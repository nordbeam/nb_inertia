# CAS Data Model

All state lives in a single SQLite database at `.cas/cas.db`. **Never edit it directly** — mutate only through `cas` commands so events, leases, hooks, and gates stay consistent. Every state change writes an append-only event in the same transaction.

## Task (and Epic)

The central record. Epics and tasks share one table; an epic is just `type: "epic"` with no `parent_id`, and its children carry `parent_id = <epic-id>`.

**Type variants:** `epic` (parent container) · `task` · `bug` · `feature` · `chore` · `spike`.

**Key fields:**

| Field | Notes |
| --- | --- |
| `id` | `task_<16hex>` or `epic_<16hex>` |
| `type` | one of the variants above |
| `parent_id` | nil for epics; epic id for children |
| `title` / `description` / `acceptance_criteria` | prose (Markdown) |
| `demo_statement` / `demo_commands` / `demo_steps` | verification evidence the worker must produce |
| `status` | state-machine value — see `lifecycle.md` |
| `priority` | higher = picked first by the scheduler |
| `labels` | `[]string` — drive model routing and workflow policy |
| `blocked_by` | `[]string` task ids that must close before this runs |
| `assignee` | agent id holding the current lease |
| `worktree_id` | active worktree FK |
| `requires_worktree` / `requires_review` / `requires_merge` | workflow gates (default true; `requires_merge` forces `requires_worktree`) |
| `auto_close_on_success` | auto-close after the last required gate (default true) |
| `review_retry_count` / `review_loop_state` | reviewer-rejection history |
| `gate_commands` | extracted from acceptance criteria; run before review |
| `close_reason` | set on cancel/close |
| `created_at` / `updated_at` / `started_at` / `closed_at` | timestamps |

**Relationships:** an epic has many child tasks (`parent_id`); a task has one active worktree and one active lease, many agent sessions (one active per role), and a `blocked_by` dependency graph.

## Event

Append-only audit log. Nothing updates or deletes events.

| Field | Notes |
| --- | --- |
| `id` | auto-increment, monotonic — use as a cursor |
| `type` | dotted namespace, e.g. `task.closed` |
| `source` | e.g. `cas.cli.task`, `cas.daemon.automation` |
| `payload` | arbitrary JSON |
| `idempotency_key` | unique; prevents duplicate hook events |
| `created_at` | timestamp |

Full event-type catalog: see `events-and-polling.md`.

## AgentSession (Worker)

One agent process execution (resumable across daemon restarts).

| Field | Notes |
| --- | --- |
| `id` | `as_<16hex>` |
| `role` | `implementer` · `reviewer` · `merger` · `verifier` · `supervisor` · `classifier` |
| `runtime` | `codex` · `claude` · `claude-print` · `mock` |
| `task_id` / `agent_id` / `worktree_id` / `cwd` | context |
| `model` / `reasoning_effort` | from model routing |
| `status` | `queued` · `resume_pending` · `running` · `paused` · `succeeded` · `failed` · `limited` · `canceled` · `interrupted` |
| `pid` | OS process id while running |
| `prompt` / `prompt_version` / `prompt_bundle` | injected system prompt |
| `transcript_path` | JSONL transcript |
| `provider_session_id` / `provider_session_path` / `resume_count` | resume bookkeeping |
| `last_activity_at` | stall detection |
| `usage` / `error` / `exit_code` | result data |

Constraint: only one active session per `(task_id, role)`.

## TaskLease

Distributed lock that stops two workers claiming one task.

`id`, `task_id`, `agent_id`, `worktree_id`, `status` (`active`/`released`/`expired`), `heartbeat_at`, `expires_at` (TTL 15m, heartbeat every 5m), `created_at`, `released_at`. Unique active lease per task.

## Worktree

A git worktree where an implementer works, under `.cas/worktrees/task_<id>/`.

`id` (`wt_<16hex>`), `task_id`, `agent_id`, `branch`, `parent_branch`, `base_commit`, `path`, `status` (`active`/`cleaned`), `snapshot_hash`, `dirty`, `merge_status` (`pending`/`merged`/`conflict`), `merged_at`, `merge_commit`, `merge_error`. Unique active branch per worktree.

## Verification / Workflow gate

`verifications` records a reviewer's or verifier's assessment. `workflow_gates` are per-`(task_id, kind)` locks that must be satisfied before a task can close. This is why `cas task close` can fail: the gate isn't satisfied yet.

## `.cas/` directory layout

```
.cas/
├── config.toml         # project config (see below)
├── cas.db[-wal,-shm]   # SQLite state — never edit by hand
├── daemon.pid          # pid + addr + project-root
├── daemon.sock         # Unix socket
├── daemon.log          # structured daemon log
├── transcripts/        # JSONL session transcripts
├── worktrees/          # per-task git worktrees
├── runtime/claude/     # compiled prompts + ready/stop signal files
├── artifacts/diffs/    # patch snapshots written by the PostToolUse hook
├── assets/             # uploaded screenshots/images (evidence)
├── backups/update/     # pre-migration DB backups
└── bin/                # cas binary managed by the update system
```

## `config.toml` essentials

```toml
schema_version = 3
state_dir = ".cas"

[daemon]
addr = "unix:/path/.cas/daemon.sock"   # or "127.0.0.1:7920"

[automation]
auto_spawn = true        # daemon picks up open tasks automatically
auto_close_epics = true  # daemon runs the epic reviewer when children close
max_workers = 10         # concurrent session cap
max_review_retries = 10  # before a task is marked failed
spawn_status = "open"    # which status triggers auto-spawn
poll_interval = "2s"
[automation.defaults]
role = "implementer"

[model_routing]
default_runtime = "codex"
# [model_routing.roles.<role>] runtime/model/reasoning_effort
# [[model_routing.label_rules]] route by label, e.g. frontend -> claude/sonnet or deep-review -> claude/opus

[task_workflows.defaults]
requires_worktree = true
requires_review = true
requires_merge = true
auto_close_on_success = true
# [[task_workflows.label_rules]] e.g. label "research" -> no worktree/review/merge

# Optional human-readable catalog entries. These examples are project-specific,
# not a universal CAS label set.
[[labels.catalog]]
name = "frontend"
description = "User-facing UI or renderer work."
use_when = ["React views, routes, modals, forms, visual QA"]
avoid_when = ["backend-only changes"]
aliases = ["ui", "renderer"]

[[labels.catalog]]
name = "research"
description = "Investigation or planning without production file edits."
use_when = ["spikes, comparisons, feasibility research"]

[[labels.catalog]]
name = "deep-review"
description = "Opus-style high-capability review routing."
use_when = ["security-sensitive review or architecture audit"]

[hooks]
enabled = true
install_codex = true     # writes .codex/hooks.json
install_claude = true    # writes .claude/settings.json
policy_mode = "enforce"  # enforce | warn | observe
```

Labels are the main routing lever: they select model profiles (`model_routing.label_rules`) and workflow shape (`task_workflows.label_rules`). A `research` task, for example, can be configured to skip worktree/review/merge entirely. The resolved label catalog combines explicit `labels.catalog` guidance with routing effects, workflow effects, lint effects from `lint.product_wiring.labels`, and observed task/epic usage. Inspect it with `cas label list --json`, drill into one label with `cas label explain <label> --json`, and preview new work with `cas label suggest` before creating tasks or epics when labels affect behavior.

Catalog lint is advisory. Alias, unknown-label, missing-label, or research-vs-implementation warnings do not block creation and do not rewrite labels automatically; operators should update the draft when the warning points to a better canonical label.
