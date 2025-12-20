defmodule NbInertia.Flash do
  @moduledoc """
  Inertia flash data API for one-time data that doesn't persist in browser history.

  Unlike regular props, flash data isn't stored in history state, making it ideal
  for success messages, newly created IDs, or other temporary values.

  ## Usage

  Flash data in your controller actions:

      def create(conn, params) do
        {:ok, user} = Accounts.create_user(params)

        conn
        |> inertia_flash(:message, "User created successfully!")
        |> redirect(to: ~p"/users/\#{user.id}")
      end

      # Flash multiple values at once
      conn
      |> inertia_flash(message: "User created!", new_user_id: user.id)
      |> redirect(to: ~p"/users")

      # Chain with render_inertia
      conn
      |> inertia_flash(:highlight, project.id)
      |> render_inertia(:projects_index, projects: projects)

  ## Session Persistence

  Flash data is automatically persisted to the session on redirects and cleared
  after being sent to the client. This is handled by `NbInertia.Plugs.Flash`.

  ## Frontend Access

  On the frontend, flash data is available as a top-level field on the page object:

      // React
      import { useFlash } from '@nordbeam/nb-inertia/react';

      function Layout({ children }) {
        const { flash, has } = useFlash();

        return (
          <div>
            {has('message') && <Toast>{flash.message}</Toast>}
            {children}
          </div>
        );
      }

      // Vue
      import { useFlash } from '@nordbeam/nb-inertia/vue';

      const { flash, has, get } = useFlash();

  ## Configuration

      # config/config.exs
      config :nb_inertia,
        # Include Phoenix flash in Inertia flash (default: true)
        include_phoenix_flash: true,

        # Camelize flash keys (follows camelize_props setting by default)
        camelize_flash: nil
  """

  import Plug.Conn

  @session_key :nb_inertia_flash

  @type flash_key :: atom() | String.t()
  @type flash_value :: any()
  @type flash_data :: %{String.t() => flash_value()}

  @doc """
  Flash a single key-value pair to the client.

  The value will be available on the frontend via `page.flash` and is cleared
  after being sent.

  ## Examples

      conn
      |> inertia_flash(:message, "User created successfully!")
      |> redirect(to: ~p"/users")

      conn
      |> inertia_flash(:new_user_id, user.id)
      |> redirect(to: ~p"/users/\#{user.id}")

  """
  @spec inertia_flash(Plug.Conn.t(), flash_key(), flash_value()) :: Plug.Conn.t()
  def inertia_flash(conn, key, value) when is_atom(key) or is_binary(key) do
    current = get_inertia_flash(conn)
    put_inertia_flash(conn, Map.put(current, to_string(key), value))
  end

  @doc """
  Flash multiple key-value pairs to the client.

  Accepts a map or keyword list. All keys are converted to strings.

  ## Examples

      conn
      |> inertia_flash(message: "User created!", new_user_id: user.id)
      |> redirect(to: ~p"/users")

      conn
      |> inertia_flash(%{toast: %{type: "success", message: "Saved!"}})
      |> redirect(to: ~p"/dashboard")

  """
  @spec inertia_flash(Plug.Conn.t(), map() | Keyword.t()) :: Plug.Conn.t()
  def inertia_flash(conn, data) when is_map(data) do
    current = get_inertia_flash(conn)
    merged = Map.merge(current, stringify_keys(data))
    put_inertia_flash(conn, merged)
  end

  def inertia_flash(conn, data) when is_list(data) do
    inertia_flash(conn, Enum.into(data, %{}))
  end

  @doc """
  Get current Inertia flash data from the connection.

  Returns the flash data map that will be sent to the client.

  ## Examples

      flash = get_inertia_flash(conn)
      # => %{"message" => "Hello!"}

  """
  @spec get_inertia_flash(Plug.Conn.t()) :: flash_data()
  def get_inertia_flash(conn) do
    conn.private[:nb_inertia_flash] || %{}
  end

  @doc """
  Put flash data into the connection's private storage.

  This is a low-level function. Prefer using `inertia_flash/2,3`.
  """
  @spec put_inertia_flash(Plug.Conn.t(), flash_data()) :: Plug.Conn.t()
  def put_inertia_flash(conn, flash) when is_map(flash) do
    put_private(conn, :nb_inertia_flash, flash)
  end

  @doc """
  Persist flash data to the session.

  Called automatically by `NbInertia.Plugs.Flash` before redirects.
  Flash data is stored in the session and retrieved on the next request.
  """
  @spec persist_to_session(Plug.Conn.t()) :: Plug.Conn.t()
  def persist_to_session(conn) do
    flash = get_inertia_flash(conn)

    if flash != %{} do
      put_session(conn, @session_key, flash)
    else
      conn
    end
  end

  @doc """
  Load flash data from the session.

  Called automatically by `NbInertia.Plugs.Flash` at the start of requests.
  The flash data is removed from the session after being loaded.
  """
  @spec load_from_session(Plug.Conn.t()) :: Plug.Conn.t()
  def load_from_session(conn) do
    case get_session(conn, @session_key) do
      nil ->
        conn

      flash when is_map(flash) ->
        conn
        |> delete_session(@session_key)
        |> put_inertia_flash(flash)

      _ ->
        # Invalid flash data, just delete it
        delete_session(conn, @session_key)
    end
  end

  @doc """
  Clear flash data from the connection.

  Called automatically after flash data is sent to the client.
  """
  @spec clear(Plug.Conn.t()) :: Plug.Conn.t()
  def clear(conn) do
    put_private(conn, :nb_inertia_flash, %{})
  end

  @doc """
  Merge Inertia flash with Phoenix flash for the response.

  This function is called when building the Inertia response to combine
  both flash sources into a single flash object.

  ## Options

    * `:include_phoenix_flash` - Include Phoenix flash data (default: from config or true)
    * `:camelize` - Camelize flash keys (default: from config)

  """
  @spec get_flash_for_response(Plug.Conn.t(), keyword()) :: flash_data()
  def get_flash_for_response(conn, opts \\ []) do
    inertia_flash = get_inertia_flash(conn)

    include_phoenix =
      Keyword.get(
        opts,
        :include_phoenix_flash,
        Application.get_env(:nb_inertia, :include_phoenix_flash, true)
      )

    camelize =
      Keyword.get(
        opts,
        :camelize,
        Application.get_env(:nb_inertia, :camelize_flash, nil)
      )

    # Get camelize setting from props if not explicitly set for flash
    camelize =
      if is_nil(camelize), do: conn.private[:inertia_camelize_props] || false, else: camelize

    # Merge Phoenix flash if configured
    flash =
      if include_phoenix do
        phoenix_flash = conn.assigns[:flash] || %{}
        phoenix_flash_stringified = stringify_keys(phoenix_flash)
        Map.merge(phoenix_flash_stringified, inertia_flash)
      else
        inertia_flash
      end

    # Camelize keys if configured
    if camelize do
      camelize_keys(flash)
    else
      flash
    end
  end

  @doc """
  Check if there is any flash data to send.
  """
  @spec has_flash?(Plug.Conn.t()) :: boolean()
  def has_flash?(conn) do
    get_inertia_flash(conn) != %{}
  end

  # Private helpers

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp camelize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      camelized = k |> to_string() |> Phoenix.Naming.camelize(:lower)
      {camelized, v}
    end)
  end
end
