defmodule NbInertia.Modal.BaseRenderer do
  @moduledoc """
  Renders modal responses with base URL request dispatching.

  This module handles the complex flow of rendering modals in Inertia.js:

  1. **Base URL Request**: Makes an internal request to the base URL to fetch
     the base page props (the page that sits "behind" the modal)

  2. **Props Injection**: Injects modal-specific data into shared props so the
     frontend knows this is a modal response

  3. **URL Spoofing**: Returns the base URL in the response instead of the modal
     URL, so the browser shows the correct URL in the address bar

  4. **Header Management**: Adds custom headers to communicate modal configuration
     to the frontend

  ## Usage

  This module is typically used via the `render_inertia_modal/4` macro in the
  controller, but can also be used directly:

      modal = Modal.new("Users/Show", %{user: user})
              |> Modal.base_url("/users")
              |> Modal.size(:lg)

      NbInertia.Modal.BaseRenderer.render(conn, modal)

  ## Internal Request Flow

  The base URL request uses Phoenix.ConnTest.build_conn/0 internally to create
  a new conn for the internal request. This ensures proper middleware processing
  for the base page.

  ## Modal Props Injection

  The renderer injects the following data into `conn.assigns`:

  - `modal` - The modal component and props
  - `modal_config` - Configuration for modal appearance (size, position, etc.)
  """

  import Plug.Conn
  alias NbInertia.Modal

  require Logger

  @type render_error ::
          {:error, :no_base_url}
          | {:error, :base_request_failed, any()}
          | {:error, :invalid_response}

  @doc """
  Renders a modal response by fetching the base page and injecting modal data.

  ## Parameters

    - `conn` - The current Plug.Conn
    - `modal` - The Modal struct with component, props, base_url, and config

  ## Returns

  - `{:ok, conn}` - Successfully rendered modal response
  - `{:error, reason}` - Failed to render modal

  ## Example

      modal = Modal.new("Users/Show", %{user: user})
              |> Modal.base_url("/users")

      case BaseRenderer.render(conn, modal) do
        {:ok, conn} -> conn
        {:error, reason} ->
          Logger.error("Modal render failed: \#{inspect(reason)}")
          # Fallback to regular page
          render_inertia(conn, "Users/Show", %{user: user})
      end
  """
  @spec render(Plug.Conn.t(), Modal.t()) :: {:ok, Plug.Conn.t()} | render_error()
  def render(conn, %Modal{} = modal) do
    with {:ok, base_url} <- validate_base_url(modal),
         {:ok, base_conn} <- fetch_base_page(conn, base_url),
         {:ok, conn} <- inject_modal_data(conn, modal, base_conn) do
      conn =
        conn
        |> add_modal_headers(modal)
        |> spoof_url(base_url)

      {:ok, conn}
    end
  end

  @doc """
  Renders a modal response, raising on error.

  Same as `render/2` but raises an exception instead of returning an error tuple.

  ## Example

      modal = Modal.new("Users/Show", %{user: user})
              |> Modal.base_url("/users")

      conn = BaseRenderer.render!(conn, modal)
  """
  @spec render!(Plug.Conn.t(), Modal.t()) :: Plug.Conn.t()
  def render!(conn, %Modal{} = modal) do
    case render(conn, modal) do
      {:ok, conn} ->
        conn

      {:error, :no_base_url} ->
        raise ArgumentError, "Modal must have a base_url set"

      {:error, :base_request_failed, reason} ->
        raise RuntimeError,
              "Failed to fetch base page for modal: #{inspect(reason)}"

      {:error, :invalid_response} ->
        raise RuntimeError, "Base page request returned invalid response"
    end
  end

  # Private functions

  defp validate_base_url(%Modal{base_url: nil}), do: {:error, :no_base_url}
  defp validate_base_url(%Modal{base_url: url}) when is_binary(url), do: {:ok, url}

  defp fetch_base_page(conn, base_url) do
    # Create an internal request to the base URL to get the base page props
    # We'll use Plug.Test.conn/3 to create a test connection
    #
    # Important: We need to:
    # 1. Preserve session data from the original conn
    # 2. Preserve authentication/authorization state
    # 3. Mark it as an Inertia request
    # 4. Add special header to exclude modal-specific middleware

    try do
      base_conn =
        conn
        |> duplicate_conn_for_base_request(base_url)
        |> Phoenix.Controller.Pipeline.put_new_layout(false)
        |> put_private(:inertia_modal_base_request, true)

      # Call the Phoenix router to dispatch the request
      router = conn.private[:phoenix_router]

      if router do
        base_conn = router.call(base_conn, router.init([]))

        if base_conn.state == :sent do
          {:ok, base_conn}
        else
          {:error, :base_request_failed, "Request not sent"}
        end
      else
        {:error, :base_request_failed, "No Phoenix router found"}
      end
    rescue
      error ->
        {:error, :base_request_failed, error}
    end
  end

  defp duplicate_conn_for_base_request(original_conn, base_url) do
    # Parse the base URL to extract path and query string
    uri = URI.parse(base_url)
    path = uri.path || "/"
    query_string = uri.query || ""

    # Build a new conn with the base URL path
    # Preserve important data from the original conn
    %Plug.Conn{original_conn | path_info: split_path(path), query_string: query_string}
    |> Map.put(:request_path, path)
    |> Map.put(:method, "GET")
    |> put_req_header("x-inertia", "true")
    |> put_req_header("x-inertia-version", get_inertia_version(original_conn))
    |> put_req_header("x-inertia-modal-base-request", "true")
  end

  defp split_path(path) do
    path
    |> String.split("/", trim: true)
  end

  defp get_inertia_version(conn) do
    case get_req_header(conn, "x-inertia-version") do
      [version | _] -> version
      _ -> ""
    end
  end

  defp inject_modal_data(conn, modal, base_conn) do
    # Extract base page props from the base_conn response
    # The base_conn should have rendered an Inertia response
    case base_conn.private[:inertia_page] do
      %{props: base_props, component: base_component} ->
        # Inject modal data into conn assigns and private
        conn =
          conn
          |> assign(:modal, %{
            component: modal.component,
            props: modal.props
          })
          |> assign(:modal_config, modal.config)
          |> put_private(:modal_base_component, base_component)
          |> put_private(:modal_base_props, base_props)

        {:ok, conn}

      _ ->
        {:error, :invalid_response}
    end
  end

  defp add_modal_headers(conn, modal) do
    conn
    |> put_resp_header(Modal.modal_header(), "true")
    |> put_resp_header(Modal.modal_base_url_header(), modal.base_url)
    |> maybe_put_modal_config_header(modal)
  end

  defp maybe_put_modal_config_header(conn, %Modal{config: config}) when map_size(config) > 0 do
    # Encode config as JSON for the header
    config_json = Jason.encode!(config)
    put_resp_header(conn, Modal.modal_config_header(), config_json)
  end

  defp maybe_put_modal_config_header(conn, _modal), do: conn

  defp spoof_url(conn, base_url) do
    # Store the original URL for reference
    conn
    |> put_private(:inertia_modal_original_url, conn.request_path)
    |> put_private(:inertia_modal_spoofed_url, base_url)
    # Override the request_path for the inertia_assigns function
    |> Map.put(:request_path, base_url)
  end

  @doc """
  Checks if the current request is a base request for a modal.

  This is used by middleware to determine if certain processing should be
  skipped during the base page fetch.

  ## Example

      def call(conn, _opts) do
        if BaseRenderer.base_request?(conn) do
          # Skip modal-specific processing
          conn
        else
          # Normal processing
          process_modal_logic(conn)
        end
      end
  """
  @spec base_request?(Plug.Conn.t()) :: boolean()
  def base_request?(conn) do
    conn.private[:inertia_modal_base_request] == true ||
      get_req_header(conn, "x-inertia-modal-base-request") == ["true"]
  end

  @doc """
  Gets the original modal URL before URL spoofing.

  Returns `nil` if this is not a modal response or URL wasn't spoofed.

  ## Example

      iex> BaseRenderer.original_url(conn)
      "/users/123/edit"
  """
  @spec original_url(Plug.Conn.t()) :: String.t() | nil
  def original_url(conn) do
    conn.private[:inertia_modal_original_url]
  end

  @doc """
  Gets the spoofed base URL for a modal response.

  Returns `nil` if this is not a modal response.

  ## Example

      iex> BaseRenderer.spoofed_url(conn)
      "/users"
  """
  @spec spoofed_url(Plug.Conn.t()) :: String.t() | nil
  def spoofed_url(conn) do
    conn.private[:inertia_modal_spoofed_url]
  end
end
