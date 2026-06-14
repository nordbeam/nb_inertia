defmodule NbInertia.Modal.HttpClient do
  @moduledoc """
  Internal HTTP client for fetching modal base pages through a Phoenix endpoint.

  This module handles internal requests to fetch the base page content
  when a modal is accessed directly via URL (not via Inertia XHR).

  It dispatches directly to the Phoenix endpoint plug without network I/O.
  Cookies and authorization headers from the modal request are forwarded so
  the base page sees the same session/auth context as a normal browser
  navigation.
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
    with {:ok, response} <- dispatch_base_page(conn, base_url, build_headers(conn)) do
      extract_html_and_page_data(response)
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
    with {:ok, response} <- dispatch_base_page(conn, base_url, build_inertia_headers(conn)) do
      extract_json_page_data(response)
    end
  end

  defp dispatch_base_page(conn, base_url, headers) do
    with {:ok, endpoint} <- get_endpoint(conn),
         {:ok, request_url} <- build_request_url(conn, base_url) do
      do_dispatch_base_page(conn, endpoint, request_url, headers)
    end
  end

  defp get_endpoint(conn) do
    endpoint = conn.private[:phoenix_endpoint] || NbInertia.Config.endpoint()

    cond do
      is_atom(endpoint) and function_exported?(endpoint, :call, 2) ->
        {:ok, endpoint}

      is_atom(endpoint) ->
        {:error,
         {:fetch_failed,
          "Modal base-page composition requires #{inspect(endpoint)} to be a Plug endpoint with call/2"}}

      true ->
        {:error,
         {:fetch_failed,
          "Modal base-page composition requires a Phoenix endpoint. Route modal requests through your endpoint or configure :endpoint for :nb_inertia."}}
    end
  end

  defp build_request_url(conn, base_url) when is_binary(base_url) do
    uri = URI.parse(base_url)

    if uri.scheme && uri.host do
      {:ok, base_url}
    else
      scheme = conn.scheme || :http
      path = normalize_path(uri.path)

      url =
        %URI{
          scheme: Atom.to_string(scheme),
          host: conn.host || "localhost",
          port: normalize_port(scheme, conn.port),
          path: path,
          query: uri.query
        }
        |> URI.to_string()

      {:ok, url}
    end
  rescue
    e -> {:error, {:fetch_failed, e}}
  end

  defp build_request_url(_conn, base_url) do
    {:error, {:fetch_failed, "Modal base_url must be a string, got: #{inspect(base_url)}"}}
  end

  defp normalize_path(nil), do: "/"
  defp normalize_path(""), do: "/"

  defp normalize_path(path) do
    if String.starts_with?(path, "/"), do: path, else: "/" <> path
  end

  defp normalize_port(:http, port) when port in [nil, 80], do: nil
  defp normalize_port(:https, port) when port in [nil, 443], do: nil
  defp normalize_port(_scheme, port), do: port

  defp do_dispatch_base_page(conn, endpoint, request_url, headers) do
    request_conn =
      :get
      |> Plug.Test.conn(request_url)
      |> Map.put(:remote_ip, conn.remote_ip)
      |> put_private(:phoenix_endpoint, endpoint)
      |> put_headers(headers)

    try do
      response_conn = endpoint.call(request_conn, endpoint_opts(endpoint))

      {:ok,
       %{
         status: response_conn.status,
         body: response_conn.resp_body || "",
         headers: response_conn.resp_headers
       }}
    rescue
      e ->
        Logger.error("Failed to fetch modal base page #{request_url}: #{inspect(e)}")
        {:error, {:fetch_failed, e}}
    catch
      kind, reason ->
        Logger.error("Failed to fetch modal base page #{request_url}: #{inspect({kind, reason})}")
        {:error, {:fetch_failed, {kind, reason}}}
    end
  end

  defp endpoint_opts(endpoint) do
    if function_exported?(endpoint, :init, 1) do
      case endpoint.init([]) do
        {:ok, opts} -> opts
        opts -> opts
      end
    else
      []
    end
  end

  defp put_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {key, value}, acc ->
      put_req_header(acc, String.downcase(key), to_string(value))
    end)
  end

  defp build_headers(conn) do
    base_headers = [
      {"accept", "text/html"},
      {"x-inertia-modal-base-request", "true"}
    ]

    # We do NOT set X-Inertia header - we want HTML response
    # The modal data will be injected after we get the base page

    base_headers ++ forwarded_auth_headers(conn)
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

    base_headers ++ forwarded_auth_headers(conn)
  end

  defp forwarded_auth_headers(conn) do
    forward_first_header(conn, "cookie") ++
      forward_first_header(conn, "authorization")
  end

  defp forward_first_header(conn, name) do
    case get_req_header(conn, name) do
      [value | _] -> [{name, value}]
      [] -> []
    end
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
    # Keep accepting decoded maps for custom endpoint plugs/tests, although
    # Phoenix responses normally arrive here as binaries.
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

  In Inertia v3, the initial page data is embedded in a
  `<script data-page="app" type="application/json">...</script>` tag.

  For backward compatibility, the legacy `data-page` attribute format is also
  supported when parsing existing HTML.

  ## Parameters

    - `html` - The HTML string to parse

  ## Returns

    - `{:ok, page_data}` - The parsed page data as a map
    - `{:error, reason}` - Failed to find or parse the embedded page data
  """
  @spec extract_page_data_from_html(String.t()) :: {:ok, map()} | {:error, String.t()}
  def extract_page_data_from_html(html) do
    case extract_page_data_from_script(html) do
      {:ok, page_data} ->
        {:ok, page_data}

      {:error, _reason} ->
        extract_page_data_from_data_page_attribute(html)
    end
  end

  defp extract_page_data_from_script(html) do
    regex =
      ~r/<script\b(?=[^>]*\bdata-page=(['"])[^'"]+\1)(?=[^>]*\btype=(['"])application\/json\2)[^>]*>(.*?)<\/script>/s

    case Regex.run(regex, html) do
      [_, _quote1, _quote2, encoded_json] ->
        case Jason.decode(encoded_json) do
          {:ok, page_data} -> {:ok, page_data}
          {:error, _} -> {:error, "Failed to parse page data JSON"}
        end

      nil ->
        {:error, "No Inertia page data found in HTML"}
    end
  end

  defp extract_page_data_from_data_page_attribute(html) do
    case Regex.run(~r/data-page='([^']*)'/s, html) do
      [_, encoded_json] ->
        decode_page_data(encoded_json)

      nil ->
        case Regex.run(~r/data-page="([^"]*)"/s, html) do
          [_, encoded_json] ->
            decode_page_data(encoded_json)

          nil ->
            {:error, "No Inertia page data found in HTML"}
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

  Used to decode the HTML-encoded JSON in the legacy `data-page` attribute.
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

  Used when building the composed HTML response for legacy `data-page`
  attribute fallbacks.
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

  Replaces the existing embedded page data with the new page data, preserving
  all other HTML (CSS, JS, etc). Inertia v3 script tags are updated first, with
  a legacy `data-page` attribute fallback for older markup.

  ## Parameters

    - `html` - The original HTML string
    - `page_data` - The modified page data to inject

  ## Returns

    - `{:ok, modified_html}` - The HTML with updated embedded page data
    - `{:error, reason}` - Failed to find existing embedded page data
  """
  @spec inject_page_data_into_html(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def inject_page_data_into_html(html, page_data) do
    case replace_script_page_data(html, page_data) do
      {:ok, modified_html} ->
        {:ok, modified_html}

      {:error, _reason} ->
        replace_legacy_data_page(html, page_data)
    end
  end

  defp replace_script_page_data(html, page_data) do
    encoded_json =
      page_data
      |> Jason.encode!()
      |> String.replace("/", "\\/")

    regex =
      ~r/(<script\b(?=[^>]*\bdata-page=(['"])[^'"]+\2)(?=[^>]*\btype=(['"])application\/json\3)[^>]*>).*?(<\/script>)/s

    case Regex.run(regex, html) do
      [_match | _rest] ->
        modified =
          Regex.replace(regex, html, fn _full, open_tag, _quote1, _quote2, close_tag ->
            open_tag <> encoded_json <> close_tag
          end)

        {:ok, modified}

      nil ->
        {:error, "No Inertia page data found in HTML"}
    end
  end

  defp replace_legacy_data_page(html, page_data) do
    encoded_json = page_data |> Jason.encode!() |> encode_html_entities()

    case Regex.run(~r/data-page='[^']*'/s, html) do
      [_match] ->
        modified = Regex.replace(~r/data-page='[^']*'/s, html, "data-page='#{encoded_json}'")
        {:ok, modified}

      nil ->
        case Regex.run(~r/data-page="[^"]*"/s, html) do
          [_match] ->
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
            {:error, "No Inertia page data found in HTML"}
        end
    end
  end
end
