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

# Deferred loading - async load after initial render
assign_serialized(conn, :stats, StatsSerializer, stats, defer: true)

# Merge props - for infinite scroll/pagination
assign_serialized(conn, :items, ItemSerializer, items, merge: true)

# Optional props - excluded on first visit
assign_serialized(conn, :expensive_data, DataSerializer, data, optional: true)
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
  render_inertia_serialized(conn, :users_index,
    users: {UserSerializer, list_users()},
    pagination: {PaginationSerializer, pagination_data()},
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

## Related Projects

- **[NbSerializer](https://github.com/nordbeam/nb_serializer)** - High-performance JSON serialization
- **[NbTs](https://github.com/nordbeam/nb_ts)** - TypeScript type generation and validation
- **[NbVite](https://github.com/nordbeam/nb_vite)** - Vite integration for Phoenix

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/nb_inertia).

Additional guides:
- [RELEASES.md](RELEASES.md) - Deployment and SSR configuration guide

## License

MIT License. See [LICENSE](LICENSE) for details.

## Credits

Built by [Nordbeam](https://github.com/nordbeam) as part of the NbSerializer ecosystem.
