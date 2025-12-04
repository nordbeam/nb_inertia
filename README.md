# NbInertia

Advanced Inertia.js integration for Phoenix with declarative page DSL, type-safe props, shared props, SSR support, and optional NbSerializer integration.

## Features

- **Declarative Page DSL**: Define pages and their props with compile-time validation
- **Component Name Inference**: Automatic conversion from `:users_index` to `"Users/Index"`
- **Shared Props**: Define props shared across all pages (inline or as dedicated modules)
- **Type Safety**: Compile-time prop validation in dev/test environments
- **Server-Side Rendering**: Built-in SSR support with DenoRider (Deno-based)
- **NbSerializer Integration**: Optional automatic serialization for high-performance JSON
- **Flexible Rendering**: Support for both all-in-one and pipe-friendly patterns
- **Test Helpers**: Comprehensive test utilities for Inertia pages
- **Optional Dependency**: Works standalone or with NbSerializer for advanced features
- **Real-Time Updates**: WebSocket integration via Phoenix Channels with declarative strategies
- **Modal System**: Render pages as modals/slideovers without full page navigation
- **Credo Checks**: 8 custom Credo checks for compile-time code quality validation

## Installation

### Quick Start (Recommended)

Run the installer directly from GitHub:

```bash
mix igniter.install nb_inertia@github:nordbeam/nb_inertia
```

For TypeScript support, add the `--typescript` flag:

```bash
mix igniter.install nb_inertia@github:nordbeam/nb_inertia --typescript
```

This installs and configures:
- NbInertia controller helpers
- Inertia configuration
- Optional TypeScript type generation (with `--typescript`)
- Mix aliases
- Example files

### Manual Installation

Add `nb_inertia` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:nb_inertia, "~> 0.1"},
    {:nb_serializer, "~> 0.1", optional: true},  # Optional
    {:nb_ts, "~> 0.1", optional: true}           # Optional for TypeScript
  ]
end
```

Run:

```bash
mix deps.get
```

## Quick Start Guide

### 1. Define an Inertia Page

In your controller, use `NbInertia.Controller`:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  # Define the page and its props
  inertia_page :users_index do
    prop :users, :list
    prop :total_count, :integer
    prop :filters, :map, optional: true
  end

  def index(conn, params) do
    users = MyApp.Accounts.list_users(params)

    render_inertia(conn, :users_index,
      users: users,
      total_count: length(users),
      filters: params["filters"]
    )
  end
end
```

### 2. Component Name Inference

NbInertia automatically converts page atoms to React component paths:

- `:users_index` → `"Users/Index"`
- `:users_show` → `"Users/Show"`
- `:users_new` → `"Users/New"`
- `:admin_users_index` → `"Admin/Users/Index"`
- `:admin_dashboard` → `"Admin/Dashboard"`
- `:dashboard` → `"Dashboard"`
- `:settings` → `"Settings"`

Override manually if needed:

```elixir
inertia_page :custom_name, component: "CustomPath/Component" do
  prop :data, :map
end
```

### 3. Unified Prop Syntax

NbInertia supports a unified, consistent syntax for defining props (matching the NbSerializer field syntax):

```elixir
inertia_page :products_index do
  # Primitives
  prop :id, :integer
  prop :name, :string
  prop :active, :boolean

  # Lists of primitives
  prop :tags, list: :string           # TypeScript: tags: string[]
  prop :scores, list: :number         # TypeScript: scores: number[]

  # Enums (restricted values)
  prop :status, enum: ["active", "inactive", "pending"]
  # TypeScript: status: "active" | "inactive" | "pending"

  # List of enums
  prop :roles, list: [enum: ["admin", "user", "guest"]]
  # TypeScript: roles: ("admin" | "user" | "guest")[]

  # Single serializer (when nb_serializer is installed)
  prop :user, UserSerializer          # TypeScript: user: User

  # List of serializers
  prop :users, list: UserSerializer   # TypeScript: users: User[]

  # Modifiers
  prop :priority, enum: ["low", "high"], optional: true
  prop :notes, list: :string, optional: true
  prop :metadata, :map, nullable: true
end
```

**Benefits of unified syntax:**
- Same syntax as `field` in NbSerializer
- Automatic TypeScript generation (with `nb_ts`)
- Type-safe props with compile-time validation
- Clear, consistent API across the codebase

## Advanced Usage

### With NbSerializer (Optional)

If you have `nb_serializer` installed, you get automatic high-performance JSON serialization:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  inertia_page :users_index do
    prop :users, MyApp.UserSerializer  # Uses serializer for type
    prop :total_count, :integer
  end

  def index(conn, _params) do
    users = MyApp.Accounts.list_users()

    render_inertia_serialized(conn, :users_index,
      users: {MyApp.UserSerializer, users},
      total_count: length(users)
    )
  end
end
```

#### NbSerializer Functions

When `nb_serializer` is available, you get additional functions:

- **`assign_serialized/5`** - Assign single prop with automatic serialization
- **`assign_serialized_props/2`** - Assign multiple serialized props at once
- **`assign_serialized_errors/2`** - Serialize Ecto changeset validation errors
- **`render_inertia_serialized/3`** - Render with serialized props

#### Advanced Prop Options

```elixir
# Lazy evaluation - only serialize on partial reloads
assign_serialized(conn, :posts, PostSerializer, posts, lazy: true)

# Lazy function - automatically optional, only executes when requested
assign_serialized(conn, :expensive_data, DataSerializer, fn ->
  fetch_expensive_data()
end)

# Lazy function - automatically optional
assign_serialized(conn, :themes, ThemeSerializer, fn ->
  Themes.list_all_with_status()
end)

# Deferred loading - async load after initial render
assign_serialized(conn, :stats, StatsSerializer, stats, defer: true)

# Merge props - for infinite scroll/pagination
assign_serialized(conn, :items, ItemSerializer, items, merge: true)
```

### Shared Props

Define props that are available to all pages:

#### Inline Shared Props

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  # Shared across all pages in this controller
  inertia_shared do
    prop :current_user, from: :assigns
    prop :flash, from: :assigns
  end

  inertia_page :dashboard do
    prop :stats, :map
  end
end
```

#### Shared Props Modules

For more complex or application-wide shared props, create dedicated modules:

```elixir
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps

  inertia_shared do
    prop :locale, :string
    prop :current_user, :map
    prop :flash, :map
  end

  def build_props(conn, _opts) do
    %{
      locale: conn.assigns[:locale] || "en",
      current_user: conn.assigns[:current_user],
      flash: Phoenix.Controller.get_flash(conn)
    }
  end
end
```

