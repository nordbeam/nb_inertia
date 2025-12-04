defmodule NbInertia.Modal.Renderer do
  @moduledoc """
  Renders modal responses for both XHR and direct URL access.

  This module determines whether the request is an Inertia XHR request or a direct
  URL access, and renders the appropriate response.

  ## Two Code Paths

  1. **XHR Request** (X-Inertia header present): The frontend already has
     the backdrop loaded. Fetches the base page as JSON, injects modal data,
     and returns composed JSON.

  2. **Direct URL Access** (no X-Inertia header): Fetches the base page HTML,
     injects modal data into the page props, and returns composed HTML.

  ## Response Structure (XHR)

  Returns an Inertia JSON response with the BASE page component and
  `_nb_modal` prop containing the modal data:

      {
        "component": "Users/Index",       <-- Base page component (backdrop)
        "props": {
          "users": [...],                 <-- Base page props
          "_nb_modal": {                  <-- Modal data
            "component": "Users/Create",
            "props": {"organizations": [...]},
            "url": "/users/create",
            "baseUrl": "/users",
            "config": {"size": "lg"}
          }
        },
        "url": "/users/create",           <-- Modal URL (for browser address bar)
        "version": "..."
      }

  ## Usage

  This module is typically used via the `render_inertia_modal/4` macro in the
  controller, but can also be used directly:

      modal = Modal.new("Users/Show", %{user: user})
              |> Modal.base_url("/users")
              |> Modal.size(:lg)

      case NbInertia.Modal.Renderer.render(conn, modal, props) do
        {:ok, conn} -> conn
        {:error, reason} -> handle_error(reason)
      end

  ## Error Handling

  - `:no_base_url` - Modal must have a base_url set
  - `:req_not_available` - Requires the Req library for base page fetching
  - Other errors from base page fetching
  """

  import Plug.Conn

  alias NbInertia.Modal
  alias NbInertia.Modal.HttpClient

  require Logger

  @type render_error ::
          {:error, :no_base_url}
          | {:error, :req_not_available}
          | {:error, term()}

  @doc """
  Renders a modal response.

  Automatically determines the correct rendering strategy based on
  whether the request is an Inertia XHR request.

  ## Parameters

    - `conn` - The current Plug.Conn
    - `modal` - The Modal struct with component, base_url, and config
    - `props` - The serialized props for the modal component

  ## Returns

    - `{:ok, conn}` - Success with the response sent
    - `{:error, :no_base_url}` - Modal must have a base_url set
    - `{:error, :req_not_available}` - Requires Req library
    - `{:error, term()}` - Other errors
  """
  @spec render(Plug.Conn.t(), Modal.t(), map()) :: {:ok, Plug.Conn.t()} | render_error()
  def render(conn, %Modal{} = modal, props \\ %{}) do
    with :ok <- validate_base_url(modal) do
      if inertia_xhr_request?(conn) do
        render_xhr(conn, modal, props)
      else
        render_direct(conn, modal, props)
      end
    end
  end

  @doc """
  Renders a modal response, raising on error.

  Same as `render/3` but raises an exception instead of returning an error tuple.

  ## Example

      modal = Modal.new("Users/Show", %{user: user})
              |> Modal.base_url("/users")

      conn = Renderer.render!(conn, modal, props)
  """
  @spec render!(Plug.Conn.t(), Modal.t(), map()) :: Plug.Conn.t()
  def render!(conn, %Modal{} = modal, props \\ %{}) do
    case render(conn, modal, props) do
      {:ok, conn} ->
        conn

      {:error, :no_base_url} ->
        raise ArgumentError, "Modal must have a base_url set"

      {:error, :req_not_available} ->
        raise RuntimeError, """
        Modal rendering requires the Req library for internal dispatch.

        Add to your mix.exs:
            {:req, "~> 0.5"}

        Or ensure modal URLs are only accessed via Inertia XHR requests
        (client-side navigation with ModalLink component).
        """

      {:error, {:http_error, status}} ->
        raise RuntimeError, "Failed to fetch base page: HTTP #{status}"

      {:error, {:parse_failed, reason}} ->
        raise RuntimeError, "Failed to parse base page response: #{reason}"

      {:error, {:fetch_failed, exception}} ->
        raise RuntimeError, "Failed to fetch base page: #{inspect(exception)}"

      {:error, {:inject_failed, reason}} ->
        raise RuntimeError, "Failed to inject modal data into HTML: #{inspect(reason)}"

      {:error, reason} ->
        raise RuntimeError, "Failed to render modal: #{inspect(reason)}"
    end
  end

  @doc """
  Checks if the current request is a base request for a modal.

  This is used by middleware to determine if certain processing should be
  skipped during the base page fetch.

  ## Example

      def call(conn, _opts) do
        if Renderer.base_request?(conn) do
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
    get_req_header(conn, "x-inertia-modal-base-request") == ["true"]
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # XHR Rendering - Returns JSON response
  # ─────────────────────────────────────────────────────────────────────────────

  defp render_xhr(conn, %Modal{} = modal, props) do
    modal_data = build_modal_data(conn, modal, props)

    case HttpClient.fetch_base_page_json(conn, modal.base_url) do
      {:ok, base_page_data} ->
        composed_page = inject_modal_into_page(base_page_data, modal_data, conn)
        {:ok, send_json_response(conn, composed_page, modal)}

      {:error, :req_not_available} = error ->
        Logger.error("""
        Modal XHR requests require the Req library for internal dispatch.
        Add {:req, "~> 0.5"} to your mix.exs dependencies.
        """)

        error

      {:error, reason} = error ->
        Logger.error("Failed to fetch base page #{modal.base_url}: #{inspect(reason)}")
        error
    end
  end

  defp send_json_response(conn, page_data, %Modal{} = modal) do
    conn
    |> put_status(200)
    |> add_modal_headers(modal)
    |> put_resp_content_type("application/json")
    |> put_resp_header("x-inertia", "true")
    |> put_resp_header("vary", "X-Inertia")
    |> send_resp(200, Jason.encode!(page_data))
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Direct URL Rendering - Returns HTML response
  # ─────────────────────────────────────────────────────────────────────────────

  defp render_direct(conn, %Modal{} = modal, props) do
    modal_data = build_modal_data(conn, modal, props)

    case HttpClient.fetch_base_page_html(conn, modal.base_url) do
      {:ok, base_html, base_page_data} ->
        composed_page = inject_modal_into_page(base_page_data, modal_data, conn)

        case HttpClient.inject_page_data_into_html(base_html, composed_page) do
          {:ok, modified_html} ->
            {:ok, send_html_response(conn, modified_html, modal)}

          {:error, reason} ->
            Logger.error("Failed to inject modal data into HTML: #{inspect(reason)}")
            {:error, {:inject_failed, reason}}
        end

      {:error, :req_not_available} = error ->
        Logger.error("""
        Direct modal URL access requires the Req library.
        Add {:req, "~> 0.5"} to your mix.exs dependencies.
        """)

        error

      {:error, reason} = error ->
        Logger.error("Failed to fetch base page #{modal.base_url}: #{inspect(reason)}")
        error
    end
  end

  defp send_html_response(conn, html, %Modal{} = modal) do
    conn
    |> put_status(200)
    |> add_modal_headers(modal)
    |> put_resp_content_type("text/html; charset=utf-8")
    |> send_resp(200, html)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Shared Helpers
  # ─────────────────────────────────────────────────────────────────────────────

  defp validate_base_url(%Modal{base_url: nil}), do: {:error, :no_base_url}
  defp validate_base_url(%Modal{base_url: url}) when is_binary(url), do: :ok

  defp inertia_xhr_request?(conn) do
    get_req_header(conn, "x-inertia") == ["true"]
  end

  defp build_modal_data(conn, %Modal{} = modal, props) do
    %{
      component: modal.component,
      props: props,
      url: conn.request_path,
      baseUrl: modal.base_url,
      config: modal.config
    }
  end

  defp inject_modal_into_page(base_page_data, modal_data, conn) do
    # Get existing props from base page (could be string keys from JSON)
    base_props = base_page_data["props"] || %{}

    # Inject _nb_modal into base page's props
    updated_props = Map.put(base_props, "_nb_modal", modal_data)

    # Update URL to modal URL (for browser address bar)
    # Keep the base page's component so the backdrop renders correctly
    base_page_data
    |> Map.put("props", updated_props)
    |> Map.put("url", conn.request_path)
  end

  defp add_modal_headers(conn, %Modal{} = modal) do
    conn
    |> put_resp_header(Modal.modal_header(), "true")
    |> put_resp_header(Modal.modal_base_url_header(), modal.base_url || "/")
    |> maybe_put_config_header(modal)
  end

  defp maybe_put_config_header(conn, %Modal{config: config}) when map_size(config) > 0 do
    put_resp_header(conn, Modal.modal_config_header(), Jason.encode!(config))
  end

  defp maybe_put_config_header(conn, _modal), do: conn
end
