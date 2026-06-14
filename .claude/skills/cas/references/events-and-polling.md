# Events & Polling

The event log is your window into what the daemon and workers are doing, and the reliable way to detect when delegated work is done.

## How `cas events tail` works

It reads from the local event log — **no daemon required**. During the event journal rollout, legacy rows from `.cas/cas.db` are exported into the journal before reads, so old SQLite events and new journal events appear in id order. Each event prints as one JSON line.

```bash
cas events tail --limit 50                      # most recent 50
cas events tail --from-id 1280                  # everything after event 1280
cas events tail --from-id 1280 --follow         # live: poll for new events
cas events tail --limit 0 --from-id 1280        # unbounded backlog from a cursor
```

Event line shape:
```json
{ "id": 1337, "created_at": "2026-05-29T18:00:00.123Z",
  "type": "task.closed", "source": "cas.daemon.automation",
  "payload": { "task_id": "task_abc", "...": "..." } }
```

`id` is monotonic — capture the last id you've seen and pass it as `--from-id` next time so you never miss or re-read events.

## Event-type catalog

**Task:** `task.created` · `task.updated` · `task.deleted` · `task.canceled` · `task.started` · `task.worker_completed` · `task.recovered_orphaned` · `task.reset` · `task.hard_reset` · `task.rerun` · `task.closed` · `task.note_added` · `task.note_appended`

**Epic:** `epic.applied` (bulk create) · `epic.follow_up_tasks_created` · (epic close emits `task.closed` for the epic id)

**Worktree:** `worktree.created` · `worktree.snapshot_updated` · `worktree.cleaned` · `worktree.merged` · `worktree.merge_failed`

**Lease:** `task_lease.created` · `task_lease.heartbeat` · `task_lease.released` · `task_lease.stale_expired`

**Agent session:** `agent_session.created` · `agent_session.updated` · `agent_session.resume_pending` · `agent_session.interrupted` · `agent_session.event` (per-tool transcript entry)

**Terminal:** `terminal.started` · `terminal.exited` · `terminal.killed` · `terminal.command_completed`

**Verification:** `verification.recorded`

**Hooks:** `hook.sessionstart` · `hook.userpromptsubmit` · `hook.pretooluse` · `hook.permissionrequest` · `hook.posttooluse` · `hook.stop` · `hook.notification`

**Automation:** `automation.worker_spawned` · `automation.worker_deferred` · `automation.merge_blocked` · `automation.epic_reviewer_spawned`

**Runtime/system:** `runtime.fallback` · `runtime.limited` · `system.initialized` · `system.schema_migration`

## Detecting closure of delegated work

The events that mean "done":
- A specific task: `task.closed` with `payload.task_id == <your task>`. Failure shows as the task reaching `failed` (watch `task.updated`).
- An epic: `task.closed` for the **epic id** (epics close via the same event).

### Polling pattern (simple, robust)
```bash
cas task show "$TASK" --json | jq -r .task.status   # "closed" | "failed" | ...
cas task list --epic "$EPIC" --status open --id-only # empty = all children done
```

### Streaming pattern (lower latency)
```bash
LAST=$(cas events tail --limit 1 --json | jq -r .id)   # remember the cursor first
cas task create ... # delegate
cas events tail --from-id "$LAST" --follow \
  | jq -rc 'select(.type=="task.closed" or .type=="task.updated")'
```
Watch for `task.closed` (success) or a transition to `failed`. Combine with a wall-clock cap so you stop blocking if a worker is wedged.

## Always cap the wait

There is no push into your session, and a worker can stall. Pick a per-task cap (e.g. 30 min). When it's exceeded: run `cas task list --epic <epic> --status open` to list what's still pending, surface it to the user, and stop blocking. Looping forever is never the right behavior.