Register the shared props module in your controller:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  # Use the shared props module
  inertia_shared(MyAppWeb.InertiaShared.Auth)

  inertia_page :dashboard do
    prop :stats, :map
  end
end
```

#### Auto-Registering Shared Props via web.ex

**Best Practice:** For shared props needed across ALL controllers, use Phoenix's `web.ex` pattern:

```elixir
# lib/my_app_web.ex
defmodule MyAppWeb do
  def controller do
    quote do
      use Phoenix.Controller
      use NbInertia.Controller

      # Auto-register base shared props for ALL controllers
      inertia_shared(MyAppWeb.InertiaShared.Base)

      import Plug.Conn
      import MyAppWeb.Gettext

      unquote(verified_routes())
    end
  end
end
```

Now every controller automatically includes base shared props without manual registration:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller  # Automatically includes Base shared props!

  # Additional controller-specific shared props (optional)
  inertia_shared(MyAppWeb.InertiaShared.Auth)

  inertia_page :dashboard do
    prop :stats, :map
  end
end
```

This pattern is ideal for app-wide data like:
- App name, version, environment
- Flash messages
- Current user (from `conn.assigns`)
- Feature flags

**See [COOKBOOK.md](COOKBOOK.md) for more patterns and examples.**

#### Conditional Shared Props

Control when shared props are included using Phoenix-style options:

```elixir
defmodule MyAppWeb.AdminController do
  use MyAppWeb, :controller

  # Only include for specific actions
  inertia_shared(MyAppWeb.InertiaShared.Admin, only: [:index, :show])

  # Exclude from specific actions
  inertia_shared(MyAppWeb.InertiaShared.Public, except: [:admin])

  # Conditional based on guard function
  inertia_shared(MyAppWeb.InertiaShared.BetaFeatures, when: :beta_enabled?)

  # Multiple conditions
  inertia_shared(MyAppWeb.InertiaShared.Analytics,
    only: [:index],
    when: :analytics_enabled?
  )

  defp beta_enabled?(conn) do
    conn.assigns[:current_user]?.beta_tester?
  end

  defp analytics_enabled?(conn) do
    Application.get_env(:my_app, :enable_analytics, false)
  end
end
```

**Options:**
- `:only` - List of actions where props should be included
- `:except` - List of actions where props should be excluded
- `:when` - Atom referencing a guard function (receives `conn`, returns boolean)

#### Deep Merging Shared Props

By default, page props override shared props (shallow merge). Enable deep merge to recursively merge nested maps:

**Global Configuration:**

```elixir
# config/config.exs
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,
  deep_merge_shared_props: true  # Default: false
```

**Per-Action Override:**

```elixir
def index(conn, _params) do
  # Shared: %{settings: %{theme: "dark", notifications: true}}
  # Page:   %{settings: %{theme: "light"}}
  # Result: %{settings: %{theme: "light", notifications: true}}

  render_inertia(conn, :index,
    [settings: %{theme: "light"}],
    deep_merge: true
  )
end
```

**Use cases:**
- Feature flags with per-page overrides
- User preferences with page-specific defaults
- Partial updates to configuration objects

#### With NbSerializer Integration

When using NbSerializer, you can specify serializers for shared props:

```elixir
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps

  inertia_shared do
    prop :locale, :string
    prop :current_user, MyApp.UserSerializer  # Automatically serialized
    prop :flash, :map
    prop :permissions, :list
  end

  def build_props(conn, _opts) do
    %{
      locale: conn.assigns[:locale] || "en",
      current_user: conn.assigns[:current_user],
      flash: Phoenix.Controller.get_flash(conn),
      permissions: conn.assigns[:permissions] || []
    }
  end
end
```

## Rendering Patterns

NbInertia supports multiple rendering patterns to fit your style:

### All-in-One Pattern (Recommended)

Provides compile-time validation in dev/test:

```elixir
def index(conn, _params) do
  render_inertia(conn, :users_index,
    users: list_users(),
    total_count: count_users(),
    filters: %{status: "active"}
  )
end
```

### Pipe-Friendly Pattern

More flexible, no compile-time validation:

```elixir
def index(conn, _params) do
  conn
  |> assign_prop(:users, list_users())
  |> assign_prop(:total_count, count_users())
  |> assign_prop(:filters, %{status: "active"})
  |> render_inertia(:users_index)
end
```

### With NbSerializer

Automatic serialization for performance:

```elixir
def index(conn, _params) do
  render_inertia(conn, :users_index,
    users: {UserSerializer, list_users()},
    pagination: {PaginationSerializer, pagination_data()},
    # Lazy function - automatically optional, only executes when requested
    analytics: {AnalyticsSerializer, fn -> fetch_analytics() end},
    total_count: count_users()
  )
end
```

### Pipe-Friendly with NbSerializer

```elixir
def index(conn, _params) do
  conn
  |> assign_serialized(:users, UserSerializer, list_users())
  |> assign_serialized(:pagination, PaginationSerializer, pagination_data())
  |> assign_prop(:total_count, count_users())
  |> render_inertia(:users_index)
end
```

## Prop Types and Validation

### Supported Primitive Types

- `:string` - String values
- `:integer` - Integer numbers
- `:float` - Floating point numbers
- `:boolean` - Boolean values
- `:map` - Map/object structures
- `:list` - List/array structures
- `:any` - Any type (no validation)

### TypeScript Types (with NbTs)

When using NbTs, you can specify exact TypeScript types:

```elixir
import NbTs.Sigil

inertia_page :dashboard do
  prop :stats, type: ~TS"{ total: number; active: number }"
  prop :status, type: ~TS"'active' | 'inactive' | 'pending'"
  prop :config, type: ~TS"Record<string, unknown>"
end
```

**Real-Time Type Regeneration:** When NbTs is installed, NbInertia automatically registers a compile hook that regenerates TypeScript types whenever your controllers are recompiled. This means your frontend types stay in sync with your backend prop definitions during development without any manual intervention.

### Serializer Types (with NbSerializer)

When NbSerializer is installed, use serializer modules as types:

```elixir
inertia_page :users_index do
  prop :users, MyApp.UserSerializer     # Single or list of users
  prop :current_user, MyApp.UserSerializer
end
```

## Compile-Time Validation

In development and test environments, NbInertia validates at compile time:

✅ **Validates:**
- All required props are provided
- No undeclared props are passed
- No collisions between shared and page props
- Prop types match declarations (when using serializers)

⚠️ **Note:** Validation is disabled in production for performance.

### Optional Props

Props can be marked as optional:

