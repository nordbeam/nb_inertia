# NbInertia Cookbook

Practical patterns and recipes for building Inertia.js applications with NbInertia.

## Table of Contents

- [Shared Props Patterns](#shared-props-patterns)
  - [Auto-Shared Props via web.ex](#auto-shared-props-via-webex)
  - [Conditional Shared Props](#conditional-shared-props)
  - [Organizing Shared Props Modules](#organizing-shared-props-modules)
  - [Deep Merging Nested Props](#deep-merging-nested-props)
- [Page Props Patterns](#page-props-patterns)
- [Testing Patterns](#testing-patterns)
- [Common Use Cases](#common-use-cases)

---

## Shared Props Patterns

### Auto-Shared Props via web.ex

**Problem:** You want to share props across ALL controllers without manually registering them in each one.

**Solution:** Use Phoenix's `web.ex` pattern to auto-register shared props modules.

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

  # ... other helpers
end
```

```elixir
# lib/my_app_web/inertia_shared/base.ex
defmodule MyAppWeb.InertiaShared.Base do
  use NbInertia.SharedProps

  @app_name Application.compile_env(:my_app, :app_name, "MyApp")
  @version Mix.Project.config()[:version]

  inertia_shared do
    prop :app_name, :string
    prop :version, :string
    prop :environment, :string
  end

  def build_props(_conn, _opts) do
    %{
      app_name: @app_name,
      version: @version,
      environment: to_string(Application.get_env(:my_app, :env, :prod))
    }
  end
end
```

**Benefits:**
- ✅ No need to manually register in every controller
- ✅ Consistent props across your entire app
- ✅ Easy to maintain in one place

---

### Conditional Shared Props

#### Pattern 1: Action-Specific Shared Props

**Problem:** You want to include admin data only on admin pages.

**Solution:** Use `:only` or `:except` options.

```elixir
defmodule MyAppWeb.Admin.DashboardController do
  use MyAppWeb, :controller

  # Only include admin data for index and show actions
  inertia_shared(MyAppWeb.InertiaShared.Admin, only: [:index, :show])

  # Exclude sensitive data from public-facing actions
  inertia_shared(MyAppWeb.InertiaShared.Internal, except: [:public_stats])

  # ... rest of controller
end
```

#### Pattern 2: Conditional Based on User Role

**Problem:** You want to include different shared props based on user permissions.

**Solution:** Use `:when` guard option.

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  # Only include admin props when user is admin
  inertia_shared(MyAppWeb.InertiaShared.Admin, when: :admin?)

  # Include feature flags for beta testers
  inertia_shared(MyAppWeb.InertiaShared.BetaFeatures, when: :beta_tester?)

  # Guard functions
  defp admin?(conn) do
    conn.assigns[:current_user]?.role == :admin
  end

  defp beta_tester?(conn) do
    user = conn.assigns[:current_user]
    user && user.beta_tester?
  end

  # ... rest of controller
end
```

#### Pattern 3: Multiple Conditions

**Problem:** You need to combine multiple conditions.

**Solution:** Combine `:only` and `:when` options.

```elixir
defmodule MyAppWeb.ReportsController do
  use MyAppWeb, :controller

  # Only on index, and only when feature is enabled
  inertia_shared(MyAppWeb.InertiaShared.Analytics,
    only: [:index],
    when: :analytics_enabled?
  )

  defp analytics_enabled?(conn) do
    Application.get_env(:my_app, :enable_analytics, false)
  end
end
```

---

### Organizing Shared Props Modules

#### Pattern 1: By Domain

```
lib/my_app_web/inertia_shared/
├── auth.ex          # Authentication/user data
├── features.ex      # Feature flags
├── notifications.ex # Notification counts
└── analytics.ex     # Analytics/tracking data
```

```elixir
# auth.ex
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps

  inertia_shared do
    prop :current_user, MyApp.UserSerializer
    prop :permissions, list: :string
  end

  def build_props(conn, _opts) do
    %{
      current_user: conn.assigns[:current_user],
      permissions: conn.assigns[:permissions] || []
    }
  end
end
```

#### Pattern 2: By Access Level

```
lib/my_app_web/inertia_shared/
├── public.ex        # Public data for all users
├── authenticated.ex # Data for logged-in users
├── admin.ex         # Data for admins only
└── super_admin.ex   # Data for super admins
```

#### Pattern 3: By Feature

```
lib/my_app_web/inertia_shared/
├── base.ex          # Core app data
├── billing.ex       # Billing/subscription data
├── team.ex          # Team/collaboration data
└── integrations.ex  # Third-party integrations
```

---

### Deep Merging Nested Props

#### Problem: Partial Updates to Nested Data

**Problem:** You want to override part of a nested shared prop without losing the rest.

**Solution:** Enable deep merge globally or per-action.

**Global Configuration:**

```elixir
# config/config.exs
config :nb_inertia,
  endpoint: MyAppWeb.Endpoint,
  deep_merge_shared_props: true
```

**Per-Action Override:**

```elixir
defmodule MyAppWeb.SettingsController do
  use MyAppWeb, :controller

  # Shared props provide defaults
  inertia_shared do
    prop :settings, from: :assigns
  end

  def index(conn, _params) do
    # Shared: %{settings: %{theme: "dark", notifications: true, language: "en"}}
    # Page:   %{settings: %{theme: "light"}}
    # With deep merge: %{settings: %{theme: "light", notifications: true, language: "en"}}

    render_inertia(conn, :settings_index,
      [settings: %{theme: "light"}],
      deep_merge: true
    )
  end
end
```

**Use Cases:**
- ✅ Feature flags with per-page overrides
- ✅ User preferences with page-specific defaults
- ✅ Configuration with partial updates

---

## Page Props Patterns

### Pattern 1: With Type Safety (NbSerializer)

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  inertia_page :users_index do
    prop :users, list: UserSerializer
    prop :total_count, :integer
    prop :filters, :map, optional: true
  end

  def index(conn, params) do
    users = Accounts.list_users(params)

    render_inertia(conn, :users_index,
      users: {UserSerializer, users},
      total_count: length(users),
      filters: params["filters"]
    )
  end
end
```

### Pattern 2: With TypeScript Types (NbTs)

```elixir
defmodule MyAppWeb.DashboardController do
  use MyAppWeb, :controller
  import NbTs.Sigil

  inertia_page :dashboard do
    prop :stats, type: ~TS"{ total: number; active: number; pending: number }"
    prop :recent_activity, list: ActivitySerializer
  end

  def index(conn, _params) do
    render_inertia(conn, :dashboard,
      stats: Dashboard.get_stats(),
      recent_activity: {ActivitySerializer, Dashboard.recent_activity()}
    )
  end
end
```

---

## Testing Patterns

### Pattern 1: Testing Shared Props

```elixir
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase

  describe "shared props" do
    test "includes app-wide shared props", %{conn: conn} do
      conn = inertia_get(conn, ~p"/dashboard")

      # Assert shared props are present
      assert_shared_props(conn, [:app_name, :version, :environment])
      assert_shared_prop(conn, :app_name, "MyApp")
    end

    test "includes auth shared props for authenticated users", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> assign(:current_user, user)
        |> inertia_get(~p"/dashboard")

      assert_shared_prop(conn, :current_user, %{
        id: user.id,
        name: user.name
      })
    end

    test "excludes admin props for regular users", %{conn: conn} do
      user = insert(:user, role: :user)

      conn =
        conn
        |> assign(:current_user, user)
        |> inertia_get(~p"/dashboard")

      refute_shared_prop(conn, :admin_settings)
      refute_shared_prop(conn, :admin_permissions)
    end
  end
end
```

### Pattern 2: Testing Conditional Shared Props

```elixir
defmodule MyAppWeb.AdminControllerTest do
  use MyAppWeb.ConnCase

  describe "admin shared props" do
    test "includes admin props for admin users", %{conn: conn} do
      admin = insert(:user, role: :admin)

      conn =
        conn
        |> assign(:current_user, admin)
        |> inertia_get(~p"/admin/dashboard")

      assert_shared_prop(conn, :admin_settings, %{...})
    end

    test "excludes admin props for regular users", %{conn: conn} do
      user = insert(:user, role: :user)

      conn =
        conn
        |> assign(:current_user, user)
        |> inertia_get(~p"/admin/dashboard")

      refute_shared_prop(conn, :admin_settings)
    end
  end
end
```

### Pattern 3: Testing Deep Merge

```elixir
defmodule MyAppWeb.SettingsControllerTest do
  use MyAppWeb.ConnCase

  test "deep merges settings props", %{conn: conn} do
    conn =
      conn
      |> assign(:settings, %{theme: "dark", notifications: true, language: "en"})
      |> inertia_get(~p"/settings")

    # With deep merge, page override should merge with shared settings
    assert_inertia_prop(conn, :settings, %{
      theme: "light",  # Overridden by page
      notifications: true,  # From shared props
      language: "en"  # From shared props
    })
  end
end
```

---

## Common Use Cases

### Use Case 1: Flash Messages

```elixir
# lib/my_app_web/inertia_shared/flash.ex
defmodule MyAppWeb.InertiaShared.Flash do
  use NbInertia.SharedProps

  inertia_shared do
    prop :flash, :map
  end

  def build_props(conn, _opts) do
    %{
      flash: Phoenix.Controller.get_flash(conn) |> Enum.into(%{})
    }
  end
end

# In web.ex
def controller do
  quote do
    use Phoenix.Controller
    use NbInertia.Controller

    inertia_shared(MyAppWeb.InertiaShared.Flash)
    # ...
  end
end

# In React component
import { usePage } from '@inertiajs/react'

export default function Layout({ children }) {
  const { flash } = usePage().props

  return (
    <div>
      {flash.info && <div className="alert-info">{flash.info}</div>}
      {flash.error && <div className="alert-error">{flash.error}</div>}
      {children}
    </div>
  )
}
```

### Use Case 2: Feature Flags

```elixir
# lib/my_app_web/inertia_shared/features.ex
defmodule MyAppWeb.InertiaShared.Features do
  use NbInertia.SharedProps

  inertia_shared do
    prop :features, :map
  end

  def build_props(conn, _opts) do
    user = conn.assigns[:current_user]

    %{
      features: %{
        new_dashboard: FeatureFlags.enabled?(:new_dashboard, user),
        advanced_search: FeatureFlags.enabled?(:advanced_search, user),
        dark_mode: FeatureFlags.enabled?(:dark_mode, user)
      }
    }
  end
end

# In React component
import { usePage } from '@inertiajs/react'

export default function Dashboard() {
  const { features } = usePage().props

  return (
    <div>
      {features.newDashboard ? (
        <NewDashboard />
      ) : (
        <LegacyDashboard />
      )}
    </div>
  )
}
```

### Use Case 3: Current User with Permissions

```elixir
# lib/my_app_web/inertia_shared/auth.ex
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps
  alias MyApp.Accounts.UserSerializer

  inertia_shared do
    prop :auth, :map
  end

  def build_props(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        %{auth: %{user: nil, permissions: []}}

      user ->
        %{
          auth: %{
            user: UserSerializer.serialize(user),
            permissions: Accounts.get_permissions(user)
          }
        }
    end
  end
end

# In React component
import { usePage } from '@inertiajs/react'

export default function Navbar() {
  const { auth } = usePage().props

  return (
    <nav>
      {auth.user ? (
        <>
          <span>Hello, {auth.user.name}</span>
          {auth.permissions.includes('admin') && (
            <Link href="/admin">Admin</Link>
          )}
        </>
      ) : (
        <Link href="/login">Login</Link>
      )}
    </nav>
  )
}
```

### Use Case 4: Notification Counts

```elixir
# lib/my_app_web/inertia_shared/notifications.ex
defmodule MyAppWeb.InertiaShared.Notifications do
  use NbInertia.SharedProps

  inertia_shared do
    prop :unread_count, :integer
    prop :unread_messages, :integer
  end

  def build_props(conn, _opts) do
    user = conn.assigns[:current_user]

    if user do
      %{
        unread_count: Notifications.count_unread(user),
        unread_messages: Messages.count_unread(user)
      }
    else
      %{
        unread_count: 0,
        unread_messages: 0
      }
    end
  end
end

# In React component
import { usePage } from '@inertiajs/react'

export default function NotificationBadge() {
  const { unreadCount } = usePage().props

  return (
    <div className="relative">
      <BellIcon />
      {unreadCount > 0 && (
        <span className="badge">{unreadCount}</span>
      )}
    </div>
  )
}
```

---

## Best Practices

### 1. Namespace Shared Props

**Good:**
```elixir
inertia_shared do
  prop :auth_user, UserSerializer
  prop :global_flash, :map
  prop :app_version, :string
end
```

**Bad:**
```elixir
inertia_shared do
  prop :user, UserSerializer  # Might collide with page prop
  prop :flash, :map           # Might collide with page prop
  prop :version, :string      # Too generic
end
```

### 2. Use SharedProps Modules Over Inline

**Good (maintainable, testable):**
```elixir
defmodule MyAppWeb.InertiaShared.Auth do
  use NbInertia.SharedProps
  # ...
end

inertia_shared(MyAppWeb.InertiaShared.Auth)
```

**Bad (hard to test, not reusable):**
```elixir
inertia_shared do
  prop :user, from: :assigns
  prop :permissions, from: :assigns
end
```

### 3. Keep Shared Props Minimal

Shared props are included in **every response**. Keep them small and only include what's truly needed across all pages.

**Good:**
```elixir
# Only essential data
%{
  current_user: %{id: 1, name: "Alice", role: "admin"},
  unread_count: 5
}
```

**Bad:**
```elixir
# Too much data that's not always needed
%{
  current_user: %{...},  # Full user object with 50 fields
  all_users: [...],      # Entire users table
  settings: %{...}       # All settings
}
```

### 4. Use Conditional Sharing for Optional Data

```elixir
# Only include admin data on admin pages
inertia_shared(MyAppWeb.InertiaShared.Admin, only: [:index, :show])

# Only include when user is authenticated
inertia_shared(MyAppWeb.InertiaShared.Auth, when: :authenticated?)
```

### 5. Test Shared Props

Always test that shared props are correctly applied:

```elixir
test "includes required shared props", %{conn: conn} do
  conn = inertia_get(conn, ~p"/any/page")

  assert_shared_props(conn, [:app_name, :version])
end
```

---

## Need More Help?

- **Documentation:** https://hexdocs.pm/nb_inertia
- **Issues:** https://github.com/nordbeam/nb_inertia/issues
- **Discussions:** https://github.com/nordbeam/nb_inertia/discussions
