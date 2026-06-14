# Task Lifecycle & State Machine

Understanding who drives each transition is what keeps you out of the daemon's way. **The daemon owns the workflow once a task is `open`.** You only drive transitions if you are the worker the daemon spawned for that task.

## Statuses

```
draft → open → ready → in_progress → review_pending → merge_pending → closed
                                                                     ↘ failed
```

| Status | Meaning | Who sets it |
| --- | --- | --- |
| `draft` | Created but not schedulable | Human / API |
| `open` | Ready for the scheduler to pick up | Human, daemon recovery, worker handoff |
| `in_progress` | A worker holds the lease | Daemon (`startWorker` → `StartTask`) |
| `review_pending` | Implementation done, awaiting review | Implementer worker |
| `merge_pending` | Review approved, worktree needs merging | Reviewer worker |
| `ready` | Approved with no merge needed | Reviewer/merger worker |
| `closed` | Terminal success (also used for cancellation, with a `canceled: …` reason) | Daemon / operator |
| `failed` | Reviewer rejected and retries exhausted | Daemon (review-loop stall) |

## Transitions and who drives them

```
scheduler sees open            → spawns implementer, StartTask: open → in_progress
implementer succeeds:
  requires_review && requires_merge   → in_progress → merge_pending
  requires_review && !requires_merge  → in_progress → review_pending
  !requires_review                    → in_progress → ready (or closed if auto_close_on_success)
reviewer approves:
  requires_merge                       → review_pending → merge_pending
  !requires_merge                      → review_pending → ready (or closed)
reviewer rejects                       → review_pending → open (review_retry_count++)
reviewer loop stalls (max retries)     → review_pending → failed
merger completes (worktree merged)     → merge_pending → ready/closed
operator cancel                        → any → closed (close_reason "canceled: …")
daemon startup recovery (orphaned)     → in_progress → open  (task.recovered_orphaned)
```

Workers perform handoffs via the internal `FinishTaskRun`, whose valid next statuses are `draft`/`open`/`ready`/`review_pending`/`merge_pending`. `closed` and `in_progress` are reserved for `CloseTask`/`StartTask`.

## The daemon's loop (`cas serve`)

On startup the daemon: opens + migrates the DB, acquires `daemon.pid`/`daemon.sock`, marks resumable sessions `resume_pending` and stale ones `interrupted`, reopens orphaned `in_progress` tasks, cleans previously-merged worktrees, then starts the scheduler.

The scheduler runs every `poll_interval` (2s default) and, in priority order:
1. `review_pending` tasks → spawn a **reviewer**
2. `merge_pending` tasks → spawn a **merger** (serialized: one at a time)
3. completable epics → spawn an **epic reviewer**
4. `open` tasks → spawn an **implementer** (the default role)

Concurrency is capped by `automation.max_workers`. Auto-spawn only happens when `automation.auto_spawn = true`.

For each spawned worker the daemon: checks no active session for that role exists, checks `blocked_by` is clear, creates/resolves a git worktree (for implementer/reviewer/verifier), resolves the model route, calls `StartTask` (sets `in_progress`, assignee, lease heartbeat), creates the `AgentSession`, and launches the agent process with env vars (`CAS_ROLE`, `CAS_TASK_ID`, `CAS_AGENT_ID`, `CAS_WORKTREE_ID`, …) injected.

## Epic completion

When every child task is `closed` and its worktree `merged`, the epic becomes "completable." The scheduler spawns an **epic reviewer**; on approval the daemon closes the epic (`task.closed` for the epic id). With `auto_close_epics = true` this is fully automatic.

## What this means for you

- **Inspecting** any status is always safe.
- **Creating** a task at `open` (the default) hands it to the scheduler immediately. If you want to stage work without running it yet, create it at `--status draft` and promote later.
- **Never** call `cas task start/update --status/close`, `cas epic close`, or `cas task reset/cancel/rerun` unless your session was launched by CAS as the worker for that task. Doing so desynchronizes leases, sessions, and gates.
- A task stuck in `in_progress` with no live session is normally auto-recovered by the daemon on its next startup; an operator can force it with `cas task reset`.
