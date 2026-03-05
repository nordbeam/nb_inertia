# Blog/CMS Example for NbInertia.Page

Reference implementation of a Blog/CMS using `NbInertia.Page` modules. Demonstrates every major feature of the Page module system in a realistic domain.

**This is reference code, not a runnable app.** Copy the files into your Phoenix project and adjust module names. Context modules (`Blog.Posts`, `Blog.Accounts`, etc.) are stubs — replace with your actual data layer.

## Prerequisites

- `nb_inertia` installed (`mix nb_inertia.install --pages`)
- `nb_serializer` (optional, for serializer-typed props)
- `nb_ts` (optional, for TypeScript type generation)

## Quick Start

1. Copy `inertia/` to `lib/my_app_web/inertia/`
2. Copy `shared_props/` to `lib/my_app_web/shared_props/`
3. Copy serializer declarations to your serializer modules
4. Replace `BlogWeb` with your app's web module name
5. Add routes from `router.ex` to your router

## Directory Layout

```
examples/blog/
├── README.md                              # This file
├── router.ex                              # Router macros (inertia, inertia_resource, inertia_shared)
├── shared_props/
│   ├── auth.ex                            # Global shared props (current_user, flash)
│   └── admin.ex                           # Scoped shared props (admin-only)
├── serializers/
│   ├── user_serializer.ex                 # User serialization
│   ├── post_serializer.ex                 # Post serialization (nested author)
│   └── comment_serializer.ex              # Comment serialization
└── inertia/
    ├── home_page/
    │   └── index.ex                       # Landing page — basic mount + ~TSX
    ├── posts_page/
    │   ├── index.ex                       # Post listing — defer, default, standalone
    │   ├── show.ex                        # Post detail — channels, delete action
    │   ├── new.ex                         # Create post — form_inputs, precognition
    │   └── edit.ex                        # Edit post — conn pipeline, inertia_flash
    ├── comments_page/
    │   └── create.ex                      # Add comment — modal
    └── admin/
        └── dashboard_page/
            └── index.ex                   # Dashboard — history controls, from:, shared
```

## Feature Guide

### Basic Page (mount/2 + props)

**See:** `inertia/home_page/index.ex`

The simplest pattern. Declare props at the module level, return a map from `mount/2`:

```elixir
use NbInertia.Page

prop :greeting, :string

def mount(_conn, _params) do
  %{greeting: "Hello!"}
end
```

Component name is derived from the module: `BlogWeb.HomePage.Index` becomes `"Home/Index"`.

### ~TSX Sigil (Colocated Frontend)

**See:** `inertia/home_page/index.ex`, `inertia/posts_page/show.ex`

Embed the React component directly in the Elixir module. The extractor writes it to `.nb_inertia/pages/<Component>.tsx` with a generated `Props` interface:

```elixir
def render do
  ~TSX"""
  export default function MyPage({ greeting }: Props) {
    return <h1>{greeting}</h1>
  }
  """
end
```

Omit `render/0` for standalone `.tsx` files (see `posts_page/index.ex`).

### Form Inputs + Precognition

**See:** `inertia/posts_page/new.ex`

Declare form fields for TypeScript type generation. Use `precognition` for real-time server-side validation:

```elixir
form_inputs :post_form do
  field :title, :string
  field :body, :string
end

def action(conn, %{"post" => params}, :create) do
  changeset = Posts.change_post(%Post{}, params)

  precognition conn, changeset do
    # Only runs for real submissions (not validation requests)
    case Posts.create(params) do
      {:ok, post} -> redirect(conn, to: "/posts/#{post.id}")
      {:error, changeset} -> {:error, changeset}
    end
  end
end
```

### Action Callbacks (Mutations)

**See:** `inertia/posts_page/new.ex` (`:create`), `inertia/posts_page/edit.ex` (`:update`), `inertia/posts_page/show.ex` (`:delete`)

`action/3` handles POST/PATCH/PUT/DELETE with verb atoms:

```elixir
def action(conn, params, :create) do ... end
def action(conn, params, :update) do ... end
def action(conn, params, :delete) do ... end
```

Return a redirect conn on success, or `{:error, changeset}` for validation failures.

### Conn Pipeline Mount

