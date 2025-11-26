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

      source_file
      |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
      |> Enum.reverse()
    end

    # Match render_inertia calls with props containing nil values
    defp traverse(
           {:render_inertia, meta, [_conn, _page, props | _]} = ast,
           issues,
           issue_meta
         )
         when is_list(props) do
      nil_props = find_nil_props(props)

      if Enum.empty?(nil_props) do
        {ast, issues}
      else
        new_issues =
          Enum.map(nil_props, fn prop_name ->
            issue_for(issue_meta, meta[:line], prop_name)
          end)

        {ast, new_issues ++ issues}
      end
    end

    defp traverse(ast, issues, _issue_meta), do: {ast, issues}

    defp find_nil_props(props) do
      Enum.flat_map(props, fn
        {prop_name, nil} when is_atom(prop_name) ->
          [prop_name]

        {prop_name, {nil, _, _}} when is_atom(prop_name) ->
          [prop_name]

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
