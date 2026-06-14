---
name: cas
description: Work with CAS (Coding Agent System) project management in this repository — epics, tasks, the daemon, the event log, and the implement→review→merge→close worker loop. Use this skill WHENEVER you are in a repo that has a `.cas/` directory or a `cas` CLI, and the user mentions epics, tasks, delegating work, filing a follow-up, decomposing a large effort, checking task/epic status, the CAS daemon, workers, or Mission Control — even if they don't say "CAS" by name. Critically, consult this BEFORE running any `cas` command that creates or changes state (`cas epic create`, `cas task create`, `cas task start/update/close`, `cas serve`), because opening a CAS task *delegates* the work to a background worker rather than doing it in your session, and flipping task status by hand corrupts the workflow.
---

# CAS — Coding Agent System

CAS is a project-management control plane that lives inside a repository under `.cas/`. The `cas` CLI, the desktop app, and the terminal UI (`cas tui`) all read the same project-local SQLite state. A long-running **daemon** (`cas serve`) watches that state and autonomously spawns agent **workers** to take tasks through an implement → review → merge → close loop.

This skill teaches you how to interact with CAS *correctly*. The single most important idea is below — internalize it before running any state-changing command.

## The one mental model that matters

**Opening a CAS task delegates it to a background worker. It does not do the work in your session.**

When a task is `open` and automation is on, the daemon's scheduler picks it up, spins up its own agent in an isolated git worktree, and drives every transition itself. If you `cas task create` for work you then also do by hand, you either **double-run the work** or **race the worker** — both produce conflicts and wasted effort. Likewise, if you manually flip a task's status, you fight the state machine the daemon owns.

So before touching CAS, decide which of three relationships you have with a piece of work:

| Your situation | What to do | Commands |
| --- | --- | --- |
| **Just looking** — you want to understand state | Inspect freely. Always safe, never mutates. | `cas epic/task list/show --json`, `cas events tail`, `cas daemon status` |
| **Delegating** — file work for a worker to do later or in parallel | Create the epic/task, then **poll for closure** before depending on it | `cas epic create`, `cas task create`, `cas epic apply` |
| **You ARE the worker** the daemon assigned to this task | Only then drive status: start, heartbeat, note, close | `cas task start/heartbeat/note/close` |

If you're doing the work **yourself in this session**, don't create a CAS task for it at all. Track it in your own harness todo list. CAS is for delegated and recorded work, not your live scratchpad.

## Always-safe: inspecting state

These never mutate. Reach for them constantly to orient yourself. Always pass `--json` so IDs, statuses, and `event_id`s are machine-readable.

```bash
cas epic list --json                     # all epics
cas epic show <epic-id> --json           # epic + its child tasks
cas task list --epic <epic-id> --json    # tasks under an epic
cas task list --status open --json       # filter by status/label/assignee/type
cas task show <task-id> --json           # one task + its notes
cas label list --json                    # resolved project label catalog
cas label explain <label> --json         # guidance, aliases, effects, warnings
cas daemon status --json                 # is the daemon running for this project?
cas daemon why <task-id> --json          # why isn't automation picking this task up?
cas events tail --limit 50               # recent state-change events
```

`cas task show <task-id> --rules` and `--prompt` reveal the workflow mode and the exact prompt the daemon would hand a worker — useful for understanding how a task will be executed.

Labels are project-specific. Before choosing labels for new delegated work,
inspect the resolved catalog with `cas label list --json`; use
`cas label explain <label> --json` for a candidate label's aliases, guidance,
and routing/workflow/lint effects; and run `cas label suggest --title "..."
--acceptance "..." --label <candidate> --json` to preview advisory suggestions
or warnings without creating anything. Do not rely on static label prose in
`AGENTS.md` as the source of truth.

## Delegating: creating work for the daemon

Create work only when you want it *done by a worker*, not by you.

**Single follow-up / bug:** create an epic to hold it, then a child task.
```bash
cas label suggest --title "Stabilize upload retry" \
  --acceptance "Test passes 50x in a row" --label backend --json
cas epic create --title "Fix flaky upload test" \
  --description "..." --acceptance "..." --json
cas task create --epic <epic-id> --title "Stabilize upload retry" \
  --acceptance "Test passes 50x in a row" --demo "go test -run Upload -count=50" --json
```

**Multi-step effort:** decompose into an epic with several small child tasks. Keep each child small enough to verify independently. For anything beyond a couple of tasks, author a plan file and apply it atomically — see `references/delegation-playbook.md`.

Label suggestions are advisory. CAS keeps the labels you pass to `epic create`,
`task create`, and `epic apply` unless you change them yourself, so replace
aliases with canonical labels or add suggested labels before creation when the
catalog output says they matter.

After creating, **you must wait for closure before doing dependent work** — CAS has no push channel into your session. Poll, don't assume:
```bash
cas task show <task-id> --json | jq -r .task.status          # "closed" = done
cas task list --epic <epic-id> --status open --id-only        # empty = all children done
cas events tail --follow --from-id <last-seen-id>             # live: watch for task.closed / epic.closed
```
**Cap the wait.** Workers usually finish in minutes. If you exceed a sensible cap (e.g. 30 min), surface the still-open tasks and stop blocking — don't loop forever. See `references/events-and-polling.md` for closure-detection recipes.

## Never flip status unless you're the assigned worker

`cas task start`, `cas task update --status`, `cas task close`, `cas epic close`, `cas task reset/cancel/rerun` all mutate the workflow the daemon owns. Run them **only** if you are the worker the daemon spawned for that exact task (you'll know — your session was launched by CAS with `CAS_ROLE` and `CAS_TASK_ID` set). For everyone else, these commands cause the daemon to lose track of leases, sessions, and gates.

Two more traps:
- `cas task close` / `cas epic close` are **not** status setters. They run verification + merge gates and fail unless those gates pass in a clean merged git state. They're the daemon's job, not a shortcut.
- Never edit `.cas/cas.db` directly. Every state change must go through a `cas` command so events, leases, hooks, and workflow gates stay consistent.

## Runtime hooks are already watching

If `[hooks]` is enabled (default), CAS installs provider hooks into `.claude/settings.json` and `.codex/hooks.json`. They inject CAS task/planner context at session start, enforce role/path/command policy on tool use (in `enforce` mode they can *deny* a tool call), and record your tool activity as task evidence. Treat hook-injected CAS context as authoritative. Details in `references/hooks-and-policy.md`.

## Before any daemon-dependent workflow

Streaming events, spawning workers, terminals, and the desktop app all need a live daemon. Check first:
```bash
cas daemon status --json        # {"daemon": {"running": true, ...}}
cas serve                       # start it (foreground) if it isn't running
```

## Reference files

Read these as needed — don't load them all up front.

- `references/cli-reference.md` — every command group, its flags, and `--json` output shapes. The authoritative command surface.
- `references/data-model.md` — the entities (task, epic, event, lease, worktree, agent session) and their fields and relationships.
- `references/lifecycle.md` — the task status state machine, every transition, and who drives each one.
- `references/delegation-playbook.md` — recipes for `epic create` / `task create` / `epic apply`, the plan-file format, and create→poll→proceed loops.
- `references/events-and-polling.md` — event types, `events tail --follow`, and reliable closure detection.
- `references/hooks-and-policy.md` — hook events, role permissions, protected paths, and blocked commands.
