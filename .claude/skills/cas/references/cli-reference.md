# CAS CLI Reference

The authoritative command surface. Every command accepts the global flags below. `--json` (or `--format json`) is supported by essentially every command and is the canonical machine-readable form — prefer it.

**Safety legend:** 🟢 read-only (never mutates) · 🟡 mutating · 🔴 long-running process.

## Contents

- [Global flags](#global-flags)
- [Inspection (always safe)](#inspection-always-safe)
- [`cas init`](#cas-init)
- [`cas epic`](#cas-epic)
- [`cas label`](#cas-label)
- [`cas task`](#cas-task)
- [`cas daemon` / `cas serve`](#cas-daemon--cas-serve)
- [`cas events`](#cas-events)
- [`cas worktree`](#cas-worktree)
- [`cas lease`](#cas-lease)
- [`cas worker`](#cas-worker)
- [`cas verify` / `cas merge`](#cas-verify--cas-merge)
- [Other groups](#other-groups)

## Global flags

Defined on the root command; inherited by every subcommand.

| Flag | Type | Description |
| --- | --- | --- |
| `--config` | string | Path to config file |
| `--state-dir` | string | Path to CAS state directory (default `.cas`) |
| `--json` | bool | Emit machine-readable JSON |
| `--format` | string | `json` or `text`; `--json` is canonical |
| `--log-level` | string | `debug` \| `info` \| `warn` \| `error` |
| `--log-format` | string | `json` \| `text` |

Env overrides: `CAS_STATE_DIR`, `CAS_DAEMON_ADDR`, `CAS_LOG_LEVEL`. Precedence (low→high): defaults → `config.toml` → env → flags.

## Inspection (always safe)

The commands you can run any time without consequences:

```bash
cas epic list --json
cas epic show <epic-id> --json
cas task list --json
cas task show <task-id> --json
cas task graph --epic <epic-id>          # blocker graph (--tree / --dot)
cas task lint <task-id>                   # check workflow flags for mistakes
cas label list --json                     # resolved project label catalog
cas label explain <label> --json          # label guidance, aliases, effects
cas label suggest --title "..." --json    # advisory draft label suggestions
cas daemon status --json
cas daemon list --json
cas daemon why <task-id> --json          # why automation isn't picking it up
cas events tail --limit 50
cas lease list --json
cas worktree list --json
cas worker list --json
```

## `cas init` 🟡

Initialize local CAS state: create the state dir, write a starter `config.toml`, install runtime hooks, agent docs, and the CAS skill bundle, and run schema migrations. Idempotent — reruns just confirm existing state.

| Flag | Description |
| --- | --- |
| `-y`, `--yes` | Accept defaults without prompting |

JSON result includes `state_dir`, `db_path`, `config_path`, `hook_install`, `agent_docs`, `skill_install`, `schema_version`, `event_id`.

## `cas epic`

An **epic** is a top-level container for tasks. Epics and tasks are the same record type under the hood (`type: "epic"` vs `"task"`).

### `cas epic create` 🟡
| Flag | Default | Description |
| --- | --- | --- |
| `--title` | *required* | Epic title |
| `--description` / `--description-file` | | Markdown description (`-file` reads a file, `-` for stdin) |
| `--acceptance` / `--acceptance-file` | | Acceptance criteria |
| `--demo` | | Demo statement |
| `--status` | | `open` or `draft` |
| `--priority` | `0` | Higher = scheduled first |
| `--label` | | Label (repeatable) |

→ `{ "ok": true, "epic": <Task>, "event_id": N }`

Before choosing important epic labels, run `cas label list --json` and
`cas label suggest --type epic --title "..." --acceptance "..." --label <candidate> --json`.
Suggestions and warnings are advisory; the create command stores the labels you
pass.

### `cas epic apply <plan.yaml|plan.json>` 🟡
Create an epic and all child tasks atomically from a plan file. `--dry-run` previews planned mutations, dependency references, label suggestions/warnings, duplicate warnings, and daemon pickup warnings without writing. Plan format and field list: see `delegation-playbook.md`.
→ `{ "ok", "epic", "tasks": [...], "key_to_id": {...}, "warnings", "duplicates" }`

### `cas epic list` 🟢
`--status`, `--limit` (50), `--offset`. → `{ "epics": [...], "count", "pagination" }`

### `cas epic show <epic-id>` 🟢
`--topological` (dependency order), `--markdown` (planning summary). → `{ "epic", "tasks": [...] }`

### `cas epic update <epic-id>` 🟡
Replace/append metadata and labels: `--title`, `--status`, `--description[-file]`, `--append-description`, `--acceptance[-file]`, `--append-acceptance`, `--demo`, `--priority`, `--label`, `--add-label`, `--remove-label`, `--clear-labels`.

### `cas epic close <epic-id>` 🟡 ⚠️
Close an epic after all children are closed and merge + epic-verification gates pass. **Not** a status setter — runs gates and requires a clean merged git state. Normally the daemon does this. `--reason`.

## `cas label`

Read-only helpers for the project-specific label catalog. The resolved catalog
combines explicit `[[labels.catalog]]` entries with inferred effects from
`model_routing.label_rules`, `task_workflows.label_rules`,
`lint.product_wiring.labels`, and observed task/epic usage. Labels are not
universal across repositories: a project may define labels like `frontend` for
UI routing, `research` for no-worktree discovery work, or `deep-review` for an
Opus-class reviewer route, but always inspect the local catalog first.

### `cas label list` 🟢
Lists every resolved label, source status, source kinds, guidance, aliases,
examples, routing/workflow/lint effects, and observed usage.

→ `{ "ok": true, "labels": [ { "name", "metadata", "guidance", "aliases", "examples", "effects", "usage" } ], "count": N }`

### `cas label explain <label>` 🟢
Explains one canonical label, alias, or unknown label. Alias lookups return the
canonical label and include a `label.alias` warning; unknown labels return a
placeholder with `source_status: "unknown"` and a `label.unknown` warning.

→ `{ "ok": true, "query", "matched", "label", "warnings": [...] }`

### `cas label suggest` 🟢
Evaluates a draft before creation without mutating state. Pass the same title,
description, acceptance criteria, demo, mode, and `--label` values you plan to
use for `cas epic create`, `cas task create`, or a plan child.

```bash
cas label suggest --title "Build React settings screen" \
  --acceptance "Settings route renders and saves" --json
cas label suggest --type epic --title "Compare sync options" \
  --label research --json
cas label suggest --title "Review auth diff" \
  --label deep-review --json
```

Suggestions and warnings are advisory. CAS does not rewrite aliases or reject
unknown labels automatically; update the draft yourself before creating work if
the catalog output identifies a better canonical label.

## `cas task`

A **task** is a child of an epic. Types: `task` (default), `bug`, `feature`, `chore`, `spike`.

### `cas task create` 🟡 (delegates work!)
| Flag | Default | Description |
| --- | --- | --- |
| `--epic` | *required* | Parent epic id |
| `--title` | *required* | Task title |
| `--type` | `task` | `task`/`bug`/`feature`/`chore`/`spike` |
| `--description` / `--description-file` | | Markdown |
| `--acceptance` / `--acceptance-file` | | Acceptance criteria (also source of gate commands) |
| `--demo` | | Demo statement |
| `--demo-command` | | Structured shell command for verification (repeatable) |
| `--demo-step` | | Structured manual demo step (repeatable) |
| `--status` | | `draft`/`open`/`ready`/`review_pending`/`merge_pending` |
| `--priority` | `0` | |
| `--label` | | Label (repeatable) — drives model + workflow routing |
| `--blocked-by` | | Task IDs that must close first (repeatable) |
| `--assignee` | | Initial assignee |
| `--mode` | | Workflow preset: `implementation`/`research`/`chore`/`hotfix` |
| `--requires-worktree` | `true` | Needs a git worktree |
| `--requires-review` | `true` | Approved impl needs a reviewer |
| `--requires-merge` | `true` | Approved changes need a merger |
| `--auto-close-on-success` | `true` | Auto-close after last gate |

→ `{ "ok", "task": <Task>, "event_id", "warnings" }`

Run `cas label suggest --title "..." --acceptance "..." --label <candidate> --json`
before `task create` when label choice affects routing or workflow.

### `cas task list` 🟢
`--epic`, `--type`, `--status`, `--assignee`, `--label`, `--filter` (e.g. `label=frontend status=open blocked_by_count>0`), `--id-only`, `--limit`, `--offset`.

### `cas task show <task-id>` 🟢
`--rules` (workflow mode + rules), `--prompt` (the implementer prompt CAS would send). → `{ "task", "notes": [...] }`

### `cas task assets <task-id>` 🟢
List evidence assets (screenshots/files). `--images`, `--limit`.

### `cas task update <task-id>` 🟡 ⚠️ status
Metadata/labels/blockers/flags. Same metadata flags as create plus: `--append-description`, `--append-acceptance`, `--clear-assignee`, `--reset-review-retries`, `--add-label`/`--remove-label`/`--clear-labels`, `--add-blocked-by`/`--remove-blocked-by`/`--clear-blocked-by`, and the four workflow flags. **Do not** use `--status` unless you are the assigned worker.

### Worker-only lifecycle commands 🟡 ⚠️
Run these **only** if you are the worker the daemon assigned (your env has `CAS_ROLE`/`CAS_TASK_ID`). See `lifecycle.md`.
- `cas task start <task-id>` — `--agent` (`$CAS_AGENT_ID`), `--ttl` (15m). Sets `in_progress`, creates a lease.
- `cas task heartbeat <task-id>` — refresh the lease (`--agent`, `--ttl`).
- `cas task close <task-id>` — `--reason`. Runs verification gates; not a plain setter.

### Recovery commands 🟡 (operator/worker)
- `cas task reset <task-id>` — release leases/sessions, make a stuck task runnable. `--status`, `--reason`, `--hard` (forget state, force-clean worktrees, delete branches).
- `cas task cancel <task-id>` — abandon without verification. `--reason` *required*.
- `cas task delete <task-id>` — delete a task that never had worker history.
- `cas task note <task-id>` — add a note. `--type` (`note`/`progress`/`decision`/`blocker`/`discovery`), `--author`, `--body` *required*, `--append`, `--note-id`.

### `cas task graph` / `cas task lint` 🟢
`graph --epic <id>` (`--tree`/`--dot`) renders the blocker graph. `lint <task-id>` flags likely workflow-flag mistakes and advisory label catalog findings; `--model` asks the reviewer runtime to assess quality.

### `cas task labels [task-id]` 🟢
Evaluates label suggestions and warnings for an existing task or supplied draft
fields. This is task-focused sugar over the same catalog evaluation used by
`cas label suggest`.

## `cas daemon` / `cas serve`

- `cas daemon status` 🟢 — `--project <root>`. → `{ "daemon": <StatusInfo> }`
- `cas daemon list` 🟢 — daemons on this machine.
- `cas daemon why <task-id>` 🟢 — `{ "eligible": bool, "reasons": [...] }`.
- `cas daemon stop` 🟡 — `--timeout` (30s), `--project`, `--dry-run`, `-y`, `--force`.
- `cas daemon restart` 🟡 — same flags as stop.
- `cas serve` 🔴 — start the daemon in the foreground. `--addr` (e.g. `unix:/path/.cas/daemon.sock`). `cas tui` and `cas daemon restart` use this internally.

## `cas events`

- `cas events tail` 🟢 — stream from the local event log (no daemon needed). `--limit` (50; `0` = unlimited with `--from-id`/`--follow`), `--offset`, `--from-id <N>`, `--follow`. Each event is one JSON line: `{ "id", "created_at", "type", "source", "payload" }`. See `events-and-polling.md`.

## `cas worktree`

Git worktrees where implementers make changes (under `.cas/worktrees/`).
- `cas worktree list` 🟢 — `--task`, `--agent`, `--status`.
- `cas worktree create` 🟡 — `--task` *req*, `--agent`, `--branch`, `--path`, `--base`, `--ttl`.
- `cas worktree status` 🟡 — record snapshot hash. `--id`/`--task`.
- `cas worktree doctor` 🟢 — diagnose verifier environment. `--id`/`--task`/`--path`/`--command`/`--failure-output[-file]`.
- `cas worktree cleanup` 🟡 — `--id` *req*, `--force`, `--delete-branch`.

## `cas lease`

Distributed locks preventing two workers from claiming one task.
- `cas lease list` 🟢 — `--task`, `--agent`, `--status`.

## `cas worker`

Daemon-backed worker sessions.
- `cas worker list` 🟢 — inspect active/recent worker sessions.

## `cas verify` / `cas merge`

- `cas verify` — run or inspect verification gates.
- `cas merge` — run merge gates.

These are gate machinery normally driven by the daemon. Inspect with `--json`; avoid invoking the mutating paths unless you are the worker.

## Other groups

Specialized; consult `cas <group> --help`:

| Group | Purpose |
| --- | --- |
| `cas mission` | Mission Control views |
| `cas tui` | Open Mission Control in the terminal (auto-starts daemon) |
| `cas supervisor` | Plan and coordinate epic work |
| `cas models` | Manage model-routing profiles |
| `cas policy` | Check command/path/role/secret policies |
| `cas runtime` | Inspect/clear runtime provider limits |
| `cas skills` / `cas tools` | Inspect managed skill/tool catalog metadata |
| `cas catalog` | Inspect tool catalog permissions |
| `cas asset` | Manage asset records (evidence) |
| `cas heartbeat` | Local heartbeat supervision jobs |
| `cas message` | Queue/inspect push-based factory messages |
| `cas learn` | Generate factory learning reports |
| `cas update` | Inspect/reconcile update-managed state |
| `cas hook <event>` | (hidden) handle provider hook events; used internally |
