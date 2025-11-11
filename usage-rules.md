# NbInertia Usage Rules

## Overview

NbInertia provides advanced Inertia.js integration for Phoenix:
- **Declarative page DSL** - Define pages and props with compile-time validation
- **Component name inference** - Auto-convert `:users_index` to `"Users/Index"`
- **Shared props** - Define props shared across all pages with conditional inclusion
- **Type safety** - Compile-time validation in dev/test with prop collision detection
- **Deep merging** - Recursively merge nested shared and page props
- **SSR support** - Built-in server-side rendering with DenoRider
- **NbSerializer integration** - Optional high-performance serialization
- **Test helpers** - Comprehensive testing utilities including shared props assertions

## Recent Features

### Conditional Shared Props
Control when shared props are included using `:only`, `:except`, and `:when` options:
```elixir
inertia_shared(MyAppWeb.InertiaShared.Admin, only: [:index, :show])
inertia_shared(MyAppWeb.InertiaShared.BetaFeatures, when: :beta_enabled?)
```

### Auto-Registration via web.ex
Register base shared props globally in `web.ex` for all controllers:
```elixir
defmodule MyAppWeb do
  def controller do
    quote do
      use Phoenix.Controller
      use NbInertia.Controller
      inertia_shared(MyAppWeb.InertiaShared.Base)  # Auto-included!
    end
  end
end
```

### Deep Merging
Recursively merge nested maps in shared and page props:
```elixir
# Global config
config :nb_inertia, deep_merge_shared_props: true

# Per-action override
render_inertia(conn, :index, [settings: %{theme: "light"}], deep_merge: true)
```

### Prop Collision Detection
Compile-time validation prevents naming conflicts between shared and page props:
```elixir
# ❌ CompileError: "user" defined in both shared and page props
inertia_shared do
  prop :user, :map
end

inertia_page :index do
  prop :user, UserSerializer
end
```

### Custom TypeScript Type Names
Prevent type name collisions when multiple pages use the same component:
```elixir
inertia_page :preview,
  component: "Public/WidgetShow",
  type_name: "WidgetPreviewProps" do
  prop :widget, WidgetSerializer
end
```

## Installation

### Quick Start
```bash
mix nb_inertia.install                # Basic installation
mix nb_inertia.install --typescript   # With TypeScript support
```

### Manual Installation
```elixir
# mix.exs
def deps do
  [
    {:nb_inertia, "~> 0.1"},
    {:nb_serializer, "~> 0.1", optional: true},  # Optional
    {:nb_ts, "~> 0.1", optional: true}           # Optional
  ]
end
```

## Configuration

```elixir
# config/config.exs
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,           # Required for SSR/versioning
  camelize_props: true,                  # Auto snake_case → camelCase (default: true)
  deep_merge_shared_props: false,        # Deep merge shared props with page props (default: false)
  static_paths: ["/css", "/js"],         # Paths for asset versioning
  default_version: "1",                  # Asset version
  ssr: [
    enabled: false,                      # Enable SSR (default: false)
    raise_on_failure: true              # Raise on SSR errors (default: true)
  ]
```

**Key Points:**
- Always configure `:nb_inertia`, NOT `:inertia`
- NbInertia automatically forwards config to base Inertia library
- `:deep_merge_shared_props` - When `true`, nested maps in shared and page props are recursively merged
- See [RELEASES.md](RELEASES.md) for SSR deployment guide

## Basic Usage

### Define Inertia Pages

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  # Define page and props
  inertia_page :users_index do
    prop :users, :list
    prop :total_count, :integer
    prop :filters, :map, optional: true
  end

  def index(conn, params) do
    users = list_users(params)

    render_inertia(conn, :users_index,
      users: users,
      total_count: length(users),
      filters: params["filters"]
    )
  end