```elixir
inertia_page :users_show do
  prop :user, :map
  prop :posts, :list, optional: true      # Can be omitted
  prop :comments, :list, lazy: true       # Can be omitted
  prop :analytics, :map, defer: true      # Can be omitted
end

# Valid - optional/lazy/defer props can be omitted
render_inertia(conn, :users_show, user: user)
```

## Configuration

Configure NbInertia using the `:nb_inertia` namespace. All configuration is automatically forwarded to the underlying `:inertia` library on application startup.

```elixir
# config/config.exs
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,           # Required for SSR and versioning
  camelize_props: true,                  # Convert snake_case to camelCase (default: true)
  history: [],                           # Scroll position preservation
  static_paths: ["/css", "/js"],         # Static paths for asset versioning
  default_version: "1",                  # Asset version
  ssr: [
    enabled: false,                      # Enable SSR (default: false)
    raise_on_failure: true              # Raise on SSR errors (default: true)
  ]
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:endpoint` | module | required | Phoenix endpoint for SSR and versioning |
| `:camelize_props` | boolean | `true` | Auto-convert snake_case to camelCase |
| `:history` | keyword | `[]` | History config for scroll preservation |
| `:static_paths` | list | `[]` | Paths for asset versioning |
| `:default_version` | string | `"1"` | Default asset version |
| `:ssr` | keyword/boolean | `false` | SSR configuration (see below) |

### SSR Configuration

```elixir
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,
  ssr: [
    enabled: true,                                    # Enable SSR
    raise_on_failure: config_env() != :prod,         # Raise on errors (not in prod)
    script_path: nil,                                 # Auto-detected from endpoint
    dev_server_url: "http://localhost:5173"          # Dev server URL (optional)
  ]
```

See [RELEASES.md](RELEASES.md) for detailed SSR setup and deployment guide.

**Important:** Always configure `:nb_inertia`, not `:inertia` directly. NbInertia automatically forwards configuration to the underlying Inertia library on application startup.

## Testing

NbInertia provides comprehensive test helpers for testing Inertia pages.

### Setup Test Helpers

Import `NbInertia.TestHelpers` in your test support:

```elixir
# test/support/conn_case.ex
defmodule MyAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import NbInertia.TestHelpers

      @endpoint MyAppWeb.Endpoint
    end
  end
end
```

### Test Helper Functions

```elixir
# Make Inertia requests
conn = inertia_get(conn, ~p"/users")
conn = inertia_post(conn, ~p"/users", user: %{name: "John"})
conn = inertia_put(conn, ~p"/users/1", user: %{name: "Jane"})
conn = inertia_patch(conn, ~p"/users/1", user: %{name: "Jane"})
conn = inertia_delete(conn, ~p"/users/1")

# Assert page and props
assert_inertia_page(conn, "Users/Index")
assert_inertia_props(conn, [:users, :total_count])
assert_inertia_prop(conn, :total_count, 10)
refute_inertia_prop(conn, :secret_data)

# Assert shared props
assert_shared_props(conn, [:app_name, :version])
assert_shared_prop(conn, :current_user, %{id: 1, name: "Alice"})
refute_shared_prop(conn, :admin_settings)  # For non-admin users
assert_shared_module_props(conn, MyAppWeb.InertiaShared.Auth)
```

### Example Tests

```elixir
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase

  test "renders users index", %{conn: conn} do
    user = insert(:user, name: "John Doe")
    conn = inertia_get(conn, ~p"/users")

    assert_inertia_page(conn, "Users/Index")
    assert_inertia_props(conn, [:users, :total_count])
    assert_inertia_prop(conn, :total_count, 1)
  end

  test "creates user with valid data", %{conn: conn} do
    conn = inertia_post(conn, ~p"/users", user: %{name: "Jane", email: "jane@example.com"})

    assert redirected_to(conn) =~ ~p"/users"
  end
end
```

## Performance

### Compile-Time Validation Overhead

- **Development:** Adds ~50-100ms per controller during compilation
- **Production:** Zero overhead - validation is disabled in production
- **Benefit:** Catches errors before deployment, saves debugging time

### Serialization Performance

NbSerializer is optimized for performance while providing type safety:

```
Benchmark (serializing 100 users):
  Manual maps:          0.5ms
  NbSerializer:         0.6ms  (overhead ~20%)
  Jason.encode:         0.8ms

Benefit: Type safety + TypeScript generation + compile-time validation
```

**When to use NbSerializer:**
- ✅ Complex nested data structures
- ✅ Need TypeScript types generated
- ✅ Want compile-time type validation
- ✅ Serializing the same data multiple times

**When to use manual maps:**
- ✅ Simple, flat data
- ✅ One-off serialization
- ✅ Data already in the right format

### Shared Props Performance

Shared props are included in **every Inertia response**. Keep them minimal:

**Good (minimal):**
```elixir
%{
  current_user: %{id: 1, name: "Alice", role: "admin"},
  unread_count: 5,
  app_version: "1.0.0"
}
```

**Bad (too much data):**
```elixir
%{
  current_user: %{... 50 fields ...},
  all_users: [...],  # Entire users table!
  settings: %{... massive config ...}
}
```

**Optimization strategies:**
1. Use conditional shared props (`only:`, `when:`) to limit inclusion
2. Use lazy props for expensive data
3. Paginate large lists
4. Reduce serializer fields to only what's needed

### Response Size Optimization

**Lazy props** prevent loading expensive data unless requested:

```elixir
inertia_page :dashboard do
  prop :summary, :map
  prop :detailed_analytics, :map, lazy: true  # Only loaded when requested
  prop :audit_log, :list, lazy: true          # Only loaded when requested
end
```

**Pagination** reduces payload size:

```elixir
def index(conn, params) do
  page = Accounts.paginate_users(params, page_size: 25)

  render_inertia(conn, :index,
    users: {UserSerializer, page.entries},
    meta: %{
      current_page: page.page_number,
      total_pages: page.total_pages,
      total_count: page.total_entries
    }
  )
end
```

See [DEBUGGING.md](DEBUGGING.md) for more performance troubleshooting.

## Error Handling

### With NbSerializer

Validation errors from Ecto changesets are automatically formatted:

```elixir
def create(conn, %{"user" => user_params}) do
  case MyApp.Accounts.create_user(user_params) do
    {:ok, user} ->
      conn
      |> put_flash(:info, "User created successfully")
      |> redirect(to: ~p"/users/#{user.id}")

    {:error, changeset} ->
      conn
      |> assign_serialized_errors(changeset)
      |> put_flash(:error, "Could not create user")
      |> redirect(to: ~p"/users/new")
  end
end
```

