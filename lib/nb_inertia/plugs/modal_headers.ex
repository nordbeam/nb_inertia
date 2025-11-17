defmodule NbInertia.Plugs.ModalHeaders do
  @moduledoc """
  Plug to extract and store modal-related headers from incoming requests.

  This plug extracts the following headers from the request:

  - `x-inertia-modal` - Boolean flag indicating if this request is for a modal
  - `x-inertia-modal-base-url` - The base URL for the modal (used for redirects)

  The extracted values are stored in `conn.private` under the following keys:

  - `:inertia_modal` - Boolean indicating if this is a modal request
  - `:inertia_modal_base_url` - String with the base URL (if provided)

  ## Usage

  Add this plug to your router pipeline before your controllers:

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug NbInertia.Plugs.ModalHeaders
      end

  Then in your controller, you can access the modal information:

      def show(conn, %{"id" => id}) do
        if is_modal_request?(conn) do
          # Render as modal
          render_inertia_modal(conn, "Users/Show", %{user: user})
        else
          # Render as full page
          render_inertia(conn, "Users/Show", %{user: user})
        end
      end

      defp is_modal_request?(conn) do
        conn.private[:inertia_modal] == true
      end
  """

  import Plug.Conn
  alias NbInertia.Modal

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    conn
    |> extract_modal_flag()
    |> extract_modal_base_url()
  end

  # Private functions

  defp extract_modal_flag(conn) do
    case get_req_header(conn, Modal.modal_header()) do
      [] ->
        put_private(conn, :inertia_modal, false)

      [value | _] ->
        # Convert header value to boolean
        # Accept "true", "1", "yes" as true
        is_modal = value in ["true", "1", "yes"]
        put_private(conn, :inertia_modal, is_modal)
    end
  end

  defp extract_modal_base_url(conn) do
    case get_req_header(conn, Modal.modal_base_url_header()) do
      [] ->
        put_private(conn, :inertia_modal_base_url, nil)

      [base_url | _] when is_binary(base_url) and base_url != "" ->
        put_private(conn, :inertia_modal_base_url, base_url)

      _ ->
        put_private(conn, :inertia_modal_base_url, nil)
    end
  end

  @doc """
  Returns true if the current request is a modal request.

  ## Parameters

    - `conn` - The Plug.Conn struct

  ## Example

      iex> NbInertia.Plugs.ModalHeaders.modal_request?(conn)
      true
  """
  @spec modal_request?(Plug.Conn.t()) :: boolean()
  def modal_request?(conn) do
    conn.private[:inertia_modal] == true
  end

  @doc """
  Returns the base URL for the current modal request, if any.

  ## Parameters

    - `conn` - The Plug.Conn struct

  ## Example

      iex> NbInertia.Plugs.ModalHeaders.modal_base_url(conn)
      "/users"

      iex> NbInertia.Plugs.ModalHeaders.modal_base_url(conn)
      nil
  """
  @spec modal_base_url(Plug.Conn.t()) :: String.t() | nil
  def modal_base_url(conn) do
    conn.private[:inertia_modal_base_url]
  end
end
