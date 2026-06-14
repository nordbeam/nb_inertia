# CLAUDE.md - nb_inertia

Inertia.js integration for Phoenix with declarative page DSL, type-safe props, and enhanced client-side components integrating with nb_routes.

## Key Concepts

- Official `@inertiajs/react` and `@inertiajs/vue3` **already support RouteResult natively** via `UrlMethodPair` — no wrappers needed for `router` and `Link`
- nb_inertia adds: `useForm` (route binding), `Head`/`usePage` (modal context), modal system, flash data, precognition, shared props, SSR via DenoRider
- Optional deps: nb_serializer, nb_routes, nb_ts

## Import Guidelines

```typescript
// Official Inertia — use directly (supports RouteResult natively)
import { router, Link, usePage } from '@inertiajs/react';

// nb_inertia — enhanced components
import { useForm } from '@nordbeam/nb-inertia/react/useForm';
import { Head } from '@nordbeam/nb-inertia/react/Head';
import { usePage } from '@nordbeam/nb-inertia/react/usePage';
import { useFlash, useOnFlash } from '@nordbeam/nb-inertia/react';
import { Modal, ModalLink, ModalProvider } from '@nordbeam/nb-inertia/react/modals';

// Vue equivalents: '@nordbeam/nb-inertia/vue/useForm', etc.
```

## Core Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `NbInertia.Controller` | `lib/nb_inertia/controller.ex` | `inertia_page` macro, prop validation, serialization |
| `useForm` (React) | `priv/nb_inertia/react/useForm.tsx` | Route-bound form with precognition support |
| `useForm` (Vue) | `priv/nb_inertia/vue/useForm.ts` | Same for Vue 3 |
| Modal system | `priv/nb_inertia/{react,vue}/modals/` | HeadlessModal, Modal, ModalLink, modalStack |
| Shared types | `priv/nb_inertia/shared/types.ts` | RouteResult, ModalConfig types |
| Installer | `lib/mix/tasks/nb_inertia.install.ex` | Igniter-based setup |

## useForm — Route Binding

```typescript
// Bound — submit() needs no method/URL
const form = useForm({ name: '', email: '' }, update_user_path.patch(user.id));
form.submit({ preserveScroll: true, onSuccess: () => {} });

// Unbound — standard Inertia behavior
const form = useForm({ name: '', email: '' });
form.submit('post', '/users');
```

Types: `BoundFormType<TForm>` (submit with options only) and `UnboundFormType<TForm>` (standard).

## useForm — Precognition

Precognition shorthand: pass route as first arg, data as second:

```typescript
const form = useForm(store_user_path.post(), { name: '', email: '' });
// form.validate('name') — validate on blur
// form.submit() — full submission
```

Separate validation/submission endpoints:

```typescript
const form = useFormWithPrecognition(data, validate_path.post(), submit_path.post());
```

Precognition methods: `validate()`, `touch()`, `touched()`, `valid()`, `invalid()`, `validating`, `setValidationTimeout()`, `validateFiles()`, `withAllErrors()`.

### Precognition Backend

Add `plug NbInertia.Plugs.Precognition` to router pipeline. In controllers:

```elixir
use NbInertia.Plugs.Precognition

def create(conn, %{"user" => params}) do
  changeset = User.changeset(%User{}, params)
  precognition conn, changeset do
    # Only runs for real submissions
    case Accounts.create_user(params) do
      {:ok, user} -> redirect(conn, to: ~p"/users/#{user.id}")
      {:error, changeset} -> render_inertia_page(conn, :users_new, changeset: changeset)
    end
  end
end
```

Options: `:only` (field list), `:camelize` (key camelization). Use `precognition_fields(conn)` for Validate-Only header support. Also accepts raw error maps instead of changesets.

Protocol: `Precognition: true` + `Precognition-Validate-Only: field1,field2` request headers. Responds 204 (valid) or 422 with `{"errors": {...}}`.

## Flash Data

One-time data that doesn't persist in browser history.

```elixir
conn
|> inertia_flash(:message, "Success!")
|> inertia_flash(new_user_id: user.id)
|> redirect(to: ~p"/users/#{user.id}")
```

```tsx
const { flash, has, get } = useFlash<{ message?: string }>();
useOnFlash<{ newUserId?: number }>(({ newUserId }) => { /* ... */ });
```