## Integration with nb_routes

**nb_routes** generates type-safe route helpers from Phoenix routes. When used with nb_inertia, it provides enhanced form helpers for seamless HTML form integration.

### Route Helpers with Inertia

Use route helpers to navigate in your Inertia apps:

```typescript
import { router } from '@inertiajs/react';
import { users_path, user_path, edit_user_path } from './routes';

function UserCard({ user }) {
  return (
    <div>
      <a href={user_path(user.id)}>View</a>
      <button onClick={() => router.visit(edit_user_path(user.id))}>
        Edit
      </button>
    </div>
  );
}
```

### Form Helpers for Inertia

When nb_routes is configured with rich mode and form helpers, you get automatic method spoofing for HTML forms:

**Backend Configuration:**

```elixir
# config/config.exs
config :nb_routes,
  variant: :rich,
  with_methods: true,
  with_forms: true  # Enable form helpers
```

**Frontend Usage with Inertia:**

```typescript
import { router } from '@inertiajs/react';
import { update_user_path, delete_user_path } from './routes';

// Update form with PATCH
function EditUserForm({ user }) {
  const handleSubmit = (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const route = update_user_path.patch(user.id);

    router.visit(route.url, {
      method: route.method,
      data: Object.fromEntries(formData)
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input type="text" name="name" defaultValue={user.name} />
      <input type="email" name="email" defaultValue={user.email} />
      <button type="submit">Update User</button>
    </form>
  );
}

// Delete with confirmation
function DeleteUserButton({ user }) {
  const handleDelete = () => {
    if (confirm('Are you sure?')) {
      const route = delete_user_path.delete(user.id);
      router.visit(route.url, {
        method: route.method
      });
    }
  };

  return <button onClick={handleDelete}>Delete</button>;
}
```

### HTML Form Integration

For standard HTML forms (without JavaScript), form helpers automatically handle method spoofing:

```typescript
import { update_user_path, delete_user_path } from './routes';

function EditUserForm({ user }) {
  const formAttrs = update_user_path.form.patch(user.id);
  // formAttrs = { action: "/users/1?_method=PATCH", method: "post" }

  return (
    <form {...formAttrs}>
      <input type="text" name="user[name]" defaultValue={user.name} />
      <button type="submit">Update</button>
    </form>
  );
}

function DeleteUserForm({ user }) {
  const formAttrs = delete_user_path.form.delete(user.id);
  // formAttrs = { action: "/users/1?_method=DELETE", method: "post" }

  return (
    <form {...formAttrs}>
      <button type="submit">Delete User</button>
    </form>
  );
}
```

### Available Method Variants

When form helpers are enabled, you get these variants:

```typescript
// Standard route (returns { url, method })
update_user_path(1)              // => { url: "/users/1", method: "patch" }
update_user_path.patch(1)        // => { url: "/users/1", method: "patch" }
update_user_path.put(1)          // => { url: "/users/1", method: "put" }

// Form variants (returns { action, method })
update_user_path.form(1)         // => { action: "/users/1?_method=PATCH", method: "post" }
update_user_path.form.patch(1)   // => { action: "/users/1?_method=PATCH", method: "post" }
update_user_path.form.put(1)     // => { action: "/users/1?_method=PUT", method: "post" }

delete_user_path.form.delete(1)  // => { action: "/users/1?_method=DELETE", method: "post" }
```

### Query Parameters with Forms

Form helpers support query parameters:

```typescript
// Add query parameters
const route = update_user_path.patch(user.id, {
  query: { redirect_to: '/dashboard' }
});
// => { url: "/users/1?redirect_to=/dashboard", method: "patch" }

// Form with query parameters
const formAttrs = update_user_path.form.patch(user.id, {
  query: { step: '2' }
});
// => { action: "/users/1?_method=PATCH&step=2", method: "post" }
```

### TypeScript Types

Form helpers include full TypeScript support:

```typescript
import type { RouteResult, FormAttributes } from './routes';
import { update_user_path } from './routes';

// Route result
const route: RouteResult = update_user_path.patch(123);
route.url;     // string
route.method;  // 'get' | 'post' | 'patch' | 'put' | 'delete' | 'head' | 'options'

// Form attributes
const formAttrs: FormAttributes = update_user_path.form.patch(123);
formAttrs.action;  // string (URL with _method param)
formAttrs.method;  // 'get' | 'post'
```

### Setup

1. **Install nb_routes:**

```bash
mix deps.get
# Add {:nb_routes, "~> 0.1.0"} to mix.exs
```

2. **Configure rich mode with form helpers:**

```elixir
# config/config.exs
config :nb_routes,
  variant: :rich,
  with_methods: true,
  with_forms: true
```

3. **Generate route helpers:**

```bash
mix nb_routes.gen
```

4. **Optional: Auto-regeneration with nb_vite:**

```typescript
// assets/vite.config.ts
import { defineConfig } from 'vite';
import phoenix from '@nordbeam/nb-vite';
import { nbRoutes } from '@nordbeam/nb-vite/nb-routes';

export default defineConfig({
  plugins: [
    phoenix({ input: ['js/app.ts'] }),
    nbRoutes({ enabled: true })  // Auto-regenerate on router changes
  ]
});
```

