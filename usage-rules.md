# NbInertia Usage Rules

## What It Does
NbInertia provides an advanced Inertia.js integration for Phoenix with declarative page DSL, type-safe props, shared props, and optional NbSerializer support. It adds compile-time validation and automatic component name inference on top of the base Inertia library.

## Installation

```elixir
# mix.exs
def deps do
  [
    {:nb_inertia, "~> 0.1"},
    {:nb_serializer, "~> 0.1", optional: true}  # Optional
  ]
end
```

## Configuration

```elixir
# config/config.exs
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,           # Required for SSR/versioning
  camelize_props: true,                  # Default: true (snake_case -> camelCase)
  static_paths: ["/css", "/js"],         # For asset versioning
  default_version: "1",                  # Asset version
  ssr: false,                            # Server-side rendering
  raise_on_ssr_failure: true             # Raise on SSR errors
```

**Important:** Configure `:nb_inertia`, not `:inertia`. NbInertia forwards config automatically.

## Basic Usage (Without NbSerializer)

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  inertia_page :users_index do
    prop :users, :list
    prop :total_count, :integer
  end

  def index(conn, _params) do
    render_inertia(conn, :users_index,
      users: list_users(),
      total_count: count_users()
    )
  end
end
```

## Component Name Inference

Page atoms automatically convert to component paths:
- `:users_index` → `"Users/Index"`
- `:users_show` → `"Users/Show"`
- `:admin_users_index` → `"Admin/Users/Index"`
- `:dashboard` → `"Dashboard"`
- `:user_profile` → `"UserProfile"`

Override manually: `inertia_page :users, component: "Custom/Component" do ... end`

## Prop Types

Primitive types: `:string`, `:integer`, `:float`, `:boolean`, `:map`, `:list`

With NbSerializer installed: Use serializer modules as types

## With NbSerializer (Optional)

```elixir
inertia_page :users_index do
  prop :users, MyApp.UserSerializer
  prop :total_count, :integer
end

def index(conn, _params) do
  render_inertia_serialized(conn, :users_index,
    users: {MyApp.UserSerializer, list_users()},
    total_count: count_users()
  )
end
```

### NbSerializer Functions
- `assign_serialized/5` - Assign single prop with serialization
- `assign_serialized_props/2` - Assign multiple serialized props
- `assign_serialized_errors/2` - Serialize Ecto changeset errors
- `render_inertia_serialized/3` - Render with serialized props

### Prop Options (with NbSerializer)
- `lazy: true` - Only load on partial reloads
- `defer: true` - Async load after initial render
- `merge: true` - Merge with existing (infinite scroll)
- `optional: true` - Excluded on first visit

## Shared Props

Define props shared across all pages:

```elixir
# Inline DSL
inertia_shared do
  prop :current_user, from: :assigns
  prop :flash, from: :assigns
end

# Or use a dedicated module
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps

  inertia_shared do
    prop :locale, :string
    prop :current_user, MyApp.UserSerializer
  end

  def build_props(conn, _opts) do
    %{
      locale: conn.assigns[:locale] || "en",
      current_user: conn.assigns[:current_user]
    }
  end
end

# Register in controller
inertia_shared(MyAppWeb.InertiaShared.Auth)
```

## Testing

```elixir
# test/support/conn_case.ex
import NbInertia.TestHelpers

# In tests
test "renders posts index", %{conn: conn} do
  conn = inertia_get(conn, ~p"/posts")

  assert_inertia_page(conn, "Posts/Index")
  assert_inertia_props(conn, [:posts, :total_count])
  assert_inertia_prop(conn, :total_count, 1)
  refute_inertia_prop(conn, :secret)
end
```

Test helpers: `inertia_get/2`, `inertia_post/3`, `assert_inertia_page/2`, `assert_inertia_props/2`, `assert_inertia_prop/3`, `refute_inertia_prop/2`
