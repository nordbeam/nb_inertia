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

## Installation

### Quick Start (Recommended)

Use the automated installer for complete setup:

```bash
mix nb_inertia.install
```

For TypeScript support, add the `--typescript` flag:

```bash
mix nb_inertia.install --typescript
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