See **[nb_routes documentation](https://github.com/nordbeam/nb/tree/main/nb_routes)** for more details.

## Integration with nb_routes Rich Mode (React)

When using nb_routes in rich mode, route helpers return `{ url, method }` objects (called `RouteResult`). The official `@inertiajs/react` already supports these objects natively in `router.visit()` and `Link` components via the `UrlMethodPair` type.

### What Official Inertia Already Supports

The official `@inertiajs/react` package natively accepts `{ url, method }` objects:

```typescript
import { router, Link } from '@inertiajs/react';
import { user_path, update_user_path, delete_user_path } from './routes';

// Router accepts RouteResult directly
router.visit(user_path(1));                    // GET /users/1
router.visit(update_user_path.patch(1));       // PATCH /users/1
router.visit(delete_user_path.delete(1));      // DELETE /users/1

// Link accepts RouteResult in href
<Link href={user_path(1)}>View User</Link>
<Link href={update_user_path.patch(1)}>Edit User</Link>
```

**No wrapper needed** - use `@inertiajs/react` directly for routing!

### What nb_inertia Provides

nb_inertia adds features **not** available in official Inertia:

1. **`useForm` with Route Binding** - Simplify form submission
2. **Modal System** - Open pages as modals/slideovers
3. **SSR-Safe Components** - `Head` and `usePage` with modal context support

### useForm with Route Binding

The enhanced useForm hook supports optional route binding. When bound to a RouteResult, the `submit()` method automatically uses the route's URL and method without needing to pass them explicitly.

**Import:**
```typescript
import { useForm } from '@nordbeam/nb-inertia/react/useForm';
import { update_user_path, create_user_path } from './routes';
```

**Basic Usage (Bound):**
```typescript
// Bound to a route - submit() is simplified
const form = useForm(
  { name: 'John', email: 'john@example.com' },
  update_user_path.patch(1)  // Route binding
);

// Submit automatically uses PATCH /users/1
const handleSubmit = (e) => {
  e.preventDefault();
  form.submit({
    preserveScroll: true,
    onSuccess: () => console.log('Saved!')
  });
};
```

**Basic Usage (Unbound):**
```typescript
// Not bound - works like standard Inertia useForm
const form = useForm({ name: 'John', email: 'john@example.com' });

// Must specify method and URL
const handleSubmit = (e) => {
  e.preventDefault();
  form.submit('patch', `/users/${userId}`, {
    preserveScroll: true,
    onSuccess: () => console.log('Saved!')
  });
};
```

**Form State and Methods:**
```typescript
const form = useForm({ name: '', email: '' }, update_user_path.patch(1));

// All standard useForm features work
form.setData('name', 'John');
form.setData({ name: 'Jane', email: 'jane@example.com' });
form.transform((data) => ({ ...data, timestamp: Date.now() }));
form.reset();
form.reset('name');
form.clearErrors();
form.clearErrors('name');

// Check form state
console.log(form.data);           // Current form data
console.log(form.errors);         // Validation errors
console.log(form.processing);     // Is form submitting?
console.log(form.progress);       // Upload progress
console.log(form.wasSuccessful);  // Was last submit successful?
console.log(form.recentlySuccessful); // Recently successful?
console.log(form.isDirty);        // Has form been modified?
```

**Real-World Example:**
```typescript
import { useForm } from '@nordbeam/nb-inertia/react/useForm';
import { update_user_path } from './routes';
import type { User } from './types';

interface EditUserFormProps {
  user: User;
}

export default function EditUserForm({ user }: EditUserFormProps) {
  // Bound to update route
  const form = useForm(
    {
      name: user.name,
      email: user.email,
      bio: user.bio || ''
    },
    update_user_path.patch(user.id)
  );

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Transform data before sending
    form.transform((data) => ({
      ...data,
      updated_at: new Date().toISOString()
    }));

    // Submit with options
    form.submit({
      preserveScroll: true,
      onSuccess: () => {
        // Show success message
        form.reset();
      },
      onError: (errors) => {
        // Handle errors
        console.error('Validation errors:', errors);
      }
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="name">Name</label>
        <input
          id="name"
          type="text"
          value={form.data.name}
          onChange={(e) => form.setData('name', e.target.value)}
        />
        {form.errors.name && <span className="error">{form.errors.name}</span>}
      </div>

      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          value={form.data.email}
          onChange={(e) => form.setData('email', e.target.value)}
        />
        {form.errors.email && <span className="error">{form.errors.email}</span>}
      </div>

      <div>
        <label htmlFor="bio">Bio</label>
        <textarea
          id="bio"
          value={form.data.bio}
          onChange={(e) => form.setData('bio', e.target.value)}
        />
        {form.errors.bio && <span className="error">{form.errors.bio}</span>}
      </div>

      <div className="actions">
        <button type="submit" disabled={form.processing || !form.isDirty}>
          {form.processing ? 'Saving...' : 'Save Changes'}
        </button>

        <button type="button" onClick={() => form.reset()} disabled={!form.isDirty}>
          Reset
        </button>
      </div>

      {form.recentlySuccessful && (
        <div className="success">Saved successfully!</div>
      )}
    </form>
  );
}
```

### TypeScript Support

Full TypeScript support is available:

**RouteResult Type:**
```typescript
import type { RouteResult } from '@nordbeam/nb-inertia/shared/types';

const route: RouteResult = user_path(1);
route.url;      // string
route.method;   // 'get' | 'post' | 'patch' | 'put' | 'delete' | 'head' | 'options'
```

**Link Props (Official Inertia):**
```typescript
import { Link } from '@inertiajs/react';
import { user_path } from './routes';

// Official Inertia Link accepts RouteResult via UrlMethodPair type
<Link href={user_path(1)}>View User</Link>
```

**Form Types:**
```typescript
import { useForm } from '@nordbeam/nb-inertia/react/useForm';

// Bound form (simplified submit signature)
type UserFormData = { name: string; email: string };
const boundForm = useForm(
  { name: '', email: '' },
  update_user_path.patch(1)
);
boundForm.submit({ preserveScroll: true });  // No method/URL needed

// Unbound form (standard Inertia signature)
const unboundForm = useForm({ name: '', email: '' });
unboundForm.submit('patch', '/users/1', { preserveScroll: true });
```

### Comparison with Standard Inertia.js

**Before (Manual URL Construction):**
```typescript
import { router, Link, useForm } from '@inertiajs/react';

// Manual URL construction
router.visit(`/users/${userId}`);
router.visit(`/users/${userId}`, { method: 'patch' });

// Link with manual URL
<Link href={`/users/${userId}`}>View</Link>
<Link href={`/users/${userId}`} method="patch">Edit</Link>

// Form with manual method/URL
const form = useForm({ name: '', email: '' });
form.submit('patch', `/users/${userId}`, options);
```

**After (nb_routes Rich Mode + nb_inertia useForm):**
```typescript
import { router, Link } from '@inertiajs/react';  // Official Inertia
import { useForm } from '@nordbeam/nb-inertia/react/useForm';  // nb_inertia
import { user_path, update_user_path } from './routes';  // nb_routes

// Type-safe route helpers - official Inertia supports RouteResult natively
router.visit(user_path(userId));
router.visit(update_user_path.patch(userId));

// Link with RouteResult - official Inertia supports this!
<Link href={user_path(userId)}>View</Link>
<Link href={update_user_path.patch(userId)}>Edit</Link>

// Form with route binding - nb_inertia's enhanced useForm
const form = useForm({ name: '', email: '' }, update_user_path.patch(userId));
form.submit(options);  // Method and URL from route
```

**Benefits:**
- ✅ **Type Safety** - Routes are validated at compile time
- ✅ **Refactor Safety** - Changing routes in router.ex updates all usages
- ✅ **Auto-completion** - IDE suggests available routes and parameters
- ✅ **Method Binding** - No need to manually specify HTTP methods (useForm)
- ✅ **Reduced Boilerplate** - Less code to write and maintain
- ✅ **Official Inertia Compatibility** - router and Link work out of the box

### Vue Support

Vue 3 has full support for both official Inertia routing and nb_inertia's enhanced useForm:

```vue
<script setup lang="ts">
import { router, Link } from '@inertiajs/vue3';  // Official Inertia - supports RouteResult
import { useForm } from '@nordbeam/nb-inertia/vue/useForm';  // nb_inertia
import { update_user_path, user_path } from './routes';

const props = defineProps<{ user: User }>();

// Official Inertia router and Link support RouteResult natively
const visitUser = () => router.visit(user_path(props.user.id));

// nb_inertia's useForm with route binding
const form = useForm(
  { name: props.user.name, email: props.user.email },
  update_user_path.patch(props.user.id)
);
</script>

<template>
  <!-- Official Inertia Link supports RouteResult -->
  <Link :href="user_path(user.id)">View User</Link>

  <!-- Form with route binding -->
  <form @submit.prevent="form.submit({ preserveScroll: true })">
    <input v-model="form.data.name" />
    <span v-if="form.errors.name">{{ form.errors.name }}</span>
    <button type="submit" :disabled="form.processing">Save</button>
  </form>
</template>
```

Official `@inertiajs/vue3` router and Link components already support RouteResult objects natively, so you only need nb_inertia's useForm for route binding.

### Best Practices

**1. Use Route Binding for Forms**

When the form is always submitting to the same route, use route binding:

```typescript
// ✅ Good - Bound to route
const form = useForm(initialData, update_user_path.patch(user.id));
form.submit(options);

// ❌ Less ideal - Repeating route info
const form = useForm(initialData);
const route = update_user_path.patch(user.id);
form.submit(route.method, route.url, options);
```

**2. Extract Routes to Constants for Complex Logic**

For complex navigation logic, extract the route to a constant:

```typescript
// ✅ Good - Clear and reusable
const editRoute = edit_user_path(user.id);
const deleteRoute = delete_user_path.delete(user.id);

const handleEdit = () => router.visit(editRoute);
const handleDelete = () => {
  if (confirm('Are you sure?')) {
    router.visit(deleteRoute);
  }
};
```

**3. Use Method Variants for Clarity**

Use method variants to make the HTTP method explicit:

```typescript
// ✅ Good - Method is clear
<Link href={update_user_path.patch(user.id)}>Edit</Link>
<Link href={delete_user_path.delete(user.id)}>Delete</Link>

// ⚠️ Works but less clear
<Link href={update_user_path(user.id)}>Edit</Link>
<Link href={delete_user_path(user.id)}>Delete</Link>
```

**4. Leverage TypeScript for Route Parameters**

Let TypeScript catch parameter errors:

```typescript
// ✅ TypeScript validates parameters
user_path(123);        // OK
user_path();           // Error: Missing required parameter

// ✅ Optional parameters are type-safe
users_path({ query: { filter: 'active' } });
```

**5. Mix with Standard Inertia for Flexibility**

Don't feel locked in - use plain strings when appropriate:

```typescript
// RouteResult for most cases
<Link href={user_path(user.id)}>View</Link>

// Plain string for dynamic or external URLs
<Link href={dynamicUrl}>View</Link>
<Link href="/external-page">External</Link>
```

## Modals and Slideovers

NbInertia provides built-in support for rendering pages as modals and slideovers without full page navigation, creating a smoother user experience. This feature integrates seamlessly with both the backend (Elixir) and frontend (React/Vue).

### Features

- **Backend Modal DSL**: Build modals using a fluent API in your controllers
- **Frontend Components**: Pre-built Modal and ModalLink components for React and Vue
- **Stacked Modals**: Support for nested modals with proper z-indexing
- **Configurable Appearance**: Control size, position, styling, and behavior
- **nb_routes Integration**: Works seamlessly with RouteResult objects
- **Custom Headers**: Communicates modal state via HTTP headers
- **Redirect Support**: Special redirect handling for modal workflows

### Backend Usage

#### Rendering a Modal

Use `render_inertia_modal/4` in your controller to render an Inertia page as a modal:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    render_inertia_modal(conn, :users_show,
      [user: user],
      base_url: "/users",
      size: :lg,
      position: :center
    )
  end
end
```

#### Modal Configuration Options

```elixir
render_inertia_modal(conn, :page_name,
  [props],
  # Required: Base URL for modal backdrop
  base_url: "/users",

  # Optional: Modal size
  # Options: :sm, :md, :lg, :xl, :full, or custom CSS class
  size: :lg,

  # Optional: Modal position
  # Options: :center, :top, :bottom, :left, :right
  position: :center,

  # Optional: Render as slideover instead of modal
  slideover: false,

  # Optional: Show close button (default: true)
  close_button: true,

  # Optional: Require explicit close (disable ESC/backdrop click)
  close_explicitly: false,

  # Optional: Custom max-width (e.g., "800px", "50rem")
  max_width: nil,

  # Optional: Custom CSS classes
  padding_classes: "p-6",
  panel_classes: "bg-white rounded-lg shadow-xl",
  backdrop_classes: "bg-black/50"
)
```

#### Rendering a Slideover

```elixir
def edit(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)

  render_inertia_modal(conn, :users_edit,
    [user: user, changeset: Accounts.change_user(user)],
    base_url: "/users/#{id}",
    slideover: true,
    position: :right,
    size: :lg
  )
end
```

#### Using the Modal DSL

For more complex modal configuration, use the Modal DSL:

```elixir
alias NbInertia.Modal

def show(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)

  modal =
    Modal.new("Users/Show", %{user: user})
    |> Modal.base_url("/users")
    |> Modal.size(:lg)
    |> Modal.position(:center)
    |> Modal.close_button(true)

  render(conn, modal)
end
```

#### Redirecting from Modals

Use `redirect_modal/2` to redirect after modal operations:

```elixir
def create(conn, %{"user" => user_params}) do
  case Accounts.create_user(user_params) do
    {:ok, user} ->
      conn
      |> put_flash(:info, "User created successfully")
      |> redirect_modal(to: "/users")

    {:error, changeset} ->
      render_inertia_modal(conn, :users_new,
        [form: changeset],
        base_url: "/users"
      )
  end
end
```

### Frontend Usage (React)

#### Using the Modal Component

Import and use the Modal component with nb_routes integration:

```typescript
import { Modal } from '@/modals/Modal';
import { user_path } from '@/routes';
import type { User } from '@/types';

interface UserShowProps {
  user: User;
}

export default function UserShow({ user }: UserShowProps) {
  return (
    <Modal
      baseUrl={user_path(user.id).url}
      config={{
        size: 'lg',
        position: 'center',
        closeButton: true
      }}
    >
      {(close) => (
        <div>
          <h2>{user.name}</h2>
          <p>{user.email}</p>
          <button onClick={close}>Close</button>
        </div>
      )}
    </Modal>
  );
}
```

#### Using ModalLink

ModalLink opens pages as modals when clicked:

```typescript
import { ModalLink } from '@/modals/ModalLink';
import { user_path, edit_user_path } from '@/routes';

function UserList({ users }) {
  return (
    <div>
      {users.map(user => (
        <div key={user.id}>
          <h3>{user.name}</h3>

          {/* Basic modal link */}
          <ModalLink href={user_path(user.id)}>
            View Details
          </ModalLink>

          {/* With custom modal config */}
          <ModalLink
            href={edit_user_path(user.id)}
            modalConfig={{
              slideover: true,
              position: 'right',
              size: 'lg'
            }}
          >
            Edit User
          </ModalLink>
        </div>
      ))}
    </div>
  );
}
```

#### Slideover Example

```typescript
export default function UserEdit({ user, changeset }: UserEditProps) {
  const form = useForm(
    { name: user.name, email: user.email },
    update_user_path.patch(user.id)
  );

  return (
    <Modal
      baseUrl={user_path(user.id).url}
      config={{
        slideover: true,
        position: 'right',
        size: 'lg',
        closeButton: true
      }}
    >
      {(close) => (
        <div>
          <h2>Edit User</h2>
          <form onSubmit={(e) => {
            e.preventDefault();
            form.submit({
              onSuccess: () => close()
            });
          }}>
            <input
              type="text"
              value={form.data.name}
              onChange={e => form.setData('name', e.target.value)}
            />
            {form.errors.name && <div className="error">{form.errors.name}</div>}

            <button type="submit" disabled={form.processing}>
              Save
            </button>
            <button type="button" onClick={close}>
              Cancel
            </button>
          </form>
        </div>
      )}
    </Modal>
  );
}
```

### Frontend Usage (Vue)

#### Using the Modal Component

```vue
<script setup lang="ts">
import { Modal } from '@/modals/Modal.vue';
import { user_path } from '@/routes';
import type { User } from '@/types';

interface Props {
  user: User;
}

const props = defineProps<Props>();
</script>

<template>
  <Modal
    :base-url="user_path(user.id).url"
    :config="{
      size: 'lg',
      position: 'center',
      closeButton: true
    }"
    v-slot="{ close }"
  >
    <div>
      <h2>{{ user.name }}</h2>
      <p>{{ user.email }}</p>
      <button @click="close">Close</button>
    </div>
  </Modal>
