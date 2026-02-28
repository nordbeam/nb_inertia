defmodule NbInertia.Modal.HttpClient do
  @moduledoc """
  HTTP client for fetching base pages using Req with :plug option.

  This module handles internal requests to fetch the base page content
  when a modal is accessed directly via URL (not via Inertia XHR).

  Uses `Req` with the `:plug` option to dispatch directly to the Phoenix
  endpoint without network I/O, which is both fast and production-ready.
  """

  import Plug.Conn

  require Logger

  @type fetch_result :: {:ok, map()} | {:error, term()}
  @type fetch_html_result :: {:ok, String.t(), map()} | {:error, term()}

  @doc """
  Fetches the base page and returns both the full HTML and parsed page data.

  This is used when we need to modify the HTML and return it with all assets
  (CSS, JS) intact, rather than building new HTML from scratch.

  ## Returns

    - `{:ok, html, page_data}` - The full HTML and parsed page data
    - `{:error, reason}` - Same error types as fetch_base_page/2
  """
  @spec fetch_base_page_html(Plug.Conn.t(), String.t()) :: fetch_html_result()
  def fetch_base_page_html(conn, base_url) do
    if Code.ensure_loaded?(Req) do
      do_fetch_base_page_html(conn, base_url)
    else
      {:error, :req_not_available}
    end
  end

  @doc """
  Fetches the base page as an Inertia JSON response.

  Used by XhrRenderer when the client already has the Inertia app loaded
  and is navigating via Inertia's router. We send the X-Inertia header to
  get the JSON response directly instead of HTML.

  ## Returns

    - `{:ok, page_data}` - The Inertia page data as a map
    - `{:error, reason}` - Same error types as fetch_base_page/2
  """
  @spec fetch_base_page_json(Plug.Conn.t(), String.t()) :: fetch_result()
  def fetch_base_page_json(conn, base_url) do
    if Code.ensure_loaded?(Req) do
      do_fetch_base_page_json(conn, base_url)
    else
      {:error, :req_not_available}
    end
  end

  defp do_fetch_base_page_html(conn, base_url) do
    endpoint = get_endpoint(conn)

    unless endpoint do
      {:error, {:fetch_failed, "No Phoenix endpoint found in conn.private"}}
    else
      headers = build_headers(conn)

      try do
        response =
          Req.new(url: base_url, plug: endpoint)
          |> Req.Request.put_headers(headers)
          |> Req.request!()

        extract_html_and_page_data(response)
      rescue
        e ->
          Logger.error("Failed to fetch base page HTML #{base_url}: #{inspect(e)}")
          {:error, {:fetch_failed, e}}
      end
    end
  end

  defp do_fetch_base_page_json(conn, base_url) do
    endpoint = get_endpoint(conn)

    unless endpoint do
      {:error, {:fetch_failed, "No Phoenix endpoint found in conn.private"}}
    else
      headers = build_inertia_headers(conn)

      try do
        response =
          Req.new(url: base_url, plug: endpoint)
          |> Req.Request.put_headers(headers)
          |> Req.request!()

        extract_json_page_data(response)
      rescue
        e ->
          Logger.error("Failed to fetch base page JSON #{base_url}: #{inspect(e)}")
          {:error, {:fetch_failed, e}}
      end
    end
  end

  defp get_endpoint(conn) do
    conn.private[:phoenix_endpoint]
  end

  defp build_headers(conn) do
    base_headers = [
      {"accept", "text/html"},
      {"x-inertia-modal-base-request", "true"}
    ]

    # Forward cookies for session/auth preservation
    cookie_headers =
      case get_req_header(conn, "cookie") do
        [cookies | _] -> [{"cookie", cookies}]
        [] -> []
      end

    # We do NOT set X-Inertia header - we want HTML response
    # The modal data will be injected after we get the base page

    base_headers ++ cookie_headers
  end

  defp build_inertia_headers(conn) do
    # Note: We use "text/html" for accept to pass Phoenix's browser pipeline,
    # but the X-Inertia header tells Inertia to return JSON instead of HTML.
    #
    # Important: Forward the X-Inertia-Version from the original request to
    # avoid 409 Conflict responses from Inertia version mismatch.
    version = get_inertia_version_from_request(conn)

    base_headers = [
      {"accept", "text/html, application/xhtml+xml"},
      {"x-inertia", "true"},
      {"x-inertia-version", version},
      {"x-inertia-modal-base-request", "true"}
    ]

    # Forward cookies for session/auth preservation
    cookie_headers =
      case get_req_header(conn, "cookie") do
        [cookies | _] -> [{"cookie", cookies}]
        [] -> []
      end

    base_headers ++ cookie_headers
  end

  defp get_inertia_version_from_request(conn) do
    # First, try to get version from the original request header
    case get_req_header(conn, "x-inertia-version") do
      [version | _] when version != "" ->
        version

      _ ->
        # Fall back to application config
        NbInertia.Config.version() || ""
    end
  end

  defp extract_json_page_data(%{status: status, body: body}) when status in [200, 201] do
    # Body may already be decoded by Req if content-type is application/json
    case body do
      %{} = page_data ->
        {:ok, page_data}

      body when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, page_data} -> {:ok, page_data}
          {:error, _} -> {:error, {:parse_failed, "Failed to parse JSON response"}}
        end
    end
  end

  defp extract_json_page_data(%{status: status}) do
    {:error, {:http_error, status}}
  end

  defp extract_html_and_page_data(%{status: status, body: body}) when status in [200, 201] do
    case extract_page_data_from_html(body) do
      {:ok, page_data} -> {:ok, body, page_data}
      {:error, reason} -> {:error, {:parse_failed, reason}}
    end
  end

  defp extract_html_and_page_data(%{status: status}) do
    {:error, {:http_error, status}}
  end

  @doc """
  Extracts Inertia page data from HTML response.

  The Inertia page data is embedded in the HTML as a `data-page` attribute
  on the root element, typically: `<div id="app" data-page='...'>`

  ## Parameters

    - `html` - The HTML string to parse

  ## Returns

    - `{:ok, page_data}` - The parsed page data as a map
    - `{:error, reason}` - Failed to find or parse the data-page attribute
  """
  @spec extract_page_data_from_html(String.t()) :: {:ok, map()} | {:error, String.t()}
  def extract_page_data_from_html(html) do
    # Try single quotes first (most common in Phoenix)
    case Regex.run(~r/data-page='([^']*)'/s, html) do
      [_, encoded_json] ->
        decode_page_data(encoded_json)

      nil ->
        # Try double quotes
        case Regex.run(~r/data-page="([^"]*)"/s, html) do
          [_, encoded_json] ->
            decode_page_data(encoded_json)

          nil ->
            {:error, "No data-page attribute found in HTML"}
        end
    end
  end

  defp decode_page_data(encoded_json) do
    decoded = decode_html_entities(encoded_json)

    case Jason.decode(decoded) do
      {:ok, page_data} -> {:ok, page_data}
      {:error, _} -> {:error, "Failed to parse page data JSON"}
    end
  end

  @doc """
  Decodes common HTML entities in a string.

  Used to decode the HTML-encoded JSON in the data-page attribute.
  """
  @spec decode_html_entities(String.t()) :: String.t()
  def decode_html_entities(str) do
    str
    |> String.replace("&quot;", "\"")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&#39;", "'")
    |> String.replace("&apos;", "'")
  end

  @doc """
  Encodes a string for safe embedding in an HTML attribute.

  Used when building the composed HTML response.
  """
  @spec encode_html_entities(String.t()) :: String.t()
  def encode_html_entities(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  @doc """
  Injects modified page data back into the original HTML.

  Replaces the existing `data-page` attribute value with the new page data,
  preserving all other HTML (CSS, JS, etc).

  ## Parameters

    - `html` - The original HTML string
    - `page_data` - The modified page data to inject

  ## Returns

    - `{:ok, modified_html}` - The HTML with updated data-page
    - `{:error, reason}` - Failed to find data-page attribute
  """
  @spec inject_page_data_into_html(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def inject_page_data_into_html(html, page_data) do
    encoded_json = page_data |> Jason.encode!() |> encode_html_entities()

    # Try single quotes first (most common in Phoenix/Inertia)
    case Regex.run(~r/data-page='[^']*'/s, html) do
      [_match] ->
        modified = Regex.replace(~r/data-page='[^']*'/s, html, "data-page='#{encoded_json}'")
        {:ok, modified}

      nil ->
        # Try double quotes
        case Regex.run(~r/data-page="[^"]*"/s, html) do
          [_match] ->
            # For double quotes, we need different escaping
            encoded_for_double_quotes =
              page_data
              |> Jason.encode!()
              |> String.replace("&", "&amp;")
              |> String.replace("\"", "&quot;")
              |> String.replace("<", "&lt;")
              |> String.replace(">", "&gt;")

            modified =
              Regex.replace(
                ~r/data-page="[^"]*"/s,
                html,
                "data-page=\"#{encoded_for_double_quotes}\""
              )

            {:ok, modified}

          nil ->
            {:error, "No data-page attribute found in HTML"}
        end
    end
  end
end
