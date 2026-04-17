defmodule NbInertia.Plug do
  @moduledoc """
  The main Inertia.js plug for detecting and handling Inertia requests.

  This plug implements the [Inertia.js protocol](https://inertiajs.com/the-protocol)
  and handles flash data persistence. Add it to your browser pipeline:

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug NbInertia.Plug
        plug NbInertia.Plugs.ModalHeaders
      end

  ## What this plug does

  1. **Inertia request detection** - Checks for the `X-Inertia` header
  2. **Asset versioning** - Computes version from static paths, forces refresh on mismatch
  3. **Partial reloads** - Parses `X-Inertia-Partial-*` headers for selective prop loading
  4. **Redirect handling** - Converts PUT/PATCH/DELETE 301/302 to 303, handles external redirects
  5. **Error persistence** - Preserves validation errors across redirects via session
  6. **Flash persistence** - Loads/persists NbInertia flash data across redirects
  """

  @behaviour Plug

  import Plug.Conn

  alias NbInertia.CoreController
  alias NbInertia.Flash

  @redirect_statuses 301..308
  @flash_redirect_statuses [301, 302, 303, 307, 308]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    conn
    |> assign(:inertia_head, [])
    |> put_private(:inertia_version, compute_version())
    |> put_private(:inertia_error_bag, get_error_bag(conn))
    |> put_private(:inertia_encrypt_history, default_encrypt_history())
    |> put_private(:inertia_clear_history, false)
    |> put_private(:inertia_preserve_fragment, false)
    |> put_private(:inertia_prefetch, false)
    |> put_private(:inertia_except_once_props, [])
    |> put_private(:inertia_shared_prop_keys, [])
    |> put_private(:inertia_camelize_props, default_camelize_props())
    |> Flash.load_from_session()
    |> merge_forwarded_flash()
    |> fetch_inertia_errors()
    |> register_flash_persistence()
    |> detect_inertia()
  end

  # -- Flash persistence (absorbed from NbInertia.Plugs.Flash) --

  defp register_flash_persistence(conn) do
    register_before_send(conn, fn conn ->
      is_prefetch = conn.private[:inertia_prefetch] == true

      if !is_prefetch and conn.status in @flash_redirect_statuses do
        Flash.persist_to_session(conn)
      else
        conn
      end
    end)
  end

  # -- Inertia error session persistence --

  defp fetch_inertia_errors(conn) do
    errors = get_session(conn, "inertia_errors") || %{}
    conn = CoreController.assign_errors(conn, errors)

    register_before_send(conn, fn %{status: status} = conn ->
      props = conn.private[:inertia_shared] || %{}

      errors =
        case props[:errors] do
          {:keep, data} -> data
          _ -> %{}
        end

      # Keep errors if responding with a redirect (301..308) or force refresh (409)
      if (status in @redirect_statuses or status == 409) and map_size(errors) > 0 do
        put_session(conn, "inertia_errors", errors)
      else
        delete_session(conn, "inertia_errors")
      end
    end)
  end

  # -- Inertia request detection --

  defp detect_inertia(conn) do
    case get_req_header(conn, "x-inertia") do
      ["true"] ->
        conn
        |> put_private(:inertia_version, compute_version())
        |> put_private(:inertia_request, true)
        |> detect_partial_reload()
        |> detect_reset()
        |> detect_infinite_scroll_merge_intent()
        |> detect_prefetch()
        |> detect_except_once_props()
        |> convert_redirects()
        |> check_version()

      _ ->
        conn
    end
  end

  defp detect_partial_reload(conn) do
    case get_req_header(conn, "x-inertia-partial-component") do
      [component] when is_binary(component) ->
        conn
        |> put_private(:inertia_partial_component, component)
        |> put_private(:inertia_partial_only, get_partial_only(conn))
        |> put_private(:inertia_partial_except, get_partial_except(conn))

      _ ->
        conn
    end
  end

  defp detect_reset(conn) do
    resets =
      case get_req_header(conn, "x-inertia-reset") do
        [list] when is_binary(list) -> String.split(list, ",")
        _ -> []
      end

    put_private(conn, :inertia_reset, resets)
  end

  defp detect_infinite_scroll_merge_intent(conn) do
    case get_req_header(conn, "x-inertia-infinite-scroll-merge-intent") do
      [intent] when is_binary(intent) ->
        case String.downcase(intent) do
          "append" -> put_private(conn, :inertia_scroll_merge_intent, "append")
          "prepend" -> put_private(conn, :inertia_scroll_merge_intent, "prepend")
          _ -> conn
        end

      _ ->
        conn
    end
  end

  defp detect_prefetch(conn) do
    purpose_prefetch? =
      conn
      |> get_req_header("purpose")
      |> Enum.any?(fn value -> String.downcase(value) == "prefetch" end)

    legacy_prefetch? =
      case get_req_header(conn, "x-inertia-prefetch") do
        ["true"] -> true
        _ -> false
      end

    if purpose_prefetch? or legacy_prefetch? do
      put_private(conn, :inertia_prefetch, true)
    else
      conn
    end
  end

  defp detect_except_once_props(conn) do
    except_once_props =
      case get_req_header(conn, "x-inertia-except-once-props") do
        [list] when is_binary(list) and list != "" -> String.split(list, ",")
        _ -> []
      end

    put_private(conn, :inertia_except_once_props, except_once_props)
  end

  defp get_partial_only(conn) do
    case get_req_header(conn, "x-inertia-partial-data") do
      [list] when is_binary(list) -> String.split(list, ",")
      _ -> []
    end
  end

  defp get_partial_except(conn) do
    case get_req_header(conn, "x-inertia-partial-except") do
      [list] when is_binary(list) -> String.split(list, ",")
      _ -> []
    end
  end

  defp get_error_bag(conn) do
    case get_req_header(conn, "x-inertia-error-bag") do
      [error_bag] when is_binary(error_bag) -> error_bag
      _ -> nil
    end
  end

  # -- Redirect handling --

  defp convert_redirects(conn) do
    register_before_send(conn, fn %{method: method, status: status} = conn ->
      cond do
        # Hash fragment redirect: return 409 so client can do SPA visit preserving fragment
        fragment_redirect?(conn) ->
          [location] = get_resp_header(conn, "location")

          conn
          |> put_status(409)
          |> put_resp_header("x-inertia-redirect", location)

        # External redirects: https://inertiajs.com/redirects#external-redirects
        external_redirect?(conn) ->
          [location] = get_resp_header(conn, "location")

          conn
          |> put_status(409)
          |> put_resp_header("x-inertia-location", location)

        # 303 conversion: https://inertiajs.com/redirects#303-response-code
        method in ["PUT", "PATCH", "DELETE"] and status in [301, 302] ->
          put_status(conn, 303)

        true ->
          conn
      end
    end)
  end

  defp fragment_redirect?(%{status: status} = conn) when status in 300..308 do
    case get_resp_header(conn, "location") do
      [location] -> has_fragment?(location) and conn.private[:inertia_request] == true
      _ -> false
    end
  end

  defp fragment_redirect?(_conn), do: false

  defp has_fragment?(url) when is_binary(url) do
    String.contains?(url, "#")
  end

  defp has_fragment?(_), do: false

  defp external_redirect?(%{status: status} = conn) when status in 300..308 do
    [location] = get_resp_header(conn, "location")
    conn.private[:inertia_force_redirect] || !String.starts_with?(location, "/")
  end

  defp external_redirect?(_conn), do: false

  # -- Asset versioning --

  # https://inertiajs.com/the-protocol#asset-versioning
  defp check_version(%{private: %{inertia_version: current_version}} = conn) do
    if conn.method == "GET" && get_req_header(conn, "x-inertia-version") != [current_version] do
      force_refresh(conn)
    else
      conn
    end
  end

  defp compute_version do
    endpoint = NbInertia.Config.endpoint()
    paths = NbInertia.Config.static_paths()

    if is_atom(endpoint) and endpoint != nil and length(paths) > 0 do
      hash_static_paths(endpoint, paths)
    else
      NbInertia.Config.default_version()
    end
  end

  defp hash_static_paths(endpoint, paths) do
    paths
    |> Enum.map_join(&endpoint.static_path(&1))
    |> then(&Base.encode16(:crypto.hash(:md5, &1), case: :lower))
  end

  defp force_refresh(conn) do
    conn
    |> put_resp_header("x-inertia-location", request_url(conn))
    |> put_resp_content_type("text/html")
    |> forward_flash()
    |> send_resp(:conflict, "")
    |> halt()
  end

  # -- Flash forwarding across 409 refreshes --

  defp forward_flash(%{assigns: %{flash: flash}} = conn)
       when is_map(flash) and map_size(flash) > 0 do
    put_session(conn, "inertia_flash", flash)
  end

  defp forward_flash(conn), do: conn

  defp merge_forwarded_flash(conn) do
    case get_session(conn, "inertia_flash") do
      nil ->
        conn

      flash ->
        conn
        |> delete_session("inertia_flash")
        |> assign(:flash, Map.merge(conn.assigns.flash, flash))
    end
  end

  # -- Config helpers --

  defp default_camelize_props do
    NbInertia.Config.camelize_props()
  end

  defp default_encrypt_history do
    history = NbInertia.Config.history()
    !!Keyword.get(history, :encrypt, false)
  end
end
