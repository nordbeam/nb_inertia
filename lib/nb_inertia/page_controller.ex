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
          render_page(returned_conn, component, page_module, page_props)
        end

      %{} = props_map ->
        render_page(conn, component, page_module, props_map)
    end
  end

  @doc """
  Handles POST/PATCH/PUT/DELETE requests by calling the Page module's `action/3` callback.

  The verb atom is derived from the HTTP method:
  - POST → `:create`
  - PATCH → `:update`
  - PUT → `:update`
  - DELETE → `:delete`

  Custom verbs can be set via `conn.private[:nb_inertia_action_verb]`.

  ## action/3 Return Values

  - `%Plug.Conn{}` — Redirect or modified conn, passes through
  - `{:error, changeset}` — Converts errors via `NbInertia.Errors` protocol, re-mounts
  - `{:error, %{field: [msgs]}}` — Assigns error map, re-mounts
  """
  def action(conn, params) do
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

  defp render_page(conn, component, page_module, props_map) do
    # Process props: handle serializer tuples, apply DSL options
    dsl_props = page_module.__inertia_props__()
    dsl_opts_map = build_dsl_opts_map(dsl_props)

    # Merge in `from:` props (pulled from conn.assigns) and `default:` values
    # for any DSL-declared props not already provided by mount/2
    props_map = apply_from_and_defaults(conn, props_map, dsl_props)

    conn = process_and_assign_props(conn, props_map, dsl_opts_map)

    # Delegate to CoreController for the actual Inertia response
    NbInertia.Controller.do_render_inertia(conn, component)
  end

  defp remount_with_errors(conn, params, page_module, component) do
    # Re-call mount/2 to get the base page props, then render with errors
    dsl_props = page_module.__inertia_props__()
    dsl_opts_map = build_dsl_opts_map(dsl_props)

    case page_module.mount(conn, params) do
      %Plug.Conn{} = returned_conn ->
        if redirected?(returned_conn) do
          returned_conn
        else
          page_props = returned_conn.private[:nb_inertia_page_props] || %{}
          page_props = apply_from_and_defaults(returned_conn, page_props, dsl_props)
          returned_conn = process_and_assign_props(returned_conn, page_props, dsl_opts_map)
          NbInertia.Controller.do_render_inertia(returned_conn, component)
        end

      %{} = props_map ->
        props_map = apply_from_and_defaults(conn, props_map, dsl_props)
        conn = process_and_assign_props(conn, props_map, dsl_opts_map)
        NbInertia.Controller.do_render_inertia(conn, component)
    end
  end

  defp build_dsl_opts_map(dsl_props) do
    dsl_props
    |> Enum.map(fn prop -> {prop.name, prop[:opts] || []} end)
    |> Map.new()
  end

  # Applies `from:` and `default:` DSL options for props not returned by mount/2.
  #
  # - `from: :assigns` — pulls from `conn.assigns[prop_name]`
  # - `from: :key_name` — pulls from `conn.assigns[:key_name]`
  # - `default: value` — uses the default if the prop is not in the mount return
  defp apply_from_and_defaults(conn, props_map, dsl_props) do
    Enum.reduce(dsl_props, props_map, fn prop_config, acc ->
      name = prop_config.name
      opts = prop_config[:opts] || []

      if Map.has_key?(acc, name) do
        # Prop was explicitly provided by mount/2, don't override
        acc
      else
        from = Keyword.get(opts, :from)
        default = Keyword.get(opts, :default, :__no_default__)

        cond do
          # from: :assigns — pull from conn.assigns using the prop name as the key
          from == :assigns ->
            Map.put(acc, name, Map.get(conn.assigns, name))

          # from: :other_key — pull from conn.assigns using the specified key
          is_atom(from) and not is_nil(from) ->
            Map.put(acc, name, Map.get(conn.assigns, from))

          # default: value — use the default value
          default != :__no_default__ ->
            Map.put(acc, name, default)

          true ->
            acc
        end
      end
    end)
  end

  defp process_and_assign_props(conn, props_map, dsl_opts_map) do
    # Split into serializer tuples and raw values
    {serialized_props, raw_props} =
      Enum.split_with(props_map, fn {_key, value} ->
        is_tuple(value) and tuple_size(value) >= 2 and is_atom(elem(value, 0)) and
          Code.ensure_loaded?(elem(value, 0)) and
          function_exported?(elem(value, 0), :serialize, 2)
      end)

    # Handle serialized props (NbSerializer tuples)
    conn =
      if serialized_props != [] and Code.ensure_loaded?(NbSerializer) do
        NbInertia.Controller.assign_serialized_props_with_dsl_opts(
          conn,
          serialized_props,
          dsl_opts_map
        )
      else
        # If NbSerializer not available, treat as raw props
        Enum.reduce(serialized_props, conn, fn {key, value}, acc ->
          dsl_opts = Map.get(dsl_opts_map, key, [])
          NbInertia.Controller.assign_raw_prop_with_dsl_opts(acc, key, value, dsl_opts)
        end)
      end

    # Handle raw props with DSL options applied
    Enum.reduce(raw_props, conn, fn {key, value}, acc ->
      dsl_opts = Map.get(dsl_opts_map, key, [])
      NbInertia.Controller.assign_raw_prop_with_dsl_opts(acc, key, value, dsl_opts)
    end)
  end
end