</template>
```

#### Using ModalLink (Vue)

```vue
<script setup lang="ts">
import { ModalLink } from '@/modals/ModalLink.vue';
import { user_path, edit_user_path } from '@/routes';
import type { User } from '@/types';

interface Props {
  users: User[];
}

const props = defineProps<Props>();
</script>

<template>
  <div>
    <div v-for="user in users" :key="user.id">
      <h3>{{ user.name }}</h3>

      <!-- Basic modal link -->
      <ModalLink :href="user_path(user.id)">
        View Details
      </ModalLink>

      <!-- With custom modal config -->
      <ModalLink
        :href="edit_user_path(user.id)"
        :modal-config="{
          slideover: true,
          position: 'right',
          size: 'lg'
        }"
      >
        Edit User
      </ModalLink>
    </div>
  </div>
</template>
```

### Configuration Reference

#### Size Options

- `:sm` - Small modal (max-width: 400px)
- `:md` - Medium modal (max-width: 600px) - **default**
- `:lg` - Large modal (max-width: 800px)
- `:xl` - Extra large modal (max-width: 1024px)
- `:full` - Full screen modal
- Custom CSS class string (e.g., "max-w-4xl")

#### Position Options

- `:center` - Centered modal - **default**
- `:top` - Top-aligned modal
- `:bottom` - Bottom-aligned modal
- `:left` - Left-aligned (for slideovers)
- `:right` - Right-aligned (for slideovers)
- Custom CSS class string

#### Global Configuration

Create `config/nb_inertia_modal.exs` to set application-wide defaults:

```elixir
import Config