end
```

### Unified Prop Syntax

NbInertia uses a unified syntax matching NbSerializer's field syntax:

**Primitives:**
```elixir
prop :id, :integer
prop :name, :string
prop :active, :boolean
prop :metadata, :map
prop :data, :any
```

**Lists of primitives:**
```elixir
prop :tags, list: :string      # TypeScript: tags: string[]
prop :scores, list: :number    # TypeScript: scores: number[]
```

**Enums (restricted values):**
```elixir
prop :status, enum: ["active", "inactive", "pending"]
# TypeScript: status: "active" | "inactive" | "pending"
```

**List of enums:**
```elixir
prop :roles, list: [enum: ["admin", "user", "guest"]]
# TypeScript: roles: ("admin" | "user" | "guest")[]
```

**With NbSerializer - Single serializer:**
```elixir
prop :user, UserSerializer      # TypeScript: user: User
```

**With NbSerializer - List of serializers:**
```elixir
prop :users, list: UserSerializer  # TypeScript: users: User[]
```

**Modifiers:**
```elixir
prop :priority, enum: ["low", "high"], optional: true
prop :notes, list: :string, optional: true
prop :metadata, :map, nullable: true
```

**Custom TypeScript types (with NbTs):**
```elixir
import NbTs.Sigil

prop :stats, type: ~TS"{ total: number; active: number }"
prop :status, type: ~TS"'active' | 'inactive'"
```

## Component Name Inference

Page atoms automatically convert to React component paths:

| Page Atom | Component Path |
|-----------|----------------|
| `:users_index` | `"Users/Index"` |
| `:users_show` | `"Users/Show"` |
| `:users_new` | `"Users/New"` |
| `:admin_users_index` | `"Admin/Users/Index"` |
| `:admin_dashboard` | `"Admin/Dashboard"` |
| `:dashboard` | `"Dashboard"` |
| `:settings` | `"Settings"` |

**Override component name:**
```elixir
inertia_page :custom, component: "Custom/Component" do
  prop :data, :map
end
```

**Custom TypeScript type name:**
```elixir
# Prevents type collisions when multiple pages use same component
inertia_page :preview,
  component: "Public/WidgetShow",
  type_name: "WidgetPreviewProps" do
  prop :widget, WidgetSerializer
end
```

Without `type_name`, both pages would generate `PublicWidgetShowProps`.
With `type_name`, you can explicitly name types to avoid collisions.

## Rendering Patterns

### Basic Rendering (Recommended)
```elixir
def index(conn, _params) do
  render_inertia(conn, :users_index,
    users: list_users(),
    total_count: count_users()
  )
end
```

### With Deep Merge (Per-Action Override)
```elixir
def index(conn, _params) do
  # Shared props: %{settings: %{theme: "dark", notifications: true}}
  # Page props:   %{settings: %{theme: "light"}}
  # Result:       %{settings: %{theme: "light", notifications: true}}

  render_inertia(conn, :index,
    [settings: %{theme: "light"}],
    deep_merge: true  # Overrides global config
  )
end
```

**Use cases for deep merge:**
- Feature flags with per-page overrides
- User preferences with page-specific defaults
- Partial updates to configuration objects

### Pipe-Friendly
```elixir
def index(conn, _params) do
  conn
  |> assign_prop(:users, list_users())
  |> assign_prop(:total_count, count_users())
  |> render_inertia(:users_index)
end
```

### With NbSerializer (High Performance)
```elixir
def index(conn, _params) do
  render_inertia_serialized(conn, :users_index,
    users: {UserSerializer, list_users()},
    pagination: {PaginationSerializer, pagination()}
  )
end
```

## Advanced Features (with NbSerializer)

### Serializer Functions
- `assign_serialized/5` - Assign with automatic serialization
- `assign_serialized_props/2` - Batch assign serialized props
- `assign_serialized_errors/2` - Serialize Ecto changeset errors
- `render_inertia_serialized/3` - Render with serialized props

### Advanced Prop Options
```elixir
# Lazy - only load on partial reloads
assign_serialized(conn, :posts, PostSerializer, posts, lazy: true)

# Defer - async load after initial render
assign_serialized(conn, :stats, StatsSerializer, stats, defer: true)

# Merge - for infinite scroll/pagination
assign_serialized(conn, :items, ItemSerializer, items, merge: true)

# Optional - excluded on first visit
assign_serialized(conn, :data, DataSerializer, data, optional: true)
```

## Shared Props

Shared props are included in **every Inertia response** from a controller.

### Inline Shared Props
```elixir
defmodule MyAppWeb.UserController do
  use NbInertia.Controller

  # Inline shared props
  inertia_shared do
    prop :current_user, from: :assigns
    prop :flash, from: :assigns
  end

  inertia_page :index do
    prop :users, :list
  end
end
```

### Shared Props Modules
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

Register in controller:
```elixir
defmodule MyAppWeb.UserController do
  use NbInertia.Controller

  inertia_shared(MyAppWeb.InertiaShared.Auth)

  inertia_page :index do
    prop :users, :list
  end
