# Agent Instructions

<!-- CAS:project-management:start -->
<!-- CAS:project-management:version project-management-v2 -->
<!-- CAS:project-management:hash sha256:fe7d4bb13e10901ffceb5b406cdd47fe95e182ac206373b01a4983473b7aba39 -->
## CAS Project Management

CAS is the source of truth for project work in this repository. The desktop app and the `cas` CLI read the same project-local state under `.cas/`.

**Mental model.** Opening a CAS task delegates it to a daemon-managed worker — the daemon spawns its own agent and drives the implement → review → merge → close transitions. Do **not** open CAS tasks for work you intend to do yourself in this session; you'll either double-run the work or race the worker.

- Always safe: inspect with `cas epic list --json`, `cas task list --json`, and `cas task show <task-id> --json`. Prefer `--json` so IDs, statuses, and event IDs are machine-readable.
- Open a CAS task when you want to *delegate* — filing a follow-up for later, decomposing a large effort into parallel pieces, or recording a bug you don't intend to fix now. Use `cas epic create --title "..." --description "..." --acceptance "..." --json` for multi-step work, then `cas task create --epic <epic-id> --title "..." --acceptance "..." --demo "..." --json` for children. Keep children small enough to verify independently.
- Before choosing labels for new work, inspect the project-specific catalog with `cas label list --json`, explain candidates with `cas label explain <label> --json`, and preview drafts with `cas label suggest --title "..." --acceptance "..." --label <label> --json`. Do not rely on static `AGENTS.md` prose as the canonical label list.
- Do **not** flip task status (`cas task start`, `cas task update --status`, `cas task close`) unless you are the worker the daemon assigned to that task. The daemon owns the workflow once a task is open.
- Track in-session work in your harness's own task list, not in CAS.
- Treat hook-injected CAS context as authoritative. Do not edit `.cas/cas.db` directly; use CAS commands so events, leases, hooks, and workflow gates stay consistent.
- Check `cas daemon status --json` before daemon-dependent workflows. Run `cas serve` when automation, event streaming, workers, terminals, or the desktop app need a live project daemon.
- After delegating with `cas task create` (or a multi-task epic), **wait for closure before continuing dependent work** — CAS has no push channel into your session. Poll `cas task show <task-id> --json` and read `.status` (`closed` means the daemon's implement→review→merge loop is done), or `cas task list --epic <epic-id> --status open --id-only` for an epic (empty means every child is done). For live updates, run `cas events tail --follow --from-id <last-seen-id>` and watch for `task.closed` / `epic.closed`.
- Cap the wait. Workers usually finish in minutes; if a per-task cap (e.g., 30 min) is exceeded, surface the still-open children and stop blocking instead of looping forever.
<!-- CAS:project-management:end -->
