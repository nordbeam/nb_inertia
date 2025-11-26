# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Readability.InertiaPageComponentNameCase do
    @moduledoc """
    Ensures Inertia page component names follow PascalCase convention.

    When using the `component:` option in `inertia_page`, the component name
    should be PascalCase to match React/Vue component naming conventions.

    ## Example

    Instead of:

        inertia_page :index, component: "items_index" do
          prop :items, list: ItemSerializer
        end

    Use:

        inertia_page :index, component: "Items/Index" do
          prop :items, list: ItemSerializer
        end

    """
    use Credo.Check,
      id: "EX5016",
      base_priority: :low,
      category: :readability,
      explanations: [
        check: """
        Inertia page component names should follow PascalCase convention
        (e.g., "Users/Show" not "users_show").

        This matches React/Vue component naming conventions and ensures
        consistency with frontend code.
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

    # Match inertia_page with explicit component option
    defp traverse({:inertia_page, meta, [_page_name, opts | _rest]} = ast, issues, issue_meta)
         when is_list(opts) do
      case Keyword.get(opts, :component) do
        nil ->
          {ast, issues}

        component_name when is_binary(component_name) ->
          if valid_component_name?(component_name) do
            {ast, issues}
          else
            new_issue = issue_for(issue_meta, meta[:line], component_name)
            {ast, [new_issue | issues]}
          end

        _ ->
          {ast, issues}
      end
    end

    defp traverse(ast, issues, _issue_meta), do: {ast, issues}

    # Check if component name follows PascalCase convention
    # Valid: "Users/Show", "Items/Index", "Dashboard"
    # Invalid: "users_show", "items/index", "dashboard"
    defp valid_component_name?(name) do
      name
      |> String.split("/")
      |> Enum.all?(&pascal_case?/1)
    end

    defp pascal_case?(segment) do
      # Must start with uppercase letter
      String.match?(segment, ~r/^[A-Z][a-zA-Z0-9]*$/)
    end

    defp issue_for(issue_meta, line_no, component_name) do
      suggested = suggest_pascal_case(component_name)

      format_issue(
        issue_meta,
        message:
          "Component name `#{component_name}` should be PascalCase. Consider: `#{suggested}`.",
        trigger: "inertia_page",
        line_no: line_no
      )
    end

    defp suggest_pascal_case(name) do
      name
      |> String.split(~r/[_\/]/)
      |> Enum.map(&String.capitalize/1)
      |> Enum.join("/")
    end
  end
end