end
```

### Auto-Register via web.ex (Recommended)

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

Now every controller automatically includes base shared props:

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

### Conditional Shared Props

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

### Deep Merging Shared Props

By default, page props override shared props (shallow merge). Enable deep merge to recursively merge nested maps:

**Global Configuration:**
```elixir
# config/config.exs
config :nb_inertia,
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

### Prop Name Collision Detection

NbInertia validates at compile-time that shared props and page props don't have naming conflicts:

```elixir
# ❌ This will raise a CompileError
defmodule MyAppWeb.UserController do
  use NbInertia.Controller

  inertia_shared do
    prop :user, :map  # Collision!
  end

  inertia_page :index do
    prop :user, UserSerializer  # Collision!
  end
end
```

**Fix strategies:**
1. Rename shared props to be more specific (`:auth_user`, `:global_flash`)
2. Rename page props (`:page_user`)
3. Use namespacing (shared: `:auth`, page: `:users`)

**Performance Best Practice:** Keep shared props minimal - they're included in every response!

## Testing

### Setup
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

### Test Helpers

**Request helpers:**
```elixir
conn = inertia_get(conn, ~p"/users")
conn = inertia_post(conn, ~p"/users", user: params)
conn = inertia_put(conn, ~p"/users/1", user: params)
conn = inertia_patch(conn, ~p"/users/1", user: params)
conn = inertia_delete(conn, ~p"/users/1")
```

**Page and prop assertions:**
```elixir
assert_inertia_page(conn, "Users/Index")
assert_inertia_props(conn, [:users, :total_count])
assert_inertia_prop(conn, :total_count, 10)
refute_inertia_prop(conn, :secret_data)
```

**Shared props assertions:**
```elixir
# Assert specific shared props are present
assert_shared_props(conn, [:current_user, :flash])

# Assert a shared prop has expected value
assert_shared_prop(conn, :app_name, "MyApp")
assert_shared_prop(conn, :current_user, %{id: 1, name: "Alice"})

# Assert a shared prop is NOT present (e.g., admin-only data)
refute_shared_prop(conn, :admin_settings)

# Assert all props from a SharedProps module are present
assert_shared_module_props(conn, MyAppWeb.InertiaShared.Auth)
```

### Example Tests

**Basic page test:**
```elixir
test "renders users index", %{conn: conn} do
  user = insert(:user, name: "John")
  conn = inertia_get(conn, ~p"/users")

  assert_inertia_page(conn, "Users/Index")
  assert_inertia_props(conn, [:users, :total_count])
  assert_inertia_prop(conn, :total_count, 1)
end
```

**Testing shared props:**
```elixir
test "includes authentication shared props", %{conn: conn} do
  user = insert(:user, name: "Alice")

  conn =
    conn
    |> assign(:current_user, user)
    |> inertia_get(~p"/dashboard")

  # Test shared props are included
  assert_shared_props(conn, [:current_user, :flash])
  assert_shared_prop(conn, :current_user, %{id: user.id, name: "Alice"})
end
```

**Testing conditional shared props:**
```elixir
test "admin data only visible to admins", %{conn: conn} do
  regular_user = insert(:user, role: :user)
  admin_user = insert(:user, role: :admin)

  # Regular user should not see admin data
  conn =
    conn
    |> assign(:current_user, regular_user)
    |> inertia_get(~p"/dashboard")

  refute_shared_prop(conn, :admin_settings)

  # Admin user should see admin data
  conn =
    build_conn()
    |> assign(:current_user, admin_user)
    |> inertia_get(~p"/dashboard")

  assert_shared_prop(conn, :admin_settings)
end
```

## Performance and Best Practices

### Compile-Time Validation

- **Development:** Adds ~50-100ms per controller during compilation
- **Production:** Zero overhead - validation is disabled in production
- **Benefit:** Catches errors before deployment, saves debugging time

### Shared Props Performance

Shared props are included in **every Inertia response**. Keep them minimal:

**✅ Good (minimal):**
```elixir
%{
  current_user: %{id: 1, name: "Alice", role: "admin"},
  unread_count: 5,
  app_version: "1.0.0"
}
```

**❌ Bad (too much data):**
```elixir
%{
  current_user: %{... 50 fields ...},
  all_users: [...],  # Entire users table!
  settings: %{... massive config ...}
}
```

**Optimization strategies:**
1. Use conditional shared props (`:only`, `:when`) to limit inclusion
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

