# Specification: NbInertia.Page — LiveView-style Page Modules

## Executive Summary

Replace the controller-based pattern for Inertia pages with self-contained **Page modules** inspired by Phoenix LiveView. Each page becomes a single module with `mount/2`, `action/3`, and `render/0` callbacks, optionally colocating the frontend component via a `~TSX` / `~JSX` sigil.

**Key Benefits**:
- LiveView-familiar DX — same callbacks, same file structure conventions
- Single-file pages — backend logic, prop declarations, and frontend component in one `.ex` file
- Eliminates controller boilerplate — no more `use MyAppWeb, :controller` + repetitive action functions
- Compile-time TSX extraction — `~TSX` sigils are extracted to real `.tsx` files that Vite processes normally
- Full backward compatibility — existing controller-based pages continue to work

---

## Table of Contents

1. [Design Goals](#1-design-goals)
2. [API Reference](#2-api-reference)
3. [Page Lifecycle](#3-page-lifecycle)
4. [Prop System](#4-prop-system)
5. [The ~TSX / ~JSX Sigil](#5-the-tsx--jsx-sigil)
6. [Modal & Slideover Support](#6-modal--slideover-support)
7. [Real-Time Channels](#7-real-time-channels)
8. [Shared Props](#8-shared-props)
9. [Precognition](#9-precognition)
10. [History Controls](#10-history-controls)
11. [Router Integration](#11-router-integration)
12. [TSX Extraction & Vite Plugin](#12-tsx-extraction--vite-plugin)
13. [IDE Support](#13-ide-support)
14. [SSR Integration](#14-ssr-integration)
15. [nb_ts Type Generation](#15-nb_ts-type-generation)
16. [nb_serializer Integration](#16-nb_serializer-integration)
17. [nb_routes Integration](#17-nb_routes-integration)
18. [Test Helpers](#18-test-helpers)
19. [Credo Checks](#19-credo-checks)
20. [Configuration](#20-configuration)
21. [Migration Path](#21-migration-path)
22. [Implementation Phases](#22-implementation-phases)
23. [Risk Assessment](#23-risk-assessment)
24. [Open Questions](#24-open-questions)

---

## 1. Design Goals

1. **LiveView parity** — Same mental model: `mount/2`, `action/3`, `render/0` mirror LiveView's `mount/3`, `handle_event/3`, `render/1`.
2. **One module per page** — Each screen is a self-contained module. No separate controller, no separate view.
3. **Colocated frontend** — `~TSX` sigil allows embedding the React/Vue component directly in the Elixir module, extracted at compile time.
4. **Escape hatch** — Omit `render/0` to use a standalone `.tsx` file. Both patterns coexist.
5. **Zero feature regression** — Every feature in `NbInertia.Controller` must be expressible in `NbInertia.Page`.
6. **Backward compatible** — Existing controller-based pages continue to work. Page modules are additive.
7. **IDE-friendly** — Syntax highlighting and TypeScript intelligence for the `~TSX` sigil via tree-sitter injections and VS Code extension.

---

## 2. API Reference

### 2.1 Minimal Page

```elixir
defmodule MyAppWeb.UsersPage.Index do
  use NbInertia.Page

  prop :users, list(UserSerializer)

  def mount(_conn, _params) do
    %{users: Accounts.list_users()}
  end
end
```

Component resolved by convention: `MyAppWeb.UsersPage.Index` → `"Users/Index"`.

### 2.2 Full Page (all features)

```elixir
defmodule MyAppWeb.UsersPage.Edit do
  use NbInertia.Page

  # ── Module options ──────────────────────────────────
  # All optional, override via `use NbInertia.Page, key: value`
  #   component:        "Custom/Component/Path"
  #   ssr:              true | false
  #   camelize_props:   true | false
  #   encrypt_history:  true | false
  #   clear_history:    true | false
  #   preserve_fragment: true | false

  # ── Prop declarations ──────────────────────────────
  prop :user, UserSerializer
  prop :roles, list(:string)
  prop :stats, :map, defer: true
  prop :audit_log, :list, defer: "heavy"
  prop :permissions, :list, partial: true
  prop :timezone, :string, from: :user_timezone
  prop :draft, :map, nullable: true, default: %{}

  # ── Form declarations ──────────────────────────────
  form_inputs :user_form do
    field :name, :string
    field :email, :string
    field :role, :string, optional: true
  end

  # ── Shared props ────────────────────────────────────
  shared MyAppWeb.SharedProps

  shared do
    prop :locale, :string
  end

  # ── Modal config (optional) ─────────────────────────
  modal base_url: "/users",
        size: :lg,
        position: :center

  # ── Channel bindings (optional) ─────────────────────
  channel "chat:{room.id}" do
    on "message_created", prop: :messages, strategy: :append
  end

  # ── Lifecycle callbacks ─────────────────────────────

  def mount(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    %{user: user, roles: ~w(admin member guest)}
  end

  def action(conn, %{"user" => params}, :update) do
    user = Accounts.get_user!(conn.params["id"])

    case Accounts.update_user(user, params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Updated")
        |> redirect(~p"/users/#{user}")

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # ── Colocated frontend component ───────────────────

  def render do
    ~TSX"""
    import { Button, Input } from '@/components/ui'

    export default function EditUser({ user, roles }: Props) {
      const form = useForm({ name: user.name, role: user.role })

      return (
        <form onSubmit={e => { e.preventDefault(); form.submit() }}>
          <Input
            value={form.data.name}
            onChange={e => form.setData('name', e.target.value)}
          />
          <Button disabled={form.processing}>Save</Button>
        </form>
      )
    }
    """
  end
end
```

### 2.3 `use NbInertia.Page` Options

| Option | Type | Default | Description |
|---|---|---|---|
| `component` | `string` | derived from module | Override the Inertia component name |
| `ssr` | `boolean` | global config | Enable/disable SSR for this page |
| `camelize_props` | `boolean` | global config | Enable/disable prop camelization |
| `encrypt_history` | `boolean` | `false` | Encrypt history state for this page |
| `clear_history` | `boolean` | `false` | Clear history on visit |
| `preserve_fragment` | `boolean` | `false` | Preserve URL fragment on navigation |
| `layout` | `atom` | `:default` | Layout selection (future) |

### 2.4 Callbacks

| Callback | Signature | Required | Description |
|---|---|---|---|
| `mount/2` | `(conn, params) -> props \| conn` | Yes | Initialize page props on GET |
| `action/3` | `(conn, params, verb) -> redirect \| {:error, term}` | No | Handle POST/PATCH/PUT/DELETE |
| `render/0` | `() -> ~TSX\|~JSX` | No | Colocated frontend component |

---

## 3. Page Lifecycle

### 3.1 GET Request (mount)

```
GET /users/:id/edit
       │
       ▼
  Router dispatches to UsersPage.Edit
       │
       ▼
  NbInertia.Plug runs (flash, errors, versioning, headers)
       │
       ▼
  Page.mount(conn, %{"id" => "42"}) called
       │
       ├─ Returns %{user: ..., roles: ...}         → render Inertia response
       ├─ Returns conn pipeline (see 3.3)           → render with conn modifications
       └─ Returns redirect(conn, path)              → HTTP redirect
       │
       ▼
  Props merged: mount return + shared props + flash + errors
       │
       ▼
  Component resolved (convention or explicit)
       │
       ▼
  Inertia JSON response (XHR) or full HTML (initial visit)
```

### 3.2 Mutation Request (action)

```
PATCH /users/:id
       │
       ▼
  Router dispatches to UsersPage.Edit
       │
       ▼
  NbInertia.Plug runs
       │
       ▼
  Page.action(conn, params, :update) called
       │
       ├─ Returns redirect(conn, path)              → HTTP redirect (303)
       ├─ Returns {:error, changeset}                → re-render with errors
       ├─ Returns {:error, %{field: [msgs]}}         → re-render with errors
       ├─ Returns close_modal(conn)                  → close modal, redirect to base_url
       └─ Returns redirect_modal(conn, opts)         → modal-aware redirect
```

### 3.3 mount/2 Return Values

```elixir
# Props map (most common)
def mount(_conn, _params) do
  %{users: Accounts.list_users()}
end

# Conn pipeline + props
def mount(conn, _params) do
  conn
  |> encrypt_history()
  |> put_flash(:info, "Welcome back")
  |> modal_config(size: :xl)
  |> props(%{users: Accounts.list_users()})
end

# Early redirect
def mount(conn, %{"id" => id}) do
  case Accounts.get_user(id) do
    nil -> redirect(conn, ~p"/users")
    user -> %{user: user}
  end
end
```

When `mount/2` returns a plain map, it's treated as props. When it returns a `%Plug.Conn{}`, props are extracted from `conn.private[:nb_inertia_props]` (set by the `props/2` helper).

### 3.4 action/3 Verb Atom

The third argument is an atom derived from the HTTP method and route context:

| Route | HTTP | Verb Atom |
|---|---|---|
| `POST /users` | POST | `:create` |
| `PATCH /users/:id` | PATCH | `:update` |
| `PUT /users/:id` | PUT | `:update` |
| `DELETE /users/:id` | DELETE | `:delete` |

Custom verb atoms can be specified in the router:

```elixir
inertia "/users/:id/archive", UsersPage.Show, action: :archive, method: :post
```

### 3.5 action/3 Return Values

```elixir
# Redirect (success path)
def action(conn, params, :create) do
  {:ok, user} = Accounts.create_user(params)
  redirect(conn, ~p"/users/#{user}")
end

# Redirect with flash
def action(conn, params, :create) do
  {:ok, user} = Accounts.create_user(params)
  conn |> put_flash(:info, "Created") |> redirect(~p"/users/#{user}")
end

# Error — changeset (auto-converted via NbInertia.Errors protocol)
def action(conn, params, :update) do
  case Accounts.update_user(user, params) do
    {:ok, _} -> redirect(conn, ~p"/users")
    {:error, changeset} -> {:error, changeset}
  end
end

# Error — raw map
def action(_conn, _params, :update) do
  {:error, %{name: ["is required"], email: ["is invalid"]}}
end

# Modal close
def action(conn, _params, :delete) do
  Accounts.delete_user!(conn.params["id"])
  close_modal(conn)
end

# Modal close with flash
def action(conn, _params, :delete) do
  Accounts.delete_user!(conn.params["id"])
  close_modal(conn, flash: {:info, "Deleted"})
end

# Modal redirect
def action(conn, params, :create) do
  {:ok, user} = Accounts.create_user(params)
  redirect_modal_success(conn, "Created!", to: ~p"/users/#{user}")
end
```

### 3.6 Error Handling

When `action/3` returns `{:error, term}`:

1. `term` is passed through the `NbInertia.Errors` protocol
2. For `Ecto.Changeset`: traverses errors, handles nested and array associations
3. For `Map`: validates `%{field => [message]}` format, passes through
4. Errors are persisted to session
5. Page is re-rendered by calling `mount/2` again with errors merged into props
6. If `camelize_props` is enabled, error keys are camelized

---

## 4. Prop System

### 4.1 Declarative Props

Same DSL as `inertia_page`, now at module level:

```elixir
defmodule MyAppWeb.UsersPage.Index do
  use NbInertia.Page

  prop :users, list(UserSerializer)
  prop :total_count, :integer
  prop :filters, :map, default: %{}
end
```

### 4.2 Prop Types

| Type | Description |
|---|---|
| `:string` | String |
| `:integer` | Integer |
| `:number` | Float or integer |
| `:boolean` | Boolean |
| `:list` | Generic list |
| `:map` | Generic map |
| `list(:string)` | Typed list |
| `list(UserSerializer)` | List of serialized structs |
| `UserSerializer` | Serializer module |
| `[enum: ["a", "b"]]` | Enumerated values |

### 4.3 Prop Options

| Option | Type | Default | Description |
|---|---|---|---|
| `partial` | `boolean` | `false` | Only included in partial reloads |
| `lazy` | `boolean` | `false` | Lazy-loaded via Stream |
| `defer` | `boolean \| string` | `false` | Deferred loading, optionally in named group |
| `from` | `atom` | prop name | Pull from `conn.assigns` under a different key |
| `nullable` | `boolean` | `false` | Allows nil values |
| `default` | `any` | none | Default value when prop is absent |

### 4.4 Runtime Prop Wrappers

All existing prop primitives are available inside `mount/2`:

```elixir
def mount(conn, _params) do
  %{
    # Merge strategies
    notifications: inertia_merge(Notifications.recent()),
    settings: inertia_deep_merge(Settings.for_user(user)),
    feed: inertia_prepend(Feed.latest()),
    items: inertia_match_merge(Items.all(), :id),
    messages: inertia_scroll(Messages.paginate(page: 1), cursor: :id),

    # Loading strategies
    analytics: inertia_defer(fn -> Analytics.heavy() end),
    grouped: inertia_defer(fn -> Reports.generate() end, "reports"),
    sidebar: inertia_optional(fn -> Sidebar.data() end),
    pinned: inertia_always(Pins.for_user(user)),

    # Caching
    tour: inertia_once(fn -> Onboarding.steps() end)
          |> once_until(days: 7),
    config: inertia_once(fn -> AppConfig.load() end)
            |> once_as(:app_config)
            |> once_fresh(config_changed?()),
    cached_defer: inertia_defer(fn -> Heavy.load() end)
                  |> defer_once(),

    # Serializer tuples
    user: {UserSerializer, user},
    report: {ReportSerializer, report, format: :detailed},

    # Preserve case
    airports: preserve_case(Airports.codes()),

    # Lazy pagination
    users: lazy_paginate(Users.query(), %{page: 1, page_size: 20}),
    activity: lazy_cursor_paginate(Activity.query(), cursor, limit: 50)
  }
end
```

### 4.5 Form Inputs

```elixir
defmodule MyAppWeb.UsersPage.New do
  use NbInertia.Page

  prop :roles, list(:string)

  form_inputs :user_form do
    field :name, :string
    field :email, :string
    field :role, :string, optional: true
    field :avatar, :file
  end

  # ...
end
```

Form declarations are used for:
- nb_ts type generation (`UserFormInputs` interface)
- Precognition field validation
- Credo check consistency validation

---

## 5. The ~TSX / ~JSX Sigil

### 5.1 Basics

```elixir
def render do
  ~TSX"""
  import { useState } from 'react'
  import { Button } from '@/components/ui'

  export default function UsersIndex({ users }: Props) {
    const [search, setSearch] = useState('')

    const filtered = users.filter(u =>
      u.name.toLowerCase().includes(search.toLowerCase())
    )

    return (
      <div>
        <input value={search} onChange={e => setSearch(e.target.value)} />
        {filtered.map(user => (
          <div key={user.id}>{user.name}</div>
        ))}
        <Button onClick={() => window.location.reload()}>Refresh</Button>
      </div>
    )
  }
  """
end
```

### 5.2 What the Sigil Does

At compile time, `~TSX` is a no-op in Elixir — it returns the string content unchanged. The real work happens in the **extraction step** (a Mix compiler or task), which:

1. Finds all modules with `~TSX` / `~JSX` in `render/0`
2. Derives the output path from the module name
3. Generates a type preamble from `prop` declarations
4. Generates channel hook code from `channel` declarations
5. Prepends the preamble to the TSX content
6. Writes the complete `.tsx` file to `.nb_inertia/pages/`

### 5.3 Extraction Output

Given this module:

```elixir
defmodule MyAppWeb.UsersPage.Index do
  use NbInertia.Page

  prop :users, list(UserSerializer)
  prop :total, :integer

  def mount(_conn, _params) do
    %{users: Accounts.list_users(), total: Accounts.count_users()}
  end

  def render do
    ~TSX"""
    export default function UsersIndex({ users, total }: Props) {
      return <div>{total} users</div>
    }
    """
  end
end
```

Extracted file at `.nb_inertia/pages/Users/Index.tsx`:

```tsx
// AUTO-GENERATED from MyAppWeb.UsersPage.Index — do not edit directly
// Source: lib/my_app_web/inertia/users_page/index.ex

import type { User } from '@/types'

interface Props {
  users: User[]
  total: number
}

export default function UsersIndex({ users, total }: Props) {
  return <div>{total} users</div>
}
```

### 5.4 Preamble Generation Rules

The preamble is generated from the module's `prop` declarations and `channel` bindings:

| Prop Declaration | Generated Type | Generated Import |
|---|---|---|
| `prop :name, :string` | `name: string` | — |
| `prop :count, :integer` | `count: number` | — |
| `prop :count, :number` | `count: number` | — |
| `prop :active, :boolean` | `active: boolean` | — |
| `prop :tags, :list` | `tags: any[]` | — |
| `prop :meta, :map` | `meta: Record<string, any>` | — |
| `prop :users, list(:string)` | `users: string[]` | — |
| `prop :users, list(UserSerializer)` | `users: User[]` | `import type { User } from '@/types'` |
| `prop :user, UserSerializer` | `user: User` | `import type { User } from '@/types'` |
| `prop :status, [enum: ["a","b"]]` | `status: 'a' \| 'b'` | — |
| `prop :x, :map, nullable: true` | `x: Record<string, any> \| null` | — |
| `prop :x, :string, default: ""` | `x?: string` | — |

When `channel` is declared, the preamble also generates:
- `import { useChannelProps } from '@nordbeam/nb-inertia/react/realtime/useChannelProps'`
- `import { socket } from '@/lib/socket'`
- Strategy configuration constant

### 5.5 ~JSX Variant

For projects not using TypeScript:

```elixir
def render do
  ~JSX"""
  export default function UsersIndex({ users }) {
    return <div>{users.length} users</div>
  }
  """
end
```

Extracts to `.jsx` files. No type preamble generated. `Props` interface is omitted.

### 5.6 No render/0 — Standalone File

When `render/0` is not defined, the component is expected at the conventional path:

```
MyAppWeb.UsersPage.Index → assets/pages/Users/Index.tsx
```

This is the escape hatch for complex pages with many local components, heavy hooks, or anything that benefits from full IDE support in a standalone file.

### 5.7 Component Name Derivation

```
Module Name                          Component Path
─────────────────────────────────    ──────────────
MyAppWeb.UsersPage.Index          →  Users/Index
MyAppWeb.UsersPage.Show           →  Users/Show
MyAppWeb.Admin.UsersPage.Edit     →  Admin/Users/Edit
MyAppWeb.DashboardPage.Index      →  Dashboard/Index
MyAppWeb.Dashboard                →  Dashboard
```

Algorithm:
1. Split module name into segments
2. Drop segments up to and including the web module (`MyAppWeb`)
3. For segments ending in `Page`, strip the `Page` suffix
4. Join with `/`

Explicit override: `use NbInertia.Page, component: "Custom/Path"`

---

## 6. Modal & Slideover Support

### 6.1 Module-Level Declaration

```elixir
defmodule MyAppWeb.UsersPage.Show do
  use NbInertia.Page

  modal base_url: "/users",
        size: :lg,
        position: :center,
        close_button: true,
        close_explicitly: false

  prop :user, UserSerializer

  def mount(_conn, %{"id" => id}) do
    %{user: Accounts.get_user!(id)}
  end
end
```

The `modal` macro configures the page to be renderable as a modal. When visited directly (not via modal navigation), it renders as a normal page. When opened via `ModalLink` or programmatic modal navigation, the modal config is applied.

### 6.2 Slideover

```elixir
modal slideover: true,
      position: :right,
      size: :lg,
      base_url: "/users"
```

### 6.3 Dynamic Base URL

```elixir
# Function reference — receives conn.params
modal base_url: &"/users/#{&1["id"]}",
      size: :md

# Or via mount/2
def mount(conn, %{"id" => id}) do
  conn
  |> modal_config(base_url: ~p"/users/#{id}")
  |> props(%{user: Accounts.get_user!(id)})
end
```

### 6.4 Dynamic Modal Config

Override module-level modal config per-request:

```elixir
def mount(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)

  conn
  |> modal_config(
    size: if(user.role == :admin, do: :xl, else: :md),
    base_url: ~p"/users/#{id}"
  )
  |> props(%{user: user})
end
```

### 6.5 Modal Actions

```elixir
def action(conn, _params, :delete) do
  Accounts.delete_user!(conn.params["id"])
  close_modal(conn)
end

def action(conn, _params, :delete) do
  Accounts.delete_user!(conn.params["id"])
  close_modal(conn, flash: {:info, "Deleted"})
end

def action(conn, params, :create) do
  case Accounts.create_user(params) do
    {:ok, user} ->
      redirect_modal_success(conn, "Created!", to: ~p"/users/#{user}")
    {:error, changeset} ->
      {:error, changeset}
  end
end
```

### 6.6 Modal Size & Position

Sizes: `:sm` | `:md` | `:lg` | `:xl` | `:2xl` | `:3xl` | `:4xl` | `:5xl` | `:full` | custom string

Positions: `:center` | `:top` | `:bottom` | `:left` | `:right` | custom string

---

## 7. Real-Time Channels

### 7.1 Declarative Channel Bindings

```elixir
defmodule MyAppWeb.ChatPage.Show do
  use NbInertia.Page

  prop :room, RoomSerializer
  prop :messages, list(MessageSerializer)
  prop :active_users, list(UserSerializer)
  prop :typing_user, :map, nullable: true

  channel "chat:{room.id}" do
    on "message_created", prop: :messages, strategy: :append
    on "message_deleted", prop: :messages, strategy: :remove, key: :id
    on "user_joined",     prop: :active_users, strategy: :upsert, key: :id
    on "user_left",       prop: :active_users, strategy: :remove, key: :id
    on "typing",          prop: :typing_user, strategy: :replace
  end

  def mount(_conn, %{"id" => id}) do
    room = Chat.get_room!(id)
    %{
      room: room,
      messages: Chat.recent_messages(room),
      active_users: Chat.active_users(room)
    }
  end
end
```

### 7.2 Channel Strategies

| Strategy | Description |
|---|---|
| `:append` | Add to end of list |
| `:prepend` | Add to beginning of list |
| `:remove` | Remove by key match |
| `:update` | Update existing item by key match |
| `:upsert` | Update if exists, append if not |
| `:replace` | Replace entire prop value |
| `:reload` | Trigger full Inertia reload |

### 7.3 Topic Interpolation

The channel topic string supports interpolation from prop names:

```elixir
channel "chat:{room.id}" do
  # {room.id} is resolved from the :room prop's id field at runtime
end
```

### 7.4 Generated Frontend Code

When `channel` is declared with a colocated `~TSX`, the extraction preamble includes:

```tsx
// AUTO-GENERATED channel configuration
import { useChannelProps } from '@nordbeam/nb-inertia/react/realtime/useChannelProps'
import { socket } from '@/lib/socket'

const __channelConfig = [
  { event: 'message_created', prop: 'messages', strategy: 'append' },
  { event: 'message_deleted', prop: 'messages', strategy: 'remove', key: 'id' },
  { event: 'user_joined', prop: 'activeUsers', strategy: 'upsert', key: 'id' },
  { event: 'user_left', prop: 'activeUsers', strategy: 'remove', key: 'id' },
  { event: 'typing', prop: 'typingUser', strategy: 'replace' },
] as const
```

The developer can then use it in their component:

```tsx
export default function ChatRoom({ room, messages, activeUsers }: Props) {
  const { props } = useChannelProps(socket, `chat:${room.id}`, __channelConfig)
  // ...
}
```

### 7.5 Standalone File Channels

When using a standalone `.tsx` file (no `render/0`), the `channel` macro generates a companion config file:

```
.nb_inertia/channels/Chat/Show.config.ts
```

Which the developer imports manually in their standalone component.

---

## 8. Shared Props

### 8.1 Module-Level Shared Props

```elixir
defmodule MyAppWeb.UsersPage.Index do
  use NbInertia.Page

  # Module-based
  shared MyAppWeb.SharedProps
  shared MyAppWeb.AdminSharedProps

  # Inline
  shared do
    prop :locale, :string
    prop :feature_flags, :map
  end

  # ...
end
```

### 8.2 Router-Scoped Shared Props

Apply shared props to all pages in a router scope:

```elixir
# router.ex
scope "/admin", MyAppWeb.Admin do
  pipe_through [:browser, :admin_auth]

  inertia_shared MyAppWeb.AdminSharedProps

  inertia "/dashboard", DashboardPage.Index
  inertia_resource "/users", UsersPage
end
```

`inertia_shared` in the router injects shared props for all `inertia` and `inertia_resource` routes in the scope.

### 8.3 Shared Props Modules

Same behaviour as existing `NbInertia.SharedProps`:

```elixir
defmodule MyAppWeb.SharedProps do
  use NbInertia.SharedProps

  inertia_shared do
    prop :current_user, UserSerializer
    prop :notifications, list(:map)
  end

  @impl true
  def build_props(conn, _opts) do
    %{
      current_user: {UserSerializer, conn.assigns.current_user},
      notifications: Notifications.unread(conn.assigns.current_user)
    }
  end
end
```

---

## 9. Precognition

### 9.1 In action/3

```elixir
defmodule MyAppWeb.UsersPage.New do
  use NbInertia.Page

  prop :roles, list(:string)

  form_inputs :user_form do
    field :name, :string
    field :email, :string
  end

  def mount(_conn, _params) do
    %{roles: ~w(admin member guest)}
  end

  def action(conn, %{"user" => params}, :create) do
    changeset = Accounts.change_user(%User{}, params)

    precognition conn, changeset do
      # This block only executes for real submissions
      case Accounts.create_user(params) do
        {:ok, user} -> redirect(conn, ~p"/users/#{user}")
        {:error, changeset} -> {:error, changeset}
      end
    end
  end
end
```

### 9.2 Precognition with Field Filtering

```elixir
precognition conn, changeset, only: [:name, :email] do
  # ...
end
```

### 9.3 Frontend Integration

```tsx
// In ~TSX render
const form = useForm(store_user_path.post(), { name: '', email: '' })

// Triggers precognition validation on blur
<input
  value={form.data.name}
  onChange={e => form.setData('name', e.target.value)}
  onBlur={() => form.validate('name')}
/>
{form.errors.name && <span>{form.errors.name}</span>}
```

---

## 10. History Controls

### 10.1 Module-Level Defaults

```elixir
use NbInertia.Page,
  encrypt_history: true,
  clear_history: false,
  preserve_fragment: true
```

### 10.2 Per-Request Overrides

```elixir
def mount(conn, params) do
  conn
  |> encrypt_history(params["sensitive"] == "true")
  |> clear_history(params["reset"] == "true")
  |> preserve_fragment()
  |> props(%{data: load_data()})
end
```

---

## 11. Router Integration

### 11.1 Individual Routes

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  inertia "/", HomePage.Index
  inertia "/dashboard", DashboardPage.Index
  inertia "/about", AboutPage.Index
end
```

The `inertia` macro creates routes that dispatch to Page modules instead of controllers.

### 11.2 Resource Routes

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  inertia_resource "/users", UsersPage
  inertia_resource "/posts", PostsPage, only: [:index, :show]
  inertia_resource "/comments", CommentsPage, except: [:delete]
end
```

`inertia_resource "/users", UsersPage` expands to:

| HTTP | Path | Module | Callback | Verb Atom |
|---|---|---|---|---|
| GET | /users | `UsersPage.Index` | `mount/2` | — |
| GET | /users/new | `UsersPage.New` | `mount/2` | — |
| POST | /users | `UsersPage.New` | `action/3` | `:create` |
| GET | /users/:id | `UsersPage.Show` | `mount/2` | — |
| GET | /users/:id/edit | `UsersPage.Edit` | `mount/2` | — |
| PATCH | /users/:id | `UsersPage.Edit` | `action/3` | `:update` |
| PUT | /users/:id | `UsersPage.Edit` | `action/3` | `:update` |
| DELETE | /users/:id | `UsersPage.Show` | `action/3` | `:delete` |

### 11.3 Nested Resources

```elixir
inertia_resource "/users", UsersPage do
  inertia_resource "/posts", UsersPage.PostsPage, only: [:index, :new, :create]
end
```

Generates `/users/:user_id/posts`, `/users/:user_id/posts/new`, etc.

### 11.4 Custom Routes

```elixir
inertia "/users/:id/archive", UsersPage.Show, action: :archive, method: :post
inertia "/users/export", UsersPage.Index, action: :export, method: :get
```

### 11.5 Singleton Resources

```elixir
inertia_resource "/account", AccountPage, singleton: true
# GET /account → AccountPage.Show.mount/2
# GET /account/edit → AccountPage.Edit.mount/2
# PATCH /account → AccountPage.Edit.action/3 :update
```

### 11.6 Mixed Controller and Page Routes

Both systems coexist in the same router:

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  # Page modules (new)
  inertia_resource "/users", UsersPage

  # Controller-based (existing, still works)
  get "/legacy", LegacyController, :index
  resources "/old_posts", OldPostController
end
```

### 11.7 Internal Implementation

The `inertia` router macro generates standard Phoenix routes that dispatch to a thin controller adapter:

```elixir
# Generated internally by the `inertia` macro:
get "/users", NbInertia.PageController, :__dispatch__,
  private: %{
    nb_inertia_page: MyAppWeb.UsersPage.Index,
    nb_inertia_verb: nil
  }
```

`NbInertia.PageController.__dispatch__/2` reads the page module from `conn.private` and calls the appropriate callback (`mount/2` for GET, `action/3` for mutations).

---

## 12. TSX Extraction & Vite Plugin

### 12.1 Extraction Pipeline

```
┌──────────────────────┐
│  .ex file with ~TSX  │
│  (source of truth)   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Mix Compiler / Task │
│  nb_inertia.extract  │
│                      │
│  1. Find ~TSX sigils │
│  2. Parse prop decls │
│  3. Parse channel    │
│  4. Generate preamble│
│  5. Write .tsx file  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  .nb_inertia/pages/  │
│  Users/Index.tsx     │  ← gitignored build artifact
│  Users/Show.tsx      │
│  Users/Edit.tsx      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Vite                │
│  (standard pipeline) │
│  HMR / build / SSR   │
└──────────────────────┘
```

### 12.2 Mix Task

```bash
# Extract all pages
mix nb_inertia.extract

# Extract a single file
mix nb_inertia.extract --file lib/my_app_web/inertia/users_page/index.ex

# Watch mode (for development)
mix nb_inertia.extract --watch

# Verbose output
mix nb_inertia.extract --verbose
```

Output:
```
Extracted 12 pages to .nb_inertia/pages/
  ✓ Users/Index.tsx    (from MyAppWeb.UsersPage.Index)
  ✓ Users/Show.tsx     (from MyAppWeb.UsersPage.Show)
  ✓ Users/Edit.tsx     (from MyAppWeb.UsersPage.Edit)
  ✓ Users/New.tsx      (from MyAppWeb.UsersPage.New)
  ─ Dashboard/Index    (standalone — no ~TSX)
  ...
```

### 12.3 Mix Compiler Integration

Register `nb_inertia_extract` as a compiler so extraction runs automatically on `mix compile`:

```elixir
# mix.exs
def project do
  [
    compilers: Mix.compilers() ++ [:nb_inertia_extract],
    # ...
  ]
end
```

The compiler tracks file dependencies — only re-extracts pages whose `.ex` source changed.

### 12.4 Vite Plugin

```typescript
// @nordbeam/nb-vite/src/vite-plugin-nb-inertia.ts
import type { Plugin, ViteDevServer } from 'vite'

interface NbInertiaOptions {
  enabled?: boolean
  pagesDir?: string          // default: '../.nb_inertia/pages'
  standaloneDir?: string     // default: 'pages'
  watchPaths?: string[]      // default: ['../lib/**/*_page/**/*.ex']
  extractCmd?: string        // default: 'mix nb_inertia.extract'
  debounce?: number          // default: 100
}

export function nbInertia(options?: NbInertiaOptions): Plugin
```

**Responsibilities:**

1. **Resolve aliases** — `@pages/Users/Index` resolves to `.nb_inertia/pages/Users/Index.tsx` (colocated) or `assets/pages/Users/Index.tsx` (standalone), with colocated taking priority.

2. **Watch .ex files** — In dev, watch `lib/**/*_page/**/*.ex` for changes. On change, trigger extraction.

3. **HMR** — After extraction writes a new `.tsx` file, invalidate the Vite module graph entry and trigger React Fast Refresh.

### 12.5 Vite Config

```typescript
// assets/vite.config.ts
import phoenix from '@nordbeam/nb-vite'
import { nbRoutes } from '@nordbeam/nb-vite/nb-routes'
import { nbInertia } from '@nordbeam/nb-vite/nb-inertia'

export default defineConfig({
  plugins: [
    phoenix({ input: ['js/app.ts'] }),
    nbRoutes({ enabled: true }),
    nbInertia({ enabled: true }),
  ]
})
```

### 12.6 Inertia resolveComponent

```typescript
// assets/js/app.tsx
createInertiaApp({
  resolve: (name) => {
    // Colocated pages (from ~TSX sigils)
    const colocated = import.meta.glob('../../.nb_inertia/pages/**/*.tsx')
    // Standalone pages
    const standalone = import.meta.glob('./pages/**/*.tsx')

    const colocatedKey = `../../.nb_inertia/pages/${name}.tsx`
    const standaloneKey = `./pages/${name}.tsx`

    // Colocated wins if both exist
    const resolver = colocated[colocatedKey] ?? standalone[standaloneKey]
    if (!resolver) throw new Error(`Page not found: ${name}`)
    return resolver()
  }
})
```

### 12.7 Production Build

```bash
# In mix assets.deploy
mix nb_inertia.extract && cd assets && npx vite build
```

`.nb_inertia/` is gitignored. Extraction always runs before build. CI/CD must run extraction as part of the asset pipeline.

### 12.8 .gitignore

```gitignore
# Generated Inertia pages (from ~TSX sigils)
.nb_inertia/
```

---

## 13. IDE Support

### 13.1 Tree-sitter (Neovim, Helix, Zed)

Injection query for TSX highlighting inside Elixir sigils:

```scheme
;; queries/elixir/injections.scm
((sigil
  (sigil_name) @_name
  (quoted_content) @injection.content)
  (#any-of? @_name "TSX" "JSX")
  (#set! injection.language "tsx"))
```

Ships as part of an `nb-inertia.nvim` plugin or a tree-sitter query file users add to their config.

### 13.2 VS Code Extension

**Layer 1: Syntax Highlighting** — TextMate grammar embedding:

```json
{
  "embeddedLanguages": {
    "meta.embedded.block.tsx": "typescriptreact"
  },
  "patterns": [{
    "begin": "~TSX\"\"\"",
    "end": "\"\"\"",
    "contentName": "meta.embedded.block.tsx",
    "patterns": [{ "include": "source.tsx" }]
  }]
}
```

**Layer 2: TypeScript Intelligence** — Route diagnostics from the extracted `.tsx` files back to the sigil positions using line offset mapping:

1. Extension watches `.ex` files containing `~TSX` sigils
2. On edit inside sigil region, extracts content to a temp `.tsx` file
3. Delegates to tsserver for completions/diagnostics
4. Maps line numbers back to the sigil offset in the `.ex` file

### 13.3 Pragmatic Escape Hatch

For users who want full IDE support without any plugin setup: open the extracted `.tsx` file directly. A bidirectional sync watcher can propagate edits back into the `~TSX` sigil:

```
.nb_inertia/pages/Users/Index.tsx  ←→  lib/.../users_page/index.ex (~TSX)
```

This is optional and opt-in. By default, the `.ex` file is the source of truth.

---

## 14. SSR Integration

### 14.1 Per-Page SSR Control

```elixir
# Enable SSR for this page (overrides global config)
use NbInertia.Page, ssr: true

# Disable SSR for this page
use NbInertia.Page, ssr: false
```

### 14.2 SSR with Colocated Components

Colocated components work with SSR the same way standalone ones do — after extraction, the `.tsx` file is a normal module that the SSR renderer (DenoRider or dev server) can import.

### 14.3 SSR Build

The SSR build includes `.nb_inertia/pages/` in its module resolution, same as the client build.

---

## 15. nb_ts Type Generation

### 15.1 Page Prop Types

nb_ts inspects Page modules via `__inertia_pages__/0` and `__inertia_props__/0` (generated by `use NbInertia.Page`):

```typescript
// Generated in assets/js/types/pages.d.ts
export interface UsersIndexProps {
  users: User[]
  totalCount: number
}

export interface UsersEditProps {
  user: User
  roles: string[]
  stats?: Record<string, any>
  auditLog?: any[]
}
```

### 15.2 Form Types

```typescript
// Generated from form_inputs declarations
export interface UserFormInputs {
  name: string
  email: string
  role?: string
}
```

### 15.3 Modal Types

```typescript
// Generated when modal macro is used
export interface UsersShowModalConfig {
  size: 'lg'
  position: 'center'
  closeButton: true
}
```

### 15.4 Introspection Functions

`use NbInertia.Page` generates at compile time:

```elixir
def __inertia_page__(), do: :users_index
def __inertia_props__(), do: [users: {list(UserSerializer), []}, total: {:integer, []}]
def __inertia_forms__(), do: [user_form: [name: :string, email: :string]]
def __inertia_shared_modules__(), do: [MyAppWeb.SharedProps]
def __inertia_modal__(), do: %{base_url: "/users", size: :lg, position: :center}
def __inertia_channel__(), do: {"chat:{room.id}", [...]}
def __inertia_component__(), do: "Users/Index"
def __inertia_has_render__(), do: true
def __inertia_has_action__(), do: true
```

nb_ts reads these to generate all TypeScript types.

---

## 16. nb_serializer Integration

### 16.1 Automatic Serialization

Same as existing controller integration. Serializer modules in prop types trigger automatic serialization:

```elixir
prop :user, UserSerializer        # serializes single struct
prop :users, list(UserSerializer)  # serializes list of structs
```

### 16.2 Serializer Tuples in mount/2

```elixir
def mount(_conn, %{"id" => id}) do
  user = Accounts.get_user!(id)
  %{
    user: {UserSerializer, user},
    user_detailed: {UserSerializer, user, format: :detailed}
  }
end
```

### 16.3 preserve_case

```elixir
def mount(_conn, _params) do
  %{airports: preserve_case(Airports.all_codes())}
end
```

---

## 17. nb_routes Integration

### 17.1 Route Helpers in mount/2

```elixir
def mount(conn, %{"id" => id}) do
  conn
  |> modal_config(base_url: users_path.get())  # RouteResult accepted
  |> props(%{user: Accounts.get_user!(id)})
end
```

### 17.2 Route Helpers in action/3

```elixir
def action(conn, params, :create) do
  {:ok, user} = Accounts.create_user(params)
  redirect(conn, users_path.show(user.id))       # RouteResult accepted in redirect
end

def action(conn, _params, :delete) do
  Accounts.delete_user!(conn.params["id"])
  redirect_modal(conn, to: users_path.index())   # RouteResult accepted
end
```

### 17.3 Route Generation

`inertia` and `inertia_resource` routes are included in nb_routes generation. The route names follow Phoenix conventions:

```elixir
inertia_resource "/users", UsersPage
# Generates routes named: users_index, users_new, users_show, users_edit
```

---

## 18. Test Helpers

### 18.1 New Page-Aware Assertions

```elixir
import NbInertia.PageTest

# Assert page module was rendered
assert_inertia_page(conn, MyAppWeb.UsersPage.Index)

# Still works with atom/string
assert_inertia_page(conn, :users_index)
assert_inertia_page(conn, "Users/Index")
```

### 18.2 Unit Testing mount/2

Test page initialization without HTTP:

```elixir
test "mount returns users" do
  conn = build_conn() |> assign(:current_user, user)
  props = mount_page(MyAppWeb.UsersPage.Index, conn, %{})

  assert length(props.users) == 3
  assert props.total_count == 3
end
```

### 18.3 Unit Testing action/3

```elixir
test "action creates user" do
  conn = build_conn() |> assign(:current_user, admin)
  result = call_action(MyAppWeb.UsersPage.New, conn, %{"user" => valid_attrs()}, :create)

  assert {:redirect, "/users/" <> _id} = result
end

test "action returns errors for invalid data" do
  conn = build_conn() |> assign(:current_user, admin)
  result = call_action(MyAppWeb.UsersPage.New, conn, %{"user" => %{}}, :create)

  assert {:error, errors} = result
  assert errors.name
end
```

### 18.4 Integration Testing

Standard Phoenix ConnTest works — the router dispatches to the page module transparently:

```elixir
test "GET /users renders index page", %{conn: conn} do
  conn = get(conn, ~p"/users")

  assert_inertia_page(conn, MyAppWeb.UsersPage.Index)
  assert_inertia_prop(conn, :users, fn users -> length(users) > 0 end)
end

test "PATCH /users/:id updates user", %{conn: conn, user: user} do
  conn = patch(conn, ~p"/users/#{user}", user: %{name: "New Name"})

  assert redirected_to(conn) == ~p"/users/#{user}"
end
```

### 18.5 Modal Testing

```elixir
test "GET /users/:id renders as modal", %{conn: conn, user: user} do
  conn =
    conn
    |> with_modal_headers()
    |> get(~p"/users/#{user}")

  assert_inertia_modal(conn, MyAppWeb.UsersPage.Show)
  assert_inertia_modal(conn, MyAppWeb.UsersPage.Show, config: %{size: "lg"})
end
```

---

## 19. Credo Checks

### 19.1 New Checks for Page Modules

| Check | Description |
|---|---|
| `MissingMount` | Warns when a Page module has no `mount/2` callback |
| `MountReturnType` | Warns when `mount/2` doesn't clearly return a map or conn |
| `ActionWithoutMount` | Warns when `action/3` exists without `mount/2` |
| `UnusedPropInMount` | Warns when a declared prop isn't returned from `mount/2` |
| `UndeclaredPropInMount` | Warns when `mount/2` returns props not declared in the module |
| `ModalWithoutBaseUrl` | Warns when `modal` is declared without `base_url` |
| `RenderWithoutProps` | Warns when `~TSX` references `Props` but no props are declared |
| `MixedPageAndController` | Warns when both Page and Controller patterns are used in one module |

### 19.2 Updated Existing Checks

Existing Credo checks need updates to recognize Page modules:

- `DeclareInertiaPage` — now also checks that Page modules declare props
- `UntypedInertiaProps` — works on module-level `prop` declarations
- `FormInputsOptionalFieldConsistency` — works on Page module `form_inputs`

---

## 20. Configuration

### 20.1 Global Config

```elixir
# config/config.exs
config :nb_inertia,
  # Existing config (unchanged)
  endpoint: MyAppWeb.Endpoint,
  camelize_props: true,
  snake_case_params: true,
  ssr: false,
  # ...

  # New Page module config
  pages: [
    # Directory where Page modules live (for extraction source discovery)
    source_dir: "lib/my_app_web/inertia",

    # Output directory for extracted .tsx files
    output_dir: ".nb_inertia/pages",

    # Standalone pages directory (for non-colocated components)
    standalone_dir: "assets/pages",

    # Auto-extract on compile (default: true in dev/test)
    auto_extract: true,

    # Component naming strategy
    # :module (derive from module name) or :atom (from page atom like today)
    naming: :module
  ]
```

### 20.2 Dev Config

```elixir
# config/dev.exs
config :nb_inertia,
  pages: [
    auto_extract: true,
    verbose: false
  ]
```

### 20.3 Prod Config

```elixir
# config/prod.exs
config :nb_inertia,
  pages: [
    auto_extract: false  # extraction runs in build step, not at runtime
  ]
```

---

## 21. Migration Path

### 21.1 Coexistence

Page modules and controller-based pages coexist. No migration required:

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  # New page modules
  inertia_resource "/users", UsersPage

  # Existing controllers (still work)
  get "/legacy", LegacyController, :index
end
```

### 21.2 Gradual Migration

Convert one controller at a time:

**Before (controller):**

```elixir
# lib/my_app_web/controllers/user_controller.ex
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  inertia_page :users_index do
    prop :users, list(UserSerializer)
  end

  def index(conn, _params) do
    render_inertia(conn, :users_index, users: Accounts.list_users())
  end
end
```

**After (page module):**

```elixir
# lib/my_app_web/inertia/users_page/index.ex
defmodule MyAppWeb.UsersPage.Index do
  use NbInertia.Page

  prop :users, list(UserSerializer)

  def mount(_conn, _params) do
    %{users: Accounts.list_users()}
  end
end
```

**Router change:**

```elixir
# Before
get "/users", UserController, :index

# After
inertia "/users", UsersPage.Index
```

### 21.3 Mix Task: Auto-Migration

```bash
mix nb_inertia.migrate_to_pages --controller MyAppWeb.UserController
```

Generates Page module files from existing controller + `inertia_page` declarations.

---

## 22. Implementation Phases

### Phase 1: Core Page Module (Foundation)

**Goal:** `use NbInertia.Page` with `mount/2`, prop declarations, and convention-based component naming.

**Files to create:**
- `lib/nb_inertia/page.ex` — `__using__` macro, prop DSL, `__before_compile__`
- `lib/nb_inertia/page_controller.ex` — thin controller adapter that dispatches to Page modules
- `lib/nb_inertia/page/naming.ex` — component name derivation from module name

**Files to modify:**
- `lib/nb_inertia/controller.ex` — extract shared DSL macros (prop, form_inputs) into a common module usable by both Controller and Page

**Deliverables:**
- [ ] `use NbInertia.Page` macro
- [ ] `mount/2` callback dispatching
- [ ] `action/3` callback dispatching with verb atoms
- [ ] Module-level `prop` declarations
- [ ] Module-level `form_inputs` declarations
- [ ] Convention-based component naming
- [ ] `component:` override option
- [ ] Return value handling (map, conn, redirect, {:error, term})
- [ ] Unit tests

### Phase 2: Router Integration

**Goal:** `inertia` and `inertia_resource` router macros.

**Files to create:**
- `lib/nb_inertia/router.ex` — router macros

**Files to modify:**
- None (new module, imported by user in their router)

**Deliverables:**
- [ ] `inertia/2` and `inertia/3` router macro
- [ ] `inertia_resource/2` and `inertia_resource/3` router macro
- [ ] `inertia_shared/1` router macro (scope-level shared props)
- [ ] Nested resource support
- [ ] `only:` / `except:` options
- [ ] `singleton:` option
- [ ] Custom action/method options
- [ ] nb_routes integration (route names generated for Inertia routes)
- [ ] Integration tests with Phoenix router

### Phase 3: Modal, History, Shared Props, Precognition

**Goal:** Port all remaining controller features to Page modules.

**Files to modify:**
- `lib/nb_inertia/page.ex` — add `modal`, `shared`, history macros
- `lib/nb_inertia/page_controller.ex` — modal rendering, precognition dispatch

**Deliverables:**
- [ ] `modal` macro with all options
- [ ] `modal_config/2` per-request override
- [ ] `close_modal/1,2` and `redirect_modal/2` helpers
- [ ] `shared` macro (inline and module-based)
- [ ] History control options and helpers
- [ ] `precognition` macro in action/3
- [ ] All controller helpers available: `assign_prop`, `assign_errors`, `inertia_flash`, etc.
- [ ] Tests for each feature

### Phase 4: ~TSX / ~JSX Sigil & Extraction

**Goal:** Colocated frontend components via sigil, extracted to real files.

**Files to create:**
- `lib/nb_inertia/sigil.ex` — `sigil_TSX/2` and `sigil_JSX/2` definitions
- `lib/nb_inertia/extractor.ex` — TSX extraction logic (parse module, generate preamble, write file)
- `lib/nb_inertia/extractor/preamble.ex` — type preamble generation from prop declarations
- `lib/mix/tasks/nb_inertia.extract.ex` — mix task
- `lib/mix/compilers/nb_inertia_extract.ex` — Mix compiler for auto-extraction

**Deliverables:**
- [ ] `~TSX` and `~JSX` sigil macros
- [ ] `def render` convention
- [ ] Extraction logic (module → .tsx file)
- [ ] Preamble generation (props → TypeScript interface)
- [ ] Channel config generation
- [ ] `mix nb_inertia.extract` task
- [ ] `mix nb_inertia.extract --watch` mode
- [ ] `mix nb_inertia.extract --file` single file mode
- [ ] Mix compiler integration
- [ ] `.nb_inertia/` output directory
- [ ] Tests for extraction

### Phase 5: Vite Plugin

**Goal:** Vite integration for resolution, watching, and HMR.

**Files to create:**
- `nb_vite/priv/nb_vite/src/vite-plugin-nb-inertia.ts`

**Files to modify:**
- `nb_vite/priv/nb_vite/package.json` — add export
- `nb_vite/priv/nb_vite/src/index.ts` — re-export

**Deliverables:**
- [ ] Vite plugin: `nbInertia()`
- [ ] Component resolution (colocated priority over standalone)
- [ ] .ex file watching in dev
- [ ] Extraction trigger on change
- [ ] HMR after extraction
- [ ] `resolveComponent` helper for `createInertiaApp`
- [ ] Tests

### Phase 6: Channel Macro

**Goal:** Declarative real-time channel bindings.

**Files to create:**
- `lib/nb_inertia/page/channel.ex` — channel macro and config generation

**Files to modify:**
- `lib/nb_inertia/page.ex` — import channel macro
- `lib/nb_inertia/extractor/preamble.ex` — generate channel hook code

**Deliverables:**
- [ ] `channel` macro with `on` event bindings
- [ ] Topic interpolation from props
- [ ] Strategy configuration
- [ ] Frontend config generation in preamble
- [ ] Companion config file for standalone pages
- [ ] Tests

### Phase 7: IDE Support

**Goal:** Syntax highlighting and TypeScript intelligence.

**Files to create:**
- `editor/nvim/queries/elixir/injections.scm` — tree-sitter injection
- `editor/vscode/syntaxes/nb-inertia.tmLanguage.json` — TextMate grammar
- `editor/vscode/extension.ts` — VS Code extension (diagnostics mapping)
- `editor/helix/languages.toml` — Helix config

**Deliverables:**
- [ ] Tree-sitter injection queries (Neovim, Helix, Zed)
- [ ] VS Code TextMate grammar for syntax highlighting
- [ ] VS Code extension for TypeScript diagnostics (line mapping)
- [ ] Documentation for editor setup

### Phase 8: nb_ts & Credo Integration

**Goal:** Type generation from Page modules and new Credo checks.

**Files to modify:**
- `nb_ts/lib/nb_ts/generator.ex` — read `__inertia_page__/0` etc. from Page modules
- `nb_inertia/lib/nb_inertia/credo/` — new check modules

**Deliverables:**
- [ ] nb_ts generates types from Page module introspection functions
- [ ] Page prop types in `pages.d.ts`
- [ ] Form input types
- [ ] Modal config types
- [ ] New Credo checks (see section 19)
- [ ] Updated existing Credo checks
- [ ] Tests

### Phase 9: Installer & Documentation

**Goal:** `mix nb_inertia.install` supports Page module setup.

**Files to modify:**
- `lib/mix/tasks/nb_inertia.install.ex` — add `--pages` flag
- `nb_stack/lib/mix/tasks/nb_stack.install.ex` — integrate page mode

**Files to create:**
- `lib/mix/tasks/nb_inertia.migrate_to_pages.ex` — auto-migration task

**Deliverables:**
- [ ] Installer generates Page module boilerplate
- [ ] Installer configures Vite plugin
- [ ] Installer adds tree-sitter queries for detected editor
- [ ] Installer adds `.nb_inertia/` to `.gitignore`
- [ ] Migration task from controller to Page modules
- [ ] README documentation
- [ ] CLAUDE.md updates
- [ ] Examples

### Phase Dependencies

```
Phase 1 (Core) ──▶ Phase 2 (Router) ──▶ Phase 3 (Features)
                                              │
                                              ▼
Phase 4 (Sigil/Extraction) ──▶ Phase 5 (Vite) ──▶ Phase 7 (IDE)
         │
         ▼
    Phase 6 (Channels)
         │
         ▼
    Phase 8 (nb_ts/Credo) ──▶ Phase 9 (Installer/Docs)
```

Phases 1-3 are usable without the sigil (standalone `.tsx` files only).
Phases 4-7 enable the colocated `~TSX` experience.
Phases 8-9 are polish and ecosystem integration.

---

## 23. Risk Assessment

### 23.1 High Risk

| Risk | Impact | Mitigation |
|---|---|---|
| IDE support is poor | Developers won't use ~TSX | Ensure standalone file escape hatch works perfectly. Phase 7 is optional — Pages work without it. |
| Extraction latency in dev | Slow feedback loop | Use incremental extraction (only changed files). Mix compiler tracks deps. Target <100ms per file. |
| Module naming conflicts with LiveView | Confusion when both Inertia Pages and LiveView exist in same app | Use clear naming convention. Document that `*Page` suffix is optional — just a convention matching LiveView's. |

### 23.2 Medium Risk

| Risk | Impact | Mitigation |
|---|---|---|
| Router macro conflicts with Phoenix | Breakage on Phoenix upgrades | Use `NbInertia.Router` as opt-in import, don't monkey-patch Phoenix.Router. |
| Bidirectional sync (IDE escape hatch) | Data loss if sync conflicts | Make it opt-in. Default is unidirectional (.ex → .tsx). |
| Complex preamble generation | Wrong types, broken builds | Comprehensive test suite for preamble generation. Fallback: user can write types manually in ~TSX. |

### 23.3 Low Risk

| Risk | Impact | Mitigation |
|---|---|---|
| Backward compatibility | Existing apps break | Page modules are fully additive. No changes to existing Controller API. |
| SSR with colocated components | SSR build fails | Extracted .tsx files are standard modules — SSR works unchanged. |
| nb_routes integration | Route names wrong | Follow Phoenix resource naming conventions exactly. |

---

## 24. Decisions (Resolved)

1. **Naming: `*Page` suffix.** Use `UsersPage.Index`, `UsersPage.Show`, etc. Avoids confusion with LiveView's `*Page` convention. Clearly signals Inertia pages.

2. **`mount(conn, params)` — 2 args.** Conn-first, params second. Idiomatic for Plug/Phoenix controllers. Session is accessible via `conn` — no need for a third argument.

3. **Multi-verb modules.** A single Page module handles GET (via `mount/2`) + mutations (via `action/3` with `:create`, `:update`, `:delete` atoms). Fewer files, pattern matching keeps it clean.

4. **Channel topic: compile-time validation.** The `channel` macro validates at compile time that props referenced in topic strings (e.g., `{room.id}` requires `:room` prop) are declared in the module. Catches typos early.

5. **Hot reload: long-lived Elixir process.** The Phoenix endpoint (or a dedicated GenServer) exposes an HTTP endpoint for extraction. Vite plugin calls it on `.ex` file changes. Fast (<50ms) since no process spawn overhead.

6. **Layouts: first-class.** `use NbInertia.Page, layout: :admin` maps to Inertia's persistent layout system. The extracted component gets the layout wrapper in its preamble.

7. **No per-page middleware.** All middleware goes in the router via `pipe_through`. Page modules stay focused on data + rendering. This is the simpler, more Phoenix-idiomatic approach.

---

## Appendix A: Complete Example App

```
lib/my_app_web/
├── router.ex
├── shared_props.ex
└── inertia/
    ├── users_page/
    │   ├── index.ex
    │   ├── show.ex
    │   ├── new.ex
    │   └── edit.ex
    ├── posts_page/
    │   ├── index.ex
    │   └── show.ex
    └── dashboard_page/
        └── index.ex

assets/
├── pages/                    # standalone pages (complex UIs)
│   └── Dashboard/
│       └── Index.tsx
├── js/
│   ├── app.tsx
│   └── routes/
└── vite.config.ts

.nb_inertia/                  # gitignored, generated
└── pages/
    ├── Users/
    │   ├── Index.tsx
    │   ├── Show.tsx
    │   ├── New.tsx
    │   └── Edit.tsx
    └── Posts/
        ├── Index.tsx
        └── Show.tsx
```

```elixir
# router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import NbInertia.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug NbInertia.Plug
    plug NbInertia.ParamsConverter
  end

  scope "/", MyAppWeb do
    pipe_through :browser

    inertia_shared MyAppWeb.SharedProps

    inertia "/", DashboardPage.Index

    inertia_resource "/users", UsersPage
    inertia_resource "/posts", PostsPage, only: [:index, :show]
  end
end
```

## Appendix B: Comparison Table

| Feature | Controller (existing) | Page Module (new) |
|---|---|---|
| Module setup | `use NbInertia.Controller` | `use NbInertia.Page` |
| Route definition | `get "/users", UserController, :index` | `inertia "/users", UsersPage.Index` |
| Prop declaration | `inertia_page :name do ... end` | `prop :name, :type` (module level) |
| Render | `render_inertia(conn, :name, props)` | Return props from `mount/2` |
| Mutations | Controller action function | `action/3` with verb atom |
| Component naming | Atom → string conversion | Module → string derivation |
| Frontend | Separate `.tsx` file | `~TSX` sigil or separate file |
| Modal | `render_inertia_modal/4` | `modal` macro + action helpers |
| Shared props | Inline or module in controller | Inline, module, or router scope |
| Resource routes | `resources "/users", UserController` | `inertia_resource "/users", UsersPage` |
