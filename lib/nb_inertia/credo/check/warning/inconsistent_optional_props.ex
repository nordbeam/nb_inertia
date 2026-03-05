# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.InconsistentOptionalProps do
    @moduledoc """
    Warns when optional props are passed with `nil` instead of an appropriate
    empty value or when they're missing entirely.

    Optional props should be handled consistently - either always pass them
    with a sensible default, or rely on the frontend to handle `undefined`.

    ## Example

    Instead of:

        render_inertia(conn, :show,
          user: user,
          settings: nil  # Inconsistent - might be undefined or null on frontend
        )

    Use:

        render_inertia(conn, :show,
          user: user,
          settings: user.settings || %{}  # Consistent empty value
        )

    Or omit optional props entirely and handle `undefined` on the frontend.

    """
    use Credo.Check,
      id: "EX5014",
      base_priority: :low,
      category: :warning,
      explanations: [
        check: """
        Optional props should not be passed as `nil` explicitly.

        Either:
        1. Pass a sensible default value (empty map, empty list, etc.)
        2. Omit the prop entirely and handle `undefined` on the frontend

        Passing `nil` explicitly creates inconsistency between null and
        undefined on the JavaScript side.
        """
      ]

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)

      # First pass: collect nullable props per inertia_page
      nullable_props = collect_nullable_props(source_file)

      state = %{issue_meta: issue_meta, issues: [], nullable_props: nullable_props}

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), state)

      Enum.reverse(final_state.issues)
    end

    # Collect nullable props from inertia_page declarations
    defp collect_nullable_props(source_file) do
      Credo.Code.prewalk(source_file, &collect_traverse(&1, &2), %{})
    end

    # Match inertia_page :name, ..., do: block
    defp collect_traverse(
           {:inertia_page, _meta, [page_name | _rest]} = ast,
           acc
         )
         when is_atom(page_name) do
      nullable = extract_nullable_props(ast)
      {ast, Map.put(acc, page_name, nullable)}
    end

    defp collect_traverse(ast, acc), do: {ast, acc}

    defp extract_nullable_props({:inertia_page, _meta, args}) do
      # The do block is in the last keyword list arg
      do_block =
        args
        |> Enum.filter(&is_list/1)
        |> Enum.find_value(fn kw -> Keyword.get(kw, :do) end)

      extract_nullable_from_block(do_block)
    end

    defp extract_nullable_from_block({:__block__, _, statements}),
      do: Enum.flat_map(statements, &extract_nullable_from_prop/1)

    defp extract_nullable_from_block({:prop, _, _} = prop),
      do: extract_nullable_from_prop(prop)

    defp extract_nullable_from_block(_), do: []

    # prop(:name, Type, nullable: true)
    defp extract_nullable_from_prop({:prop, _, [name | rest]}) when is_atom(name) do
      opts = Enum.find(rest, &is_list/1)
      if opts && Keyword.get(opts, :nullable) == true, do: [name], else: []
    end

    defp extract_nullable_from_prop(_), do: []

    # Match render_inertia calls with props containing nil values
    defp traverse(
           {:render_inertia, meta, [_conn, page, props | _]} = ast,
           state
         )
         when is_list(props) and is_atom(page) do
      page_nullable = Map.get(state.nullable_props, page, [])
      nil_props = find_nil_props(props, page_nullable)

      if Enum.empty?(nil_props) do
        {ast, state}
      else
        new_issues =
          Enum.map(nil_props, fn prop_name ->
            issue_for(state.issue_meta, meta[:line], prop_name)
          end)

        {ast, %{state | issues: new_issues ++ state.issues}}
      end
    end

    defp traverse(ast, state), do: {ast, state}

    defp find_nil_props(props, nullable_props) do
      Enum.flat_map(props, fn
        {prop_name, nil} when is_atom(prop_name) ->
          if prop_name in nullable_props, do: [], else: [prop_name]

        {prop_name, {nil, _, _}} when is_atom(prop_name) ->
          if prop_name in nullable_props, do: [], else: [prop_name]

        _ ->
          []
      end)
    end

    defp issue_for(issue_meta, line_no, prop_name) do
      format_issue(
        issue_meta,
        message:
          "Prop `:#{prop_name}` is set to `nil`. Consider using a default value or omitting it entirely.",
        trigger: "render_inertia",
        line_no: line_no
      )
    end
  end
end
