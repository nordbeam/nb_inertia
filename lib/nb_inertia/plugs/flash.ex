defmodule NbInertia.Plugs.Flash do
  @moduledoc """
  Plug for handling Inertia flash data persistence across redirects.

  This plug should be added to your browser pipeline after session handling:

      # lib/my_app_web/router.ex
      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug NbInertia.Plugs.Flash  # Add after session plugs
        plug Inertia.Plug
      end

  ## How it works

  1. On request start: Loads any flash data stored in the session from a previous redirect
  2. On response: If the response is a redirect (3xx), persists flash data to the session
  3. After send: Flash data is automatically included in the Inertia response and cleared

  ## Configuration

      # config/config.exs
      config :nb_inertia,
        # Include Phoenix flash in Inertia flash (default: true)
        include_phoenix_flash: true

  """

  @behaviour Plug

  import Plug.Conn
  alias NbInertia.Flash

  @redirect_statuses [301, 302, 303, 307, 308]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    conn
    |> Flash.load_from_session()
    |> register_before_send(&maybe_persist_flash/1)
  end

  # Persist flash to session on redirects so it survives the redirect
  defp maybe_persist_flash(conn) do
    if conn.status in @redirect_statuses do
      Flash.persist_to_session(conn)
    else
      conn
    end
  end
end
