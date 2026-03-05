defmodule NbInertia.Plugs.SharedProps do
  @moduledoc """
  Plug that registers a shared props module on the connection.

  Used by `NbInertia.Router.inertia_shared/1` to accumulate shared props
  modules that will be applied by `NbInertia.PageController` before rendering.

  ## Usage

  Typically used via the `inertia_shared` macro in the router:

      import NbInertia.Router

      scope "/admin" do
        inertia_shared MyAppWeb.InertiaShared.Admin
        inertia_resource "/users", UsersPage
      end

  Can also be used directly as a plug:

      plug NbInertia.Plugs.SharedProps, module: MyAppWeb.InertiaShared.Admin
  """

  @behaviour Plug

  @impl Plug
  def init(opts) do
    module = Keyword.fetch!(opts, :module)

    unless Code.ensure_loaded?(module) do
      raise ArgumentError,
            "shared props module #{inspect(module)} could not be loaded"
    end

    module
  end

  @impl Plug
  def call(conn, module) do
    existing = conn.private[:nb_inertia_shared_modules] || []
    Plug.Conn.put_private(conn, :nb_inertia_shared_modules, existing ++ [module])
  end
end
