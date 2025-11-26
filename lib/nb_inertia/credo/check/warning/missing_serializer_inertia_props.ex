# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.MissingSerializerInertiaProps do
    @moduledoc """
    Warns when complex props are rendered without using serializers.

    Serializers ensure consistent formatting (camelCase keys, proper timestamps),
    can hide sensitive fields, and compute derived values.

    ## Example

    Instead of:

        def show(conn, params) do
          render_inertia(conn, :show,
            user: user,           # Raw struct without serializer
            config: widget.config # Raw map
          )
        end

    Use:

        def show(conn, params) do
          render_inertia(conn, :show,
            user: {UserSerializer, user},
            config: {ConfigSerializer, widget.config}
          )
        end

    This check looks for props that use dot notation (e.g., `user.field`)
    or bare variables that likely contain structs/maps without serializers.

    """
    use Credo.Check,
      id: "EX5012",
      base_priority: :normal,
      category: :warning,
      explanations: [
        check: """
        Complex data (structs, maps with nested data) should be serialized
        using NbSerializer before being passed to Inertia pages.

        Serializers provide:
        - Consistent key formatting (camelCase)
        - Proper timestamp serialization
        - Hidden sensitive fields
        - Computed/derived fields

        Instead of:
            render_inertia(:page, user: user)

        Use:
            render_inertia(:page, user: {UserSerializer, user})
        """
      ]

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)

      source_file
      |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
      |> Enum.reverse()
    end

    # Match render_inertia with props that access struct fields directly
    defp traverse(
           {:render_inertia, meta, [_conn, _page, props | _]} = ast,
           issues,
           issue_meta
         )
         when is_list(props) do
      problematic_props = find_unserialzed_complex_props(props)

      if Enum.empty?(problematic_props) do
        {ast, issues}
      else
        new_issues =
          Enum.map(problematic_props, fn {prop_name, reason} ->
            issue_for(issue_meta, meta[:line], prop_name, reason)
          end)

        {ast, new_issues ++ issues}
      end
    end

    defp traverse(ast, issues, _issue_meta), do: {ast, issues}

    # Find props that look like unserialized complex data
    defp find_unserialzed_complex_props(props) do
      Enum.flat_map(props, fn
        # Prop using dot notation: `widget.config`
        {prop_name, {{:., _, _}, _, _}} when is_atom(prop_name) ->
          [{prop_name, :dot_access}]

        # Already using serializer tuple: {Serializer, data} or {Serializer, data, opts}
        {_prop_name, {:{}, _, [{:__aliases__, _, _} | _]}} ->
          []

        {_prop_name, {{:__aliases__, _, _}, _data}} ->
          []

        {_prop_name, {{:__aliases__, _, _}, _data, _opts}} ->
          []

        _ ->
          []
      end)
    end

    defp issue_for(issue_meta, line_no, prop_name, :dot_access) do
      format_issue(
        issue_meta,
        message:
          "Prop `:#{prop_name}` accesses a field directly. Consider using a serializer: `{MySerializer, data}`.",
        trigger: "render_inertia",
        line_no: line_no
      )
    end
  end
end
