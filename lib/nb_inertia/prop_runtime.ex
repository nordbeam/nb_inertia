defmodule NbInertia.PropRuntime do
  @moduledoc false

  alias NbInertia.Controller
  alias NbInertia.CoreController

  @spec dsl_opts_map([map()]) :: map()
  def dsl_opts_map(prop_configs) do
    Map.new(prop_configs, fn prop_config ->
      {prop_config.name, prop_config[:opts] || []}
    end)
  end

  @spec apply_from_and_defaults(Plug.Conn.t(), map(), [map()] | nil) :: map()
  def apply_from_and_defaults(_conn, props_map, nil), do: props_map

  def apply_from_and_defaults(conn, props_map, prop_configs) do
    Enum.reduce(prop_configs, props_map, fn prop_config, acc ->
      name = prop_config.name
      opts = prop_config[:opts] || []

      if Map.has_key?(acc, name) do
        acc
      else
        from = Keyword.get(opts, :from)
        default = Keyword.get(opts, :default, :__no_default__)

        cond do
          from == :assigns ->
            Map.put(acc, name, Map.get(conn.assigns, name))

          is_atom(from) and not is_nil(from) ->
            Map.put(acc, name, Map.get(conn.assigns, from))

          default != :__no_default__ ->
            Map.put(acc, name, default)

          true ->
            acc
        end
      end
    end)
  end

  @spec resolve_inline_shared_props(Plug.Conn.t(), [map()] | nil) :: map()
  def resolve_inline_shared_props(conn, inline_shared_props) do
    apply_from_and_defaults(conn, %{}, inline_shared_props)
  end

  @spec resolve_shared_props(Plug.Conn.t(), list(), [map()] | nil, keyword()) :: map()
  def resolve_shared_props(conn, shared_modules, inline_shared_props, opts \\ []) do
    action = Keyword.get(opts, :action)
    controller_module = Keyword.get(opts, :controller_module)
    deep_merge? = Keyword.get(opts, :deep_merge, false)

    shared_module_props =
      build_shared_module_props(shared_modules, conn, action, controller_module)

    inline_shared_props =
      resolve_inline_shared_props(conn, inline_shared_props)

    merge_props(shared_module_props, inline_shared_props, deep_merge?)
  end

  @spec merge_props(map(), map(), boolean()) :: map()
  def merge_props(left, right, true), do: NbInertia.DeepMerge.deep_merge(left, right)
  def merge_props(left, right, false), do: Map.merge(left, right)

  @spec mark_shared_prop_keys(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def mark_shared_prop_keys(conn, shared_props) do
    if map_size(shared_props) == 0 do
      conn
    else
      CoreController.mark_shared_prop_keys(conn, Map.keys(shared_props))
    end
  end

  @spec assign_props(Plug.Conn.t(), map() | keyword(), map()) :: Plug.Conn.t()
  def assign_props(conn, props_map, dsl_opts_map) when is_map(props_map) do
    assign_props(conn, Map.to_list(props_map), dsl_opts_map)
  end

  def assign_props(conn, props, dsl_opts_map) when is_list(props) do
    {serialized_props, raw_props} = Enum.split_with(props, &serialized_prop?/1)

    conn =
      if serialized_props != [] and Code.ensure_loaded?(NbSerializer) do
        Controller.assign_serialized_props_with_dsl_opts(conn, serialized_props, dsl_opts_map)
      else
        conn
      end

    Enum.reduce(raw_props, conn, fn {key, value}, acc ->
      dsl_opts = Map.get(dsl_opts_map, key, [])
      Controller.assign_raw_prop_with_dsl_opts(acc, key, value, dsl_opts)
    end)
  end

  defp build_shared_module_props(shared_modules, conn, action, controller_module) do
    Enum.reduce(shared_modules || [], %{}, fn module_config, acc ->
      if should_apply_shared_module?(module_config, conn, action, controller_module) do
        module = shared_module(module_config)
        Map.merge(acc, shared_module_props(module, conn))
      else
        acc
      end
    end)
  end

  defp should_apply_shared_module?(module_config, _conn, _action, nil)
       when is_atom(module_config),
       do: true

  defp should_apply_shared_module?(module_config, _conn, _action, nil) when is_map(module_config),
    do: true

  defp should_apply_shared_module?(module_config, conn, action, controller_module) do
    Controller.should_apply_shared_module?(module_config, conn, action, controller_module)
  end

  defp shared_module(%{module: module}), do: module
  defp shared_module(module), do: module

  defp shared_module_props(module, conn) do
    cond do
      function_exported?(module, :serialize_props, 2) ->
        module.serialize_props(conn, [])

      function_exported?(module, :build_and_validate_props, 2) ->
        module.build_and_validate_props(conn, [])

      true ->
        module.build_props(conn, [])
    end
  end

  defp serialized_prop?({_key, value}) do
    is_tuple(value) and tuple_size(value) >= 2 and is_atom(elem(value, 0))
  end
end
