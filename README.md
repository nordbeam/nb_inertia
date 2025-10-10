# NbInertia

Advanced Inertia.js integration for Phoenix with declarative page DSL, type-safe props, shared props, and optional NbSerializer support.

## Features

- **Declarative Page DSL**: Define pages and their props with compile-time validation
- **Component Name Inference**: Automatic conversion from `:users_index` to `"Users/Index"`
- **Shared Props**: Define props shared across all pages (inline or as modules)
- **Type Safety**: Compile-time prop validation in dev/test environments
- **NbSerializer Integration**: Optional automatic serialization with NbSerializer
- **Flexible Rendering**: Support for both all-in-one and pipe-friendly patterns
- **Optional Dependency**: NbSerializer is completely optional - use raw props if you prefer

## Installation

Add `nb_inertia` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nb_inertia, "~> 0.1"},
    {:nb_serializer, "~> 0.1", optional: true}  # Optional
  ]
end
```

## Basic Usage (Without NbSerializer)

In your controller, use `NbInertia.Controller`:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  inertia_page :users_index do
    prop :users, :list
    prop :total_count, :integer
  end

  def index(conn, _params) do
    users = MyApp.Accounts.list_users()

    render_inertia(conn, :users_index,
      users: users,
      total_count: length(users)
    )
  end
end
```

The component name is automatically inferred from the page atom:
- `:users_index` → `"Users/Index"`
- `:users_show` → `"Users/Show"`
- `:admin_users_index` → `"Admin/Users/Index"`
- `:dashboard` → `"Dashboard"`

## With NbSerializer (Optional)

If you have `nb_serializer` installed, you can use automatic serialization:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  inertia_page :users_index do
    prop :users, MyApp.UserSerializer
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

### NbSerializer Integration Features

When `nb_serializer` is available, you get:

- `assign_serialized/5` - Assign props with automatic serialization
- `assign_serialized_props/2` - Assign multiple serialized props at once
- `assign_serialized_errors/2` - Serialize validation errors from changesets
- `render_inertia_serialized/3` - Render with serialized props
- Support for lazy, optional, deferred, and merge props

```elixir
# Lazy evaluation (only serialize on partial reloads)
assign_serialized(conn, :posts, PostSerializer, posts, lazy: true)

# Deferred loading (async after initial render)
assign_serialized(conn, :stats, StatsSerializer, stats, defer: true)

# Merge props (for infinite scroll)
assign_serialized(conn, :items, ItemSerializer, items, merge: true)

# Optional props (excluded on first visit)
assign_serialized(conn, :expensive_data, DataSerializer, data, optional: true)
```

## Shared Props

Define props shared across all pages:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  inertia_shared do
    prop :current_user, from: :assigns
    prop :flash, from: :assigns
  end

  inertia_page :dashboard do
    prop :stats, :map
  end
end
```

### Shared Props Modules

For more complex shared props, create dedicated modules:

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

# Register in your controller
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  inertia_shared(MyAppWeb.InertiaShared.Auth)

  inertia_page :dashboard do
    prop :stats, :map
  end
end
```

With NbSerializer, you can use serializers in shared props:

```elixir
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps

  inertia_shared do
    prop :locale, :string
    prop :current_user, MyApp.UserSerializer  # Automatically serialized
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

## Rendering Patterns

### All-in-One Pattern (with validation)

```elixir
def index(conn, _params) do
  render_inertia(conn, :users_index,
    users: list_users(),
    total_count: count_users()
  )
end
```

### Pipe-Friendly Pattern (flexible, no validation)

```elixir
def index(conn, _params) do
  conn
  |> assign_prop(:users, list_users())
  |> assign_prop(:total_count, count_users())
  |> render_inertia(:users_index)
end
```

### With NbSerializer

```elixir
def index(conn, _params) do
  render_inertia_serialized(conn, :users_index,
    users: {UserSerializer, list_users()},
    total_count: count_users()
  )
end
```

## Prop Types

Supported primitive types:
- `:string`
- `:integer`
- `:float`
- `:boolean`
- `:map`
- `:list`

When NbSerializer is installed, you can also use serializer modules as types.

## Compile-Time Validation

In dev and test environments, NbInertia validates:
- All required props are provided
- No undeclared props are passed
- No collision between shared props and page props

Optional, lazy, and deferred props can be omitted:

```elixir
inertia_page :users_show do
  prop :user, :map
  prop :posts, :list, optional: true
end

# This is valid - posts can be omitted
render_inertia(conn, :users_show, user: user)
```

## Configuration

Configure NbInertia using the `:nb_inertia` namespace. All configuration is automatically forwarded to the underlying `:inertia` library on application startup.

```elixir
# config/config.exs
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,           # Required for SSR and versioning
  camelize_props: true,                  # Default: true, converts snake_case to camelCase
  history: [],                           # Default: []
  static_paths: ["/css", "/js"],         # Default: []
  default_version: "1",                  # Default: "1"
  ssr: false,                            # Default: false
  raise_on_ssr_failure: true             # Default: true
```

### Configuration Options

- **`:endpoint`** - Your Phoenix endpoint module (required for SSR and asset versioning)
- **`:camelize_props`** - Whether to automatically camelize Inertia props (default: `true`)
- **`:history`** - History configuration for preserving scroll positions (default: `[]`)
- **`:static_paths`** - List of static paths for asset versioning (default: `[]`)
- **`:default_version`** - Default asset version (default: `"1"`)
- **`:ssr`** - Enable Server-Side Rendering (default: `false`)
- **`:raise_on_ssr_failure`** - Raise on SSR failures (default: `true`)

**Important:** Always configure `:nb_inertia`, not `:inertia` directly. NbInertia automatically forwards the configuration to the underlying Inertia library on application startup

## Component Name Inference

NbInertia automatically converts page atoms to component names:

- `:users_index` → `"Users/Index"`
- `:users_show` → `"Users/Show"`
- `:users_new` → `"Users/New"`
- `:admin_dashboard` → `"Admin/Dashboard"`
- `:admin_users_index` → `"Admin/Users/Index"`
- `:dashboard` → `"Dashboard"`
- `:user_profile` → `"UserProfile"`

You can also override the component name:

```elixir
inertia_page :user_profile, component: "Profile/Show" do
  prop :user, :map
end
```

## Error Handling

With NbSerializer, validation errors from Ecto changesets are automatically formatted:

```elixir
def create(conn, params) do
  case MyApp.Accounts.create_user(params) do
    {:ok, user} ->
      conn
      |> put_flash(:info, "User created successfully")
      |> redirect(to: ~p"/users/#{user.id}")

    {:error, changeset} ->
      conn
      |> assign_serialized_errors(changeset)
      |> redirect(to: ~p"/users/new")
  end
end
```

## Documentation

For full documentation, see [HexDocs](https://hexdocs.pm/nb_inertia).

## License

MIT License. See [LICENSE](LICENSE) for details.

## Credits

Built by [Nordbeam](https://github.com/nordbeam) as part of the NbSerializer ecosystem.
