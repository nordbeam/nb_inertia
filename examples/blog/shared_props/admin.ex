# Example: Scoped shared props for admin routes
#
# Features demonstrated:
#   - Scoped shared props (only applied in /admin scope)
#   - Additive with auth shared props (both are available in admin pages)
#
# Register in your admin router scope:
#   include_shared_props BlogWeb.InertiaShared.Admin

defmodule BlogWeb.InertiaShared.Admin do
  use NbInertia.SharedProps

  inertia_shared do
    prop(:pending_posts_count, :integer)
    prop(:admin_nav_items, list_of(shape(label: :string, path: :string)))
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