### NbSerializer Performance

NbSerializer is optimized for performance while providing type safety:

**Benchmark (serializing 100 users):**
- Manual maps: 0.5ms
- NbSerializer: 0.6ms (overhead ~20%)
- Jason.encode: 0.8ms

**When to use NbSerializer:**
- ✅ Complex nested data structures
- ✅ Need TypeScript types generated
- ✅ Want compile-time type validation
- ✅ Serializing the same data multiple times

**When to use manual maps:**
- ✅ Simple, flat data
- ✅ One-off serialization
- ✅ Data already in the right format

### Best Practices Summary

1. **Shared Props**: Keep minimal, use conditional inclusion
2. **Lazy Props**: Use for expensive/large data
3. **Pagination**: Always paginate large lists
4. **Deep Merge**: Only enable when needed for nested configs
5. **Type Safety**: Use NbSerializer + NbTs for complex apps
6. **Testing**: Test both page props and shared props
7. **Performance**: Monitor response sizes in production

See [DEBUGGING.md](DEBUGGING.md) for troubleshooting and [COOKBOOK.md](COOKBOOK.md) for more patterns.

## Quick Reference

### Configuration Options

```elixir
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,           # Required for SSR/versioning
  camelize_props: true,                  # Auto camelCase (default: true)
  deep_merge_shared_props: false,        # Deep merge shared props (default: false)
  static_paths: ["/css", "/js"],         # Asset versioning paths
  default_version: "1",                  # Asset version
  ssr: [
    enabled: false,                      # Enable SSR (default: false)
    raise_on_failure: true              # Raise on SSR errors (default: true)
  ]
```

### Shared Props API

```elixir
# Inline shared props
inertia_shared do
  prop :current_user, from: :assigns
end

# Register SharedProps module
inertia_shared(MyAppWeb.InertiaShared.Auth)

# Conditional shared props
inertia_shared(Module, only: [:index, :show])
inertia_shared(Module, except: [:admin])
inertia_shared(Module, when: :guard_function?)
inertia_shared(Module, only: [:index], when: :enabled?)
```

### Render Options

```elixir
# Basic rendering
render_inertia(conn, :page_name, [prop: value])

# With deep merge
render_inertia(conn, :page_name, [prop: value], deep_merge: true)

# With NbSerializer
render_inertia_serialized(conn, :page_name, prop: {Serializer, data})
```

### Page Options

```elixir
# Custom component name
inertia_page :name, component: "Custom/Component" do
  prop :data, :map
end

# Custom TypeScript type name
inertia_page :name, type_name: "CustomProps" do
  prop :data, :map
end

# Both options
inertia_page :name,
  component: "Public/Widget",
  type_name: "WidgetPreviewProps" do
  prop :widget, WidgetSerializer
end
```

### Test Helpers

```elixir
# Request helpers
conn = inertia_get(conn, ~p"/path")
conn = inertia_post(conn, ~p"/path", params)

# Page assertions
assert_inertia_page(conn, "Component/Name")
assert_inertia_props(conn, [:prop1, :prop2])
assert_inertia_prop(conn, :prop, value)
refute_inertia_prop(conn, :prop)

# Shared props assertions
assert_shared_props(conn, [:current_user, :flash])
assert_shared_prop(conn, :prop, value)
refute_shared_prop(conn, :prop)
assert_shared_module_props(conn, MyAppWeb.InertiaShared.Auth)
```

### Prop Type Syntax

```elixir
# Primitives
prop :name, :string
prop :count, :integer
prop :active, :boolean
prop :data, :map
prop :anything, :any

# Lists
prop :tags, list: :string
prop :users, list: UserSerializer

# Enums
prop :status, enum: ["active", "inactive"]
prop :roles, list: [enum: ["admin", "user"]]

# Options
prop :data, :map, optional: true
prop :value, :string, nullable: true
prop :expensive, :map, lazy: true

# Custom TypeScript types
prop :stats, type: ~TS"{ total: number; active: number }"
```

## Additional Resources

- **[README.md](README.md)** - Full documentation with examples
- **[COOKBOOK.md](COOKBOOK.md)** - Patterns and recipes
- **[MIGRATION.md](MIGRATION.md)** - Migrating from plain Inertia
- **[DEBUGGING.md](DEBUGGING.md)** - Troubleshooting guide
- **[RELEASES.md](RELEASES.md)** - Deployment and SSR setup
