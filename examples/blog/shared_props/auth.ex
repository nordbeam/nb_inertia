# Example: Global shared props for authentication
#
# Features demonstrated:
#   - use NbInertia.SharedProps
#   - inertia_shared do ... end block with prop declarations
#   - Serializer-typed prop (nullable)
#   - build_props/2 callback
#
# Register in your router:
#   inertia_shared BlogWeb.InertiaShared.Auth

defmodule BlogWeb.InertiaShared.Auth do
  use NbInertia.SharedProps

  # Declare shared props with types. These are available on every page
  # in the router scope where this module is registered.
  # nb_ts generates TypeScript types from these declarations automatically.
  inertia_shared do
    prop :current_user, Blog.UserSerializer, nullable: true
    prop :flash, :map
  end

  # Called at request time. Return a map matching the declared props.
  @impl NbInertia.SharedProps.Behaviour
  def build_props(conn, _opts) do
    %{
      current_user: conn.assigns[:current_user],
      flash: conn.assigns[:flash] || %{}
    }
  end
end
