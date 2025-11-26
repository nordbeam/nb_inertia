defmodule NbInertia.Credo.Check.Readability.PropFromAssigns do
  @moduledoc """
  Suggests using the `from: :assigns` option when passing conn.assigns values as props.

  When you need to pass a value from `conn.assigns` to your Inertia page, it's cleaner
  to use the `from: :assigns` option in your prop declaration instead of manually
  accessing `conn.assigns` in your controller action.

  This makes the data flow explicit in your page declaration and reduces boilerplate
  in your controller actions.

  ## Example

  Instead of:

      inertia_page :dashboard do
        prop :current_user, :map
        prop :flash, :map
      end

      def index(conn, _params) do
        render_inertia(conn, :dashboard,
          current_user: conn.assigns.current_user,  # Manual access
          flash: conn.assigns.flash                  # Manual access
        )
      end

  Use:

      inertia_page :dashboard do
        prop :current_user, :map, from: :assigns
        prop :flash, from: :assigns
      end

      def index(conn, _params) do
        render_inertia(conn, :dashboard)
        # Props are automatically pulled from assigns!
      end

  Or use shared props for values needed across multiple pages:

      inertia_shared do
        prop :current_user, :map, from: :assigns
        prop :flash, from: :assigns
      end

  """
  use Credo.Check,
    id: "EX5004",
    base_priority: :low,
    category: :readability,
    explanations: [
      check: """
      When passing `conn.assigns` values to Inertia props, consider using
      the `from: :assigns` option in your prop declaration.

      This approach:
      - Makes data flow explicit in your page declaration
      - Reduces boilerplate in controller actions
      - Works well with shared props for common values

      Instead of:
          render_inertia(conn, :page, current_user: conn.assigns.current_user)

      Declare with `from: :assigns`:
          inertia_page :page do
            prop :current_user, :map, from: :assigns
          end

          def action(conn, _params) do
            render_inertia(conn, :page)
          end
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

  # Match `render_inertia(conn, page, props)` where props contains conn.assigns access
  defp traverse(
         {:render_inertia, meta, [_conn, _page, props | _]} = ast,
         issues,
         issue_meta
       )
       when is_list(props) do
    assigns_props = find_assigns_access(props)

    if Enum.empty?(assigns_props) do
      {ast, issues}
    else
      new_issues =
        Enum.map(assigns_props, fn prop_name ->
          issue_for(issue_meta, meta[:line], prop_name)
        end)

      {ast, new_issues ++ issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  # Find prop keys that have conn.assigns access as their value
  defp find_assigns_access(props) when is_list(props) do
    Enum.reduce(props, [], fn
      # Match {prop_name, {{:., _, [{:conn, _, _}, :assigns]}, _, _}}
      {prop_name, {{:., _, [_, :assigns]}, _, _}}, acc when is_atom(prop_name) ->
        [prop_name | acc]

      # Match {prop_name, {{:., _, [{{:., _, [{:conn, _, _}, :assigns]}, _, _}, _field]}, _, _}}
      {prop_name,
       {{:., _,
         [
           {{:., _, [_, :assigns]}, _, _},
           _field
         ]}, _, _}},
      acc
      when is_atom(prop_name) ->
        [prop_name | acc]

      # Match conn.assigns.field pattern more broadly
      {prop_name, value}, acc when is_atom(prop_name) ->
        if contains_assigns_access?(value) do
          [prop_name | acc]
        else
          acc
        end

      _, acc ->
        acc
    end)
  end

  defp find_assigns_access(_), do: []

  # Recursively check if AST contains conn.assigns access
  defp contains_assigns_access?({{:., _, [{:conn, _, nil}, :assigns]}, _, _}), do: true

  defp contains_assigns_access?({{:., _, [inner, _field]}, _, _}) do
    contains_assigns_access?(inner)
  end

  defp contains_assigns_access?({_, _, args}) when is_list(args) do
    Enum.any?(args, &contains_assigns_access?/1)
  end

  defp contains_assigns_access?(_), do: false

  defp issue_for(issue_meta, line_no, prop_name) do
    format_issue(
      issue_meta,
      message:
        "Consider using `prop :#{prop_name}, from: :assigns` instead of accessing `conn.assigns` directly.",
      trigger: "conn.assigns",
      line_no: line_no
    )
  end
end
