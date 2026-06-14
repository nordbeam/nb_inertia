# Delegation Playbook

Recipes for handing work to the daemon and waiting for it correctly. Remember: creating an `open` task **delegates** it — a worker will do it, not you.

## When to delegate vs. do it yourself

| Situation | Action |
| --- | --- |
| You'll do the work in this session | Don't create a CAS task. Use your own todo list. |
| Follow-up / bug to fix later | Create an epic + one task. |
| Large effort with independent pieces | Create an epic + several small child tasks (or a plan file). |
| Record a bug you won't fix now | Create it at `--status draft` so the daemon doesn't start it yet. |

## Recipe: single follow-up

```bash
cas label suggest --title "Strip UTF-8 BOM before parsing" \
  --acceptance "Test importing a BOM file passes." \
  --label backend --json

EPIC=$(cas epic create --title "Harden CSV import" \
  --description "Importer crashes on BOM-prefixed files." \
  --acceptance "BOM files import cleanly; regression test added." \
  --json | jq -r .epic.id)

TASK=$(cas task create --epic "$EPIC" \
  --title "Strip UTF-8 BOM before parsing" \
  --acceptance "Test importing a BOM file passes." \
  --demo "go test ./internal/importer -run BOM" \
  --label backend --json | jq -r .task.id)
```

## Recipe: multi-task epic via a plan file

For more than a couple of tasks, write a plan and apply it atomically — this creates the epic and all children in one transaction and resolves `blocked_by` between them by key.

`plan.yaml`:
```yaml
epic:
  title: "Add dark mode"
  description: "User-toggleable dark theme across the app."
  acceptance: "Toggle persists; all screens themed; no contrast regressions."
  labels: [frontend]
tasks:
  - key: tokens
    title: "Define dark color tokens"
    acceptance: "Token set added and unit-tested."
    demo: "npm test -- tokens"
  - key: toggle
    title: "Add theme toggle + persistence"
    acceptance: "Toggle flips theme and survives reload."
    demo: "npm test -- theme-toggle"
    depends_on: [tokens]      # resolved to the created task id automatically
  - key: screens
    title: "Theme all screens"
    acceptance: "Visual check passes on every route."
    depends_on: [tokens]
    labels: [frontend]
```

```bash
cas epic apply plan.yaml --dry-run --json   # preview labels, dependencies, duplicates
cas epic apply plan.yaml --json             # returns key_to_id mapping
```

Per-task plan fields: `key`, `type`, `title`, `description`, `acceptance`/`acceptance_criteria`, `demo`/`demo_statement`, `demo_commands`, `demo_steps`, `status`, `priority`, `labels`, `blocked_by`/`depends_on`, `assignee`, `mode`, `requires_worktree`, `requires_review`, `requires_merge`, `auto_close_on_success`.

## Writing tasks workers can actually finish

- **Acceptance criteria** are the contract. Make them concrete and checkable — gate commands are extracted from them.
- **Demo** (`--demo` / `--demo-command`) is the verification the worker must produce. A runnable command (`go test ...`, `npm test ...`) is far better than prose.
- **Keep children small** enough to verify independently — one coherent change each.
- **Labels** route the work: they pick the model profile and the workflow shape. Inspect the local catalog with `cas label list --json`, explain candidates with `cas label explain <label> --json`, and preview drafts with `cas label suggest --title "..." --acceptance "..." --label <candidate> --json` before creating work. Projects often define labels like `frontend` for UI work, `research` for no-worktree discovery, or a deep-review/Opus-style label for high-capability review routing, but those examples are not universal.
- **Label lint is advisory.** Unknown labels and aliases are preserved unless you change the draft. Use warnings from `cas label suggest`, `cas task labels`, `cas task lint`, or `cas epic apply --dry-run` to choose canonical labels before the daemon sees the work.
- Run `cas task lint <task-id>` after creating to catch workflow-flag mistakes; `cas task show <task-id> --rules --prompt` shows exactly how the worker will be briefed.

## Recipe: delegate → wait → proceed

CAS has **no push channel** into your session. After delegating, you must poll for closure before depending on the result.

```bash
# one task
while :; do
  st=$(cas task show "$TASK" --json | jq -r .task.status)
  echo "status: $st"
  [ "$st" = closed ] && break
  [ "$st" = failed ] && { echo "task failed"; break; }
  sleep 20
done

# whole epic — empty list means every child is done
cas task list --epic "$EPIC" --status open --id-only
```

For live updates instead of polling, follow the event stream — see `events-and-polling.md`.

**Always cap the wait.** Workers usually finish in minutes. If you exceed a sensible cap (e.g. 30 minutes), stop blocking, report which tasks are still open/failed, and let the user decide. Never loop forever.

## Prerequisite: a running daemon

Delegation only executes if the daemon is up and `auto_spawn` is on.

```bash
cas daemon status --json     # {"daemon":{"running":true,...}}
cas serve                    # start it if not running
cas daemon why <task-id> --json   # if a task isn't being picked up, this explains why
```