**See:** `inertia/posts_page/edit.ex`

When you need to modify the conn alongside props, return a conn from `mount/2`:

```elixir
def mount(conn, %{"id" => id}) do
  conn
  |> props(%{post: Posts.get!(id)})
end
```

### Modals

**See:** `inertia/comments_page/create.ex`

Configure a page to render as a modal overlay:

```elixir
modal base_url: &"/posts/#{&1["post_id"]}",
      size: :md,
      position: :center
```

The `base_url` function receives `conn.params` and determines what page shows "behind" the modal.

### Real-Time Channels

**See:** `inertia/posts_page/show.ex`

Declare channel bindings with event-to-prop strategies:

```elixir
channel "post:{post.id}" do
  on "comment_created", prop: :comments, strategy: :append
  on "comment_deleted", prop: :comments, strategy: :remove, key: :id
  on "typing",          prop: :typing_user, strategy: :replace
end
```

Strategies: `:append`, `:prepend`, `:remove`, `:update`, `:upsert`, `:replace`, `:reload`.

### Shared Props

**See:** `shared_props/auth.ex`, `shared_props/admin.ex`, `router.ex`

Define reusable shared props as modules, register them in the router:

```elixir
# In the router
inertia_shared BlogWeb.InertiaShared.Auth

# Page-level (additive)
shared do
  prop :admin_permissions, :list
end
```

### History Controls

**See:** `inertia/admin/dashboard_page/index.ex`

Protect sensitive pages from browser history inspection:

```elixir
use NbInertia.Page,
  encrypt_history: true,
  clear_history: true
```

### Prop Options

**See:** `inertia/posts_page/index.ex` (`defer:`, `default:`), `inertia/posts_page/show.ex` (`nullable:`), `inertia/admin/dashboard_page/index.ex` (`from:`)

```elixir
prop :data, :map, defer: true           # Loaded after initial render
prop :filter, :string, default: "all"   # Fallback value
prop :user, :map, nullable: true        # Can be nil
prop :tz, :string, from: :user_timezone # Auto-pull from conn.assigns
```

### Router Macros

**See:** `router.ex`

```elixir
import NbInertia.Router

inertia "/", HomePage.Index                              # Single route
inertia_resource "/posts", PostsPage                     # Full CRUD
inertia_resource "/dashboard", DashboardPage, only: [:index]  # Filtered
inertia_shared BlogWeb.InertiaShared.Auth                # Scope-level shared
```

## Extracted Output

When using `~TSX` sigils, the extractor generates `.tsx` files in `.nb_inertia/pages/`. For example, `BlogWeb.PostsPage.Show` produces:

```
.nb_inertia/pages/Posts/Show.tsx
```

The generated file includes a `Props` interface derived from your prop declarations, type imports from serializers, and the component code from `render/0`.

## Feature Index

| I want to learn about... | Look at... |
|---|---|
| Basic page setup | `inertia/home_page/index.ex` |
| ~TSX sigil | `inertia/home_page/index.ex` |
| Standalone (no ~TSX) | `inertia/posts_page/index.ex` |
| Form inputs | `inertia/posts_page/new.ex` |
| Precognition (live validation) | `inertia/posts_page/new.ex` |
| Create action | `inertia/posts_page/new.ex` |
| Update action | `inertia/posts_page/edit.ex` |
| Delete action | `inertia/posts_page/show.ex` |
| Conn pipeline mount | `inertia/posts_page/edit.ex` |
| Flash data | `inertia/posts_page/edit.ex` |
| Deferred props | `inertia/posts_page/index.ex` |
| Default prop values | `inertia/posts_page/index.ex` |
| Nullable props | `inertia/posts_page/show.ex` |
| Props from assigns | `inertia/admin/dashboard_page/index.ex` |
| Real-time channels | `inertia/posts_page/show.ex` |
| Modals | `inertia/comments_page/create.ex` |
| History controls | `inertia/admin/dashboard_page/index.ex` |
| Shared props (module) | `shared_props/auth.ex` |
| Shared props (scoped) | `shared_props/admin.ex`, `router.ex` |
| Shared props (page-level) | `inertia/admin/dashboard_page/index.ex` |
| Router macros | `router.ex` |
| Serializer integration | `serializers/*.ex` |
