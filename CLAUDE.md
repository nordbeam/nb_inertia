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
      {:error, changeset} -> render_inertia(conn, :users_new, changeset: changeset)
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

Use `inertia_shared(Module)` in the **controller** (NOT a plug) — integrates with nb_ts type generation.

```elixir
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps

  inertia_shared do
    prop(:user, UserSerializer, nullable: true)
    prop(:flash, :map)
  end

  @impl NbInertia.SharedProps.Behaviour
  def build_props(conn, _opts) do
    %{user: conn.assigns[:current_scope]&.user, flash: conn.assigns[:flash] || %{}}
  end
end

# In controller:
inertia_shared(Auth)
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

## Page Modules (NbInertia.Page)

LiveView-style single-module-per-page pattern as an alternative to controller-based pages.

### Key Files

| File | Purpose |
|------|---------|
| `lib/nb_inertia/page.ex` | Core `use NbInertia.Page` macro, prop DSL, `__before_compile__` |
| `lib/nb_inertia/page_controller.ex` | Thin dispatch controller: routes to Page module's `mount/2` or `action/3` |
| `lib/nb_inertia/page/naming.ex` | Component name derivation from module name (e.g., `MyAppWeb.UsersPage.Index` -> `"Users/Index"`) |
| `lib/nb_inertia/page/channel.ex` | Declarative `channel` macro for real-time bindings |
| `lib/nb_inertia/router.ex` | Router macros: `inertia/2,3`, `inertia_resource/2,3,4`, `inertia_shared/1` |
| `lib/nb_inertia/sigil.ex` | `~TSX` and `~JSX` sigils (no-ops in Elixir, extracted by Extractor) |
| `lib/nb_inertia/extractor.ex` | TSX extraction: discovers Page modules with `render/0`, writes `.tsx` files |
| `lib/nb_inertia/extractor/preamble.ex` | TypeScript preamble generation: `Props` interface from prop declarations |
| `lib/mix/tasks/nb_inertia.extract.ex` | `mix nb_inertia.extract` task (manual extraction) |
| `lib/mix/compilers/nb_inertia_extract.ex` | Mix compiler for auto-extraction on `mix compile` |
| `lib/nb_inertia/page_test.ex` | Test helpers: `mount_page/2,3`, `action_page/4`, page-aware assertions |
| `lib/mix/tasks/nb_inertia.migrate_to_pages.ex` | Migration task: generates Page modules from controller's `inertia_page` blocks |
| `editor/` | IDE support: tree-sitter injections (nvim, helix, zed), VS Code extension |

### Page Lifecycle

```
GET /users/:id/edit
  -> Router dispatches to NbInertia.PageController
  -> PageController calls Page.mount(conn, params)
  -> mount/2 returns %{props} | conn | redirect
  -> Props merged: mount return + shared props + flash + errors
  -> Inertia JSON response or full HTML

PATCH /users/:id
  -> Router dispatches to NbInertia.PageController
  -> PageController calls Page.action(conn, params, :update)
  -> action/3 returns redirect | {:error, changeset} | {:error, map}
```

### Prop DSL

Reused from `NbInertia.Controller` — same `prop`, `form_inputs`, `shared`, `modal` macros:

```elixir
prop :users, list(UserSerializer)
prop :status, enum: ["active", "inactive"]
prop :draft, :map, nullable: true, default: %{}
prop :stats, :map, defer: true
```

### Router Macros

```elixir
import NbInertia.Router

# Single page
inertia "/", HomePage.Index
inertia "/about", AboutPage.Index

# Resource (generates index, show, new, edit, create, update, delete routes)
inertia_resource "/users", UsersPage
inertia_resource "/posts", PostsPage, only: [:index, :show]

# Scoped shared props
scope "/admin" do
  inertia_shared AdminSharedProps
  inertia_resource "/dashboard", Admin.DashboardPage
end
```

### Test Helpers (NbInertia.PageTest)

```elixir
use NbInertia.PageTest

# Direct mount testing
props = mount_page(MyAppWeb.UsersPage.Index, conn)
assert Map.has_key?(props, :users)

# Action testing
result = action_page(MyAppWeb.UsersPage.New, conn, params, :create)
assert {:redirect, _} = result

# Page-aware assertions
assert_page_props(conn, [:users, :total_count])
```

### Credo Checks (Page-specific)

| Check | Description |
|-------|-------------|
| `MissingMount` | Page module without `mount/2` |
| `ActionWithoutMount` | Page has `action/3` but no `mount/2` |
| `UnusedPropInMount` | Declared prop not returned by `mount/2` |
| `UndeclaredPropInMount` | Prop returned by `mount/2` not declared |
| `RenderWithoutProps` | `render/0` present but no props declared |
| `MixedPageAndController` | Module uses both `NbInertia.Page` and `NbInertia.Controller` |
| `ModalWithoutBaseUrl` | Modal declared without `base_url` |

## Installation

```bash
# Standard installation
mix nb_inertia.install --client-framework react --typescript

# With Page module support
mix nb_inertia.install --client-framework react --typescript --pages
```

The `--pages` flag additionally:
- Adds `import NbInertia.Router` to the router
- Generates a sample Page module (`HomePage.Index`)
- Adds `inertia "/"` route
- Adds `.nb_inertia/` to `.gitignore`
- Adds `:nb_inertia_extract` compiler to `mix.exs`
- Configures `pages` section in `:nb_inertia` config
- Adds `nbInertia()` Vite plugin (if nb_vite detected)

Installs npm packages, configures Phoenix (`use NbInertia.Controller`, `plug NbInertia.Plug`), sets up TypeScript with `@/*` path alias.
