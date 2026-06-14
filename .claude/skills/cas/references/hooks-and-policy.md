# Hooks & Policy

If `[hooks]` is enabled (the default), `cas init` installs provider-local hooks that wire your agent runtime to CAS. These run automatically — you don't call them — but knowing what they do explains the CAS context you receive and why some tool calls get denied.

## Installation

`cas init` (and the daemon on startup) writes:
- **Codex** → `.codex/hooks.json`
- **Claude** → `.claude/settings.json`

Both invoke `cas hook <event>` with `CAS_HOOK_PROVIDER=codex|claude`. The hook bridge is deterministic — it never calls a model.

## Hook events and what each does

| Event | CAS action |
| --- | --- |
| `SessionStart` | Injects CAS task/planner context as `additionalContext`; signals the daemon the session started |
| `UserPromptSubmit` | Injects lighter planner context (recent tasks) on each prompt |
| `PreToolUse` | Evaluates command + role + protected-path policy; in `enforce` mode returns a **deny** decision when policy blocks |
| `PermissionRequest` | Same policy check; additionally auto-approves safe read-only tools (`Read`, `Glob`, `Grep`, `LS`, safe `bash` prefixes) |
| `PostToolUse` | Records a transcript entry (`agent_session.event`), tool-usage record, and diff snapshot as task evidence |
| `Stop` | Signals the daemon the session ended |
| `Notification` | No-op |

Treat the injected CAS context as authoritative — it reflects live project state.

## Policy: roles and permissions

The hook reads `CAS_ROLE` from the environment to decide what's allowed (defaults to `supervisor` if unset).

| Role | Permissions |
| --- | --- |
| `implementer` | read, write, verify |
| `reviewer` | read, verify |
| `merger` | read, write, merge, cleanup |
| `verifier` | read, verify |
| `supervisor` | read, write, verify, merge, cleanup, inspect_policy |
| `admin` | all |

When a task is active, writes **outside the active worktree root** (`CAS_WORKTREE_ID`) are blocked.

## Protected paths (blocked for non-admin roles)

`.git/**`, `.cas/**`, `.env`, `.env.*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa`, `id_dsa`, `id_ecdsa`, `id_ed25519`, `.ssh/**`.

This is one reason not to edit `.cas/cas.db` or `.cas/config.toml` directly — policy blocks it, and even when it doesn't, direct edits desync the daemon's state.

## Dangerous commands (blocked)

`rm -rf /`, `git reset --hard`, `git clean -fd`, `git push --force`, `git branch -D`, `curl … | sh`, `chmod 777`, `mkfs`, `sudo`, and similar.

## Policy modes

`hooks.policy_mode` in `config.toml`:
- `enforce` (default) — blocks disallowed actions
- `warn` — injects a warning but allows the action
- `observe` — silent; records only

## Checking policy yourself

```bash
cas policy --help                 # inspect command/path/role/secret policy checks
```

If a tool call is unexpectedly denied, it's almost always a protected path, a dangerous-command match, a write outside the worktree, or a role lacking the permission. Adjust the action rather than trying to bypass policy.