Flow: `inertia_flash` -> `conn.private[:nb_inertia_flash]` -> session on redirect -> loaded & cleared on next request -> sent as top-level `flash` field (not inside props).

Config: `include_phoenix_flash: true`, `camelize_flash: nil`.

## Shared Props

Use `include_shared_props(Module)` in the **controller** (NOT a plug) — integrates with nb_ts type generation.

```elixir
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps

  inertia_shared do
    prop(:user, ref(UserSerializer), nullable: true)
    prop(:flash, :map)
  end

  @impl NbInertia.SharedProps.Behaviour
  def build_props(conn, _opts) do
    %{user: conn.assigns[:current_scope]&.user, flash: conn.assigns[:flash] || %{}}
  end
end

# In controller:
include_shared_props(Auth)
```

nb_ts auto-generates `DashboardProps extends AuthProps` — never manually merge types.

## Modal System

### Backend

```elixir
render_inertia_modal(conn, :users_show,
  [user: user],
  base_url: "/users", size: :lg, position: :center
)
```

Key modules:
- `NbInertia.Modal` — struct with `new/2`, `base_url/2`, `size/2`, `position/2`, `slideover/2`, `close_button/2`, `close_explicitly/2`
- `NbInertia.Modal.BaseRenderer` (`lib/nb_inertia/modal/base_renderer.ex`) — renders modal to Inertia response with headers
- `NbInertia.Modal.Redirector` — `redirect_modal(conn, to: url)`
- `NbInertia.Plugs.ModalHeaders` (`lib/nb_inertia/plugs/modal_headers.ex`) — detects `X-Inertia-Modal-Request` header

Modal config type: `size` (:sm/:md/:lg/:xl/:full), `position` (:center/:top/:bottom/:left/:right), `slideover` (bool), `closeButton`, `closeExplicitly`, `maxWidth`, `paddingClasses`, `panelClasses`, `backdropClasses`.

Config hierarchy: global defaults -> per-modal -> frontend overrides.

### Frontend

**ModalLink** — intercepts clicks, fetches via Inertia. When backend uses `render_inertia_modal`, response includes `_nb_modal` prop — ModalLink detects this and defers to InitialModalHandler (prevents duplicate modals).

**InitialModalHandler** — required setup component inside Inertia App context. Handles initial page loads with `_nb_modal` and navigation events. **Must clear `currentModalRef` in `onClose`** to allow reopening the same modal (since `history.replaceState` doesn't fire Inertia navigate events).

**modalStack** — manages modal stack array, z-index calculation (`baseZIndex=50 + index`), browser history integration (`pushState` on open, `popstate` listener for back button).

### HTTP Headers

Request: `X-Inertia-Modal-Request: true`
Response: `X-Inertia-Modal: true`, `X-Inertia-Modal-Base-Url`, `X-Inertia-Modal-Config` (JSON), `X-Inertia-Modal-Redirect`

## Real-Time WebSocket Support

Setup: `mix nb_inertia.gen.realtime`

Uses standard Phoenix Channels. Frontend hooks:

```typescript
import { socket, useChannel, useRealtimeProps } from '@/lib/socket';

const { props, setProp } = useRealtimeProps<ChatRoomProps>();
useChannel(socket, `chat:${room.id}`, {
  message_created: ({ message }) => setProp('messages', msgs => [...msgs, message]),
});
```

Declarative strategies via `useChannelProps`: `append`, `prepend`, `remove`, `update`, `upsert`, `replace`, `reload`.

Backend helper: `NbInertia.Realtime` — `broadcast/4` with tuple serialization matching `render_inertia`.

```elixir
use NbInertia.Realtime, endpoint: MyAppWeb.Endpoint
broadcast("chat:#{room.id}", "message_created", message: {MessageSerializer, message})
```

Hooks: `useChannel<TEvents>`, `useRealtimeProps<T>` (with `setProp`/`setProps`/`reload`/`resetOptimistic`), `usePresence<T>`.

## nb_routes Integration

`RouteResult = { url: string, method: 'get' | 'post' | 'put' | 'patch' | 'delete' | 'head' }`.

Components use `isRouteResult()` type guard. All components are backward-compatible with plain strings.

## Installation

```bash
# Standard installation
mix nb_inertia.install --client-framework react --typescript
```

Installs npm packages, configures Phoenix (`use NbInertia.Controller`, `plug NbInertia.Plug`), sets up TypeScript with `@/*` path alias.

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
