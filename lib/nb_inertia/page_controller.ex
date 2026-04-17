defmodule NbInertia.PageController do
  @moduledoc """
  Thin Phoenix controller adapter that dispatches to `NbInertia.Page` modules.

  This controller is used by the router to bridge standard Phoenix routing with
  Page modules. It receives requests and dispatches to the appropriate Page module's
  `mount/2` or `action/3` callbacks.

  ## How It Works

  The Page module is stored in `conn.private[:nb_inertia_page_module]` by router
  integration or a plug, and this controller dispatches to it.

  ## Router Usage

      # In your router:
      get "/users", NbInertia.PageController, :show,
        private: %{nb_inertia_page_module: MyAppWeb.UsersPage.Index}

      post "/users", NbInertia.PageController, :action,
        private: %{nb_inertia_page_module: MyAppWeb.UsersPage.Index}
  """

  use Phoenix.Controller, formats: [:html, :json]

  import Plug.Conn
  import NbInertia.CoreController

  # Override Phoenix's action/2 dispatcher to correctly route to show/2 or do_action/2
  # based on the Phoenix action name. Without this, our def action/2 below would shadow
  # Phoenix's auto-generated dispatcher, causing all routes to hit action/2 instead of show/2.
  def action(conn, _opts) do
    case action_name(conn) do
      :show -> show(conn, conn.params)
      :action -> do_action(conn, conn.params)
      other -> apply(__MODULE__, other, [conn, conn.params])
    end
  end

  @doc """
  Handles GET requests by calling the Page module's `mount/2` callback.

  ## mount/2 Return Values

  - `%{key: value}` (map) — Treated as props, renders Inertia response
  - `%Plug.Conn{}` — Props extracted from `conn.private[:nb_inertia_page_props]`, renders
  - `%Plug.Conn{state: :set}` — Redirect, passes through unchanged
  """
  def show(conn, params) do
    page_module = get_page_module!(conn)
    opts = page_module.__inertia_options__()
    component = page_module.__inertia_component__()

    # Apply module-level options to conn
    conn = apply_page_options(conn, opts)

    case page_module.mount(conn, params) do
      %Plug.Conn{} = returned_conn ->
        if redirected?(returned_conn) do
          returned_conn
        else
          page_props = returned_conn.private[:nb_inertia_page_props] || %{}
          render_page_or_modal(returned_conn, component, page_module, page_props, params)
        end

      %{} = props_map ->
        render_page_or_modal(conn, component, page_module, props_map, params)
    end
  end

  @doc false
  def do_action(conn, params) do
    page_module = get_page_module!(conn)

    unless page_module.__inertia_has_action__() do
      raise "#{inspect(page_module)} does not define action/3 but received a #{conn.method} request"
    end

    opts = page_module.__inertia_options__()
    component = page_module.__inertia_component__()
    verb = derive_verb(conn)

    # Apply module-level options to conn
    conn = apply_page_options(conn, opts)

    case page_module.action(conn, params, verb) do
      %Plug.Conn{} = returned_conn ->
        returned_conn

      {:error, errors} ->
        # Assign errors and re-mount the page
        conn = assign_errors(conn, errors)
        remount_with_errors(conn, params, page_module, component)
    end
  end

  # -- Private helpers --

  defp get_page_module!(conn) do
    case conn.private[:nb_inertia_page_module] do
      nil ->
        raise ArgumentError, """
        No page module found in conn.private[:nb_inertia_page_module].

        Make sure the route sets the page module:

            get "/users", NbInertia.PageController, :show,
              private: %{nb_inertia_page_module: MyAppWeb.UsersPage.Index}
        """

      module ->
        module
    end
  end

  defp apply_page_options(conn, opts) do
    conn
    |> maybe_encrypt_history(opts)
    |> maybe_clear_history(opts)
    |> maybe_preserve_fragment(opts)
    |> maybe_camelize_props(opts)
  end

  defp maybe_encrypt_history(conn, %{encrypt_history: true}),
    do: encrypt_history(conn)

  defp maybe_encrypt_history(conn, _), do: conn

  defp maybe_clear_history(conn, %{clear_history: true}),
    do: clear_history(conn)

  defp maybe_clear_history(conn, _), do: conn

  defp maybe_preserve_fragment(conn, %{preserve_fragment: true}),
    do: preserve_fragment(conn)

  defp maybe_preserve_fragment(conn, _), do: conn

  defp maybe_camelize_props(conn, %{camelize_props: true}),
    do: camelize_props(conn)

  defp maybe_camelize_props(conn, _opts) do
    if NbInertia.Config.camelize_props?() do
      camelize_props(conn)
    else
      conn
    end
  end

  defp derive_verb(conn) do
    # Check for custom verb first
    case conn.private[:nb_inertia_action_verb] do
      nil -> method_to_verb(conn.method)
      verb -> verb
    end
  end

  defp method_to_verb("POST"), do: :create
  defp method_to_verb("PATCH"), do: :update
  defp method_to_verb("PUT"), do: :update
  defp method_to_verb("DELETE"), do: :delete
  defp method_to_verb(method), do: method |> String.downcase() |> String.to_atom()

  defp redirected?(%Plug.Conn{state: :set, status: status}) when status in 301..303, do: true
  defp redirected?(_conn), do: false

  # Decides whether to render as a modal or a regular page based on
  # the page module's modal configuration.
  defp render_page_or_modal(conn, component, page_module, props_map, params) do
    modal_config = get_modal_config(conn, page_module, params)

    if modal_config do
      render_modal(conn, component, page_module, props_map, modal_config)
    else
      render_page(conn, component, page_module, props_map)
    end
  end

  # Returns the resolved modal config (keyword list) if the page has modal
  # configuration, or nil if it doesn't.
  defp get_modal_config(conn, page_module, params) do
    module_config = page_module.__inertia_modal__()

    if module_config do
      # Resolve dynamic base_url if it's a function
      module_config = resolve_dynamic_base_url(module_config, params)

      # Apply per-request overrides from modal_config/2
      case conn.private[:nb_inertia_page_modal_overrides] do
        nil -> module_config
        overrides -> Keyword.merge(module_config, overrides)
      end
    else
      # No module-level modal config, but check for per-request overrides
      case conn.private[:nb_inertia_page_modal_overrides] do
        nil -> nil
        overrides -> overrides
      end
    end
  end

  # Resolves dynamic base_url when it's a function
  defp resolve_dynamic_base_url(config, params) do
    case Keyword.get(config, :base_url) do
      fun when is_function(fun, 1) ->
        Keyword.put(config, :base_url, fun.(params))

      _ ->
        config
    end
  end

  # Renders the page as a modal using the existing NbInertia.Modal infrastructure.
  defp render_modal(conn, component, page_module, props_map, modal_config) do
    dsl_props = page_module.__inertia_props__()
    props_map = apply_from_and_defaults(conn, props_map, dsl_props)
    shared_props = shared_props_for_page(conn, page_module)

    # Build serialized modal props from the props_map
    modal_props = build_modal_props_from_map(Map.merge(shared_props, props_map))

    # Build the Modal struct using existing NbInertia.Modal module
    base_url = Keyword.get(modal_config, :base_url)

    unless base_url do
      raise ArgumentError, """
      Modal page #{inspect(page_module)} requires a :base_url.

      Set it in the modal macro:

          modal base_url: "/users", size: :lg

      Or in mount/2 via modal_config/2:

          def mount(conn, %{"id" => id}) do
            conn
            |> modal_config(base_url: ~p"/users/\#{id}")
            |> props(%{user: get_user!(id)})
          end
      """
    end

    # Extract base URL from RouteResult or string
    resolved_base_url =
      case base_url do
        %{url: url} when is_binary(url) -> url
        url when is_binary(url) -> url
        _ -> raise ArgumentError, ":base_url must be a string or RouteResult struct"
      end

    modal =
      NbInertia.Modal.new(component, %{})
      |> NbInertia.Modal.base_url(resolved_base_url)
      |> apply_modal_config_options(modal_config)

    # Render using the existing modal renderer
    NbInertia.Modal.Renderer.render!(conn, modal, modal_props)
  end

  defp apply_modal_config_options(modal, opts) do
    Enum.reduce(opts, modal, fn
      {:size, size}, acc -> NbInertia.Modal.size(acc, size)
      {:position, position}, acc -> NbInertia.Modal.position(acc, position)
      {:slideover, enabled}, acc -> NbInertia.Modal.slideover(acc, enabled)
      {:close_button, enabled}, acc -> NbInertia.Modal.close_button(acc, enabled)
      {:close_explicitly, enabled}, acc -> NbInertia.Modal.close_explicitly(acc, enabled)
      {:base_url, _}, acc -> acc
      # Ignore unknown options
      _, acc -> acc
    end)
  end

  # Builds serialized props map for modal rendering.
  # Handles NbSerializer tuples if available.
  defp build_modal_props_from_map(props_map) do
    props_list = Enum.to_list(props_map)

    if function_exported?(NbInertia.Controller, :build_modal_props, 1) do
      NbInertia.Controller.build_modal_props(props_list)
    else
      Map.new(props_list)
    end
  end

  defp render_page(conn, component, page_module, props_map) do
    dsl_props = page_module.__inertia_props__()
    inline_shared_props = page_module.__inertia_shared_inline__() || []
    dsl_opts_map = build_dsl_opts_map(dsl_props ++ inline_shared_props)

    props_map = apply_from_and_defaults(conn, props_map, dsl_props)
    shared_props = shared_props_for_page(conn, page_module)

    conn =
      conn
      |> NbInertia.PropRuntime.mark_shared_prop_keys(shared_props)
      |> process_and_assign_props(Map.merge(shared_props, props_map), dsl_opts_map)

    NbInertia.Controller.do_render_inertia(conn, component)
  end

  defp remount_with_errors(conn, params, page_module, component) do
    # Preserve errors already assigned to the conn (from assign_errors in do_action).
    # We need to save and restore them because apply_from_and_defaults may overwrite
    # :errors with a default value (e.g., `prop :errors, :map, default: %{}`).
    saved_errors = conn.private[:inertia_shared][:errors]

    dsl_props = page_module.__inertia_props__()
    inline_shared_props = page_module.__inertia_shared_inline__() || []
    dsl_opts_map = build_dsl_opts_map(dsl_props ++ inline_shared_props)

    case page_module.mount(conn, params) do
      %Plug.Conn{} = returned_conn ->
        if redirected?(returned_conn) do
          returned_conn
        else
          page_props = returned_conn.private[:nb_inertia_page_props] || %{}
          page_props = apply_from_and_defaults(returned_conn, page_props, dsl_props)
          shared_props = shared_props_for_page(returned_conn, page_module)

          returned_conn =
            returned_conn
            |> NbInertia.PropRuntime.mark_shared_prop_keys(shared_props)
            |> process_and_assign_props(Map.merge(shared_props, page_props), dsl_opts_map)

          returned_conn = restore_errors(returned_conn, saved_errors)
          NbInertia.Controller.do_render_inertia(returned_conn, component)
        end

      %{} = props_map ->
        props_map = apply_from_and_defaults(conn, props_map, dsl_props)
        shared_props = shared_props_for_page(conn, page_module)

        conn =
          conn
          |> NbInertia.PropRuntime.mark_shared_prop_keys(shared_props)
          |> process_and_assign_props(Map.merge(shared_props, props_map), dsl_opts_map)

        conn = restore_errors(conn, saved_errors)
        NbInertia.Controller.do_render_inertia(conn, component)
    end
  end

  # Restores previously saved errors onto the conn, ensuring they aren't
  # overwritten by prop defaults during remount.
  defp restore_errors(conn, nil), do: conn

  defp restore_errors(conn, saved_errors) do
    shared = conn.private[:inertia_shared] || %{}
    put_private(conn, :inertia_shared, Map.put(shared, :errors, saved_errors))
  end

  defp shared_props_for_page(conn, page_module) do
    router_shared_modules = conn.private[:nb_inertia_shared_modules] || []
    page_shared_modules = page_module.__inertia_shared_modules__()

    NbInertia.PropRuntime.resolve_shared_props(
      conn,
      router_shared_modules ++ page_shared_modules,
      page_module.__inertia_shared_inline__()
    )
  end

  defp build_dsl_opts_map(dsl_props) do
    NbInertia.PropRuntime.dsl_opts_map(dsl_props)
  end

  # Applies `from:` and `default:` DSL options for props not returned by mount/2.
  #
  # - `from: :assigns` — pulls from `conn.assigns[prop_name]`
  # - `from: :key_name` — pulls from `conn.assigns[:key_name]`
  # - `default: value` — uses the default if the prop is not in the mount return
  defp apply_from_and_defaults(conn, props_map, dsl_props) do
    NbInertia.PropRuntime.apply_from_and_defaults(conn, props_map, dsl_props)
  end

  defp process_and_assign_props(conn, props_map, dsl_opts_map) do
    NbInertia.PropRuntime.assign_props(conn, props_map, dsl_opts_map)
  end
end
