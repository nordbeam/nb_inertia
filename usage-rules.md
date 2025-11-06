# NbInertia Usage Rules

## Overview

NbInertia provides advanced Inertia.js integration for Phoenix:
- **Declarative page DSL** - Define pages and props with compile-time validation
- **Component name inference** - Auto-convert `:users_index` to `"Users/Index"`
- **Shared props** - Define props shared across all pages
- **Type safety** - Compile-time validation in dev/test
- **SSR support** - Built-in server-side rendering with DenoRider
- **NbSerializer integration** - Optional high-performance serialization
- **Test helpers** - Comprehensive testing utilities

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

**Override if needed:**
```elixir
inertia_page :custom, component: "Custom/Component" do
  prop :data, :map
end
```

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

**Assertion helpers:**
```elixir
assert_inertia_page(conn, "Users/Index")
assert_inertia_props(conn, [:users, :total_count])
assert_inertia_prop(conn, :total_count, 10)
refute_inertia_prop(conn, :secret_data)
```

### Example Test
```elixir
test "renders users index", %{conn: conn} do
  user = insert(:user, name: "John")
  conn = inertia_get(conn, ~p"/users")

  assert_inertia_page(conn, "Users/Index")
  assert_inertia_props(conn, [:users, :total_count])
  assert_inertia_prop(conn, :total_count, 1)
end
```