config :nb_inertia, :modal,
  default_size: :md,
  default_position: :center,
  default_close_button: true,
  default_close_explicitly: false,
  default_padding_classes: "p-6",
  default_panel_classes: "bg-white rounded-lg shadow-xl",
  default_backdrop_classes: "bg-black/50"

config :nb_inertia, :slideover,
  default_position: :right,
  default_size: :md
```

### Advanced Usage

#### Nested Modals

Modals automatically support nesting with proper z-index management:

```typescript
<Modal baseUrl="/users" config={{ size: 'lg' }}>
  {(closeOuter) => (
    <div>
      <h2>User Details</h2>
      <ModalLink
        href={edit_user_path(user.id)}
        modalConfig={{ size: 'md' }}
      >
        Edit (opens nested modal)
      </ModalLink>
      <button onClick={closeOuter}>Close</button>
    </div>
  )}
</Modal>
```

#### Form in Modal

```typescript
import { useForm } from '@nordbeam/nb-inertia/react/useForm';
import { create_user_path } from '@/routes';

export default function CreateUser() {
  const form = useForm(
    { name: '', email: '' },
    create_user_path.post()
  );

  return (
    <Modal
      baseUrl="/users"
      config={{
        size: 'lg',
        closeExplicitly: true
      }}
    >
      {(close) => (
        <form onSubmit={(e) => {
          e.preventDefault();
          form.submit({
            onSuccess: () => close()
          });
        }}>
          <h2>Create User</h2>

          <div>
            <label>Name</label>
            <input
              type="text"
              value={form.data.name}
              onChange={e => form.setData('name', e.target.value)}
            />
            {form.errors.name && <span className="error">{form.errors.name}</span>}
          </div>

          <div>
            <label>Email</label>
            <input
              type="email"
              value={form.data.email}
              onChange={e => form.setData('email', e.target.value)}
            />
            {form.errors.email && <span className="error">{form.errors.email}</span>}
          </div>

          <div>
            <button type="submit" disabled={form.processing}>
              {form.processing ? 'Creating...' : 'Create User'}
            </button>
            <button type="button" onClick={close}>
              Cancel
            </button>
          </div>
        </form>
      )}
    </Modal>
  );
}
```

### Setup

#### 1. Add Modal Plug

Add the modal headers plug to your router pipeline:

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import NbInertia.Plugs.ModalHeaders

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Inertia.Plug
    plug :modal_headers  # Add this line
  end
end
```

