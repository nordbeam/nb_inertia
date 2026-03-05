# Example: Scoped shared props for admin routes
#
# Features demonstrated:
#   - Scoped shared props (only applied in /admin scope)
#   - Additive with auth shared props (both are available in admin pages)
#
# Register in your admin router scope:
#   inertia_shared BlogWeb.InertiaShared.Admin

defmodule BlogWeb.InertiaShared.Admin do
  use NbInertia.SharedProps

  inertia_shared do
    prop :pending_posts_count, :integer
    prop :admin_nav_items, :list
  end

  @impl NbInertia.SharedProps.Behaviour
  def build_props(_conn, _opts) do
    %{
      pending_posts_count: Blog.Posts.count_pending(),
      admin_nav_items: [
        %{label: "Dashboard", path: "/admin/dashboard"},
        %{label: "Posts", path: "/admin/posts"},
        %{label: "Users", path: "/admin/users"}
      ]
    }
  end
end