#### 2. Install Dependencies

The modal components use Radix UI for React:

```bash
cd assets
npm install @radix-ui/react-dialog
```

For Vue, the components use Headless UI:

```bash
cd assets
npm install @headlessui/vue@latest
```

#### 3. Import Modal Components

In your Inertia pages, import modal components from the nb_inertia package:

```typescript
// React
import { Modal } from '@/modals/Modal';
import { ModalLink } from '@/modals/ModalLink';

// Vue
import { Modal } from '@/modals/Modal.vue';
import { ModalLink } from '@/modals/ModalLink.vue';
```

## Real-Time Updates via Phoenix Channels

NbInertia provides real-time prop updates via Phoenix Channels, eliminating the need for polling. This integration leverages Phoenix's excellent WebSocket support while maintaining Inertia.js's prop-based architecture.

### Setup

Run the generator to set up WebSocket support:

```bash
mix nb_inertia.gen.realtime
```

### Usage

```typescript
import { socket, useChannel, useRealtimeProps } from '@/lib/socket';
import type { ChatRoomProps } from '@/types';

export default function ChatRoom({ room }: ChatRoomProps) {
  const { props, setProp } = useRealtimeProps<ChatRoomProps>();

  useChannel(socket, `chat:${room.id}`, {
    message_created: ({ message }) => {
      setProp('messages', msgs => [...msgs, message]);
    },
    message_deleted: ({ id }) => {
      setProp('messages', msgs => msgs.filter(m => m.id !== id));
    }
  });

  return (
    <div>
      {props.messages.map(msg => (
        <Message key={msg.id} message={msg} />
      ))}
    </div>
  );
}
```

### Declarative Strategies

For complex apps, use `useChannelProps` for declarative event handling:

```typescript
import { socket, useChannelProps } from '@/lib/socket';

const { props } = useChannelProps(socket, `chat:${room.id}`, {
  message_created: { prop: 'messages', strategy: 'append', transform: e => e.message },
  message_deleted: { prop: 'messages', strategy: 'remove', match: (msg, e) => msg.id === e.id },
  message_edited: { prop: 'messages', strategy: 'update', key: 'id', transform: e => e.message },
  room_updated: { prop: 'room', strategy: 'replace', transform: e => e.room }
});
```

**Available Strategies:**
- `append` / `prepend` - Add items to arrays
- `remove` - Remove items matching predicate
- `update` / `upsert` - Update items in place
- `replace` - Replace entire prop
- `reload` - Reload prop(s) from server

### Available Hooks

- `useChannel` - Subscribe to Phoenix Channel events
- `useRealtimeProps` - Manage props with optimistic updates
- `usePresence` - Track Phoenix Presence state
- `useChannelProps` - Declarative event-to-prop mapping

## Credo Checks

NbInertia includes 8 custom Credo checks for code quality:

| Check | Priority | Description |
|-------|----------|-------------|
| `NbInertia.Credo.InertiaPageWithoutProps` | HIGH | Detects `inertia_page` blocks without any props |
| `NbInertia.Credo.DuplicateProps` | HIGH | Detects duplicate prop definitions |
| `NbInertia.Credo.MissingSharedPropsModule` | NORMAL | Warns when `inertia_shared` references missing module |
| `NbInertia.Credo.UnusedInertiaPage` | NORMAL | Detects unused `inertia_page` definitions |
| `NbInertia.Credo.LargePropsCount` | LOW | Warns when page has too many props (configurable) |
| `NbInertia.Credo.PropWithoutType` | HIGH | Detects props without explicit types |
| `NbInertia.Credo.SharedPropsCollision` | HIGH | Detects prop name collisions between shared and page props |
| `NbInertia.Credo.MissingSerializerType` | NORMAL | Warns when using serializer without proper type annotation |

Enable in `.credo.exs`:

```elixir
%{
  configs: [
    %{
      checks: [
        {NbInertia.Credo.PropWithoutType, []},
        {NbInertia.Credo.DuplicateProps, []},
        {NbInertia.Credo.SharedPropsCollision, []},
        # ... other checks
      ]
    }
  ]
}
```

## Related Projects

- **[NbRoutes](https://github.com/nordbeam/nb_routes)** - Type-safe route helpers with form integration
- **[NbSerializer](https://github.com/nordbeam/nb_serializer)** - High-performance JSON serialization
- **[NbTs](https://github.com/nordbeam/nb_ts)** - TypeScript type generation and validation
- **[NbVite](https://github.com/nordbeam/nb_vite)** - Vite integration for Phoenix

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/nb_inertia).

### Guides

- **[COOKBOOK.md](COOKBOOK.md)** - Patterns and recipes
  - Shared props strategies (web.ex, conditional, organizing modules)
  - Deep merging nested data
  - Testing patterns with examples
  - Common use cases (auth, flash, feature flags, notifications)
  - Best practices

- **[MIGRATION.md](MIGRATION.md)** - Migrating from plain Inertia
  - Step-by-step migration guide
  - Three migration options (minimal, recommended, full type safety)
  - Common migration issues and solutions
  - Rollback plan if needed
  - Timeline estimates by team size

- **[DEBUGGING.md](DEBUGGING.md)** - Troubleshooting guide
  - Compile-time errors (missing props, collisions, etc.)
  - Runtime errors (guard functions, camelization, etc.)
  - Props issues (nil handling, performance)
  - Shared props issues (not appearing, overriding)
  - TypeScript issues (generation, stale types)
  - SSR issues (bundle not found, rendering failures)
  - Testing issues

- **[RELEASES.md](RELEASES.md)** - Deployment and SSR
  - Production deployment guide
  - SSR configuration for Docker, Fly.io, etc.
  - Zero-config default setup
  - Troubleshooting production issues

### Quick Links

- **Getting Started:** See [Installation](#installation) section above
- **Shared Props:** See [COOKBOOK.md - Shared Props Patterns](COOKBOOK.md#shared-props-patterns)
- **TypeScript Integration:** See [TypeScript Types](#typescript-types) section above
- **Common Issues:** See [DEBUGGING.md](DEBUGGING.md)
- **Examples:** See [COOKBOOK.md - Common Use Cases](COOKBOOK.md#common-use-cases)

## License

MIT License. See [LICENSE](LICENSE) for details.

## Credits

Built by [Nordbeam](https://github.com/nordbeam) as part of the NbSerializer ecosystem.
