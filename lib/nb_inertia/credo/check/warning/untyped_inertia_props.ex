# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.UntypedInertiaProps do
    @moduledoc """
    Warns when props use generic types (`:map`, `:list`) instead of explicit
    TypeScript types or serializers.

    Generic types lose structure information on the frontend, making it harder
    for TypeScript to provide type safety and IDE autocomplete.

    ## Example

    Instead of:

        inertia_page :index do
          prop :filters, :map
          prop :data, :list
        end

    Use:

        inertia_page :index do
          prop :filters, type: ~TS"{ search?: string; status?: string }"
          prop :data, list: ItemSerializer
        end

    """
    use Credo.Check,
      id: "EX5011",
      base_priority: :normal,
      category: :warning,
      explanations: [
        check: """
        Generic types like `:map` and `:list` should be replaced with explicit
        TypeScript types or serializers.

        This enables:
        - Frontend type safety with TypeScript
        - IDE autocomplete support
        - Better API documentation

        Instead of:
            prop :data, :map

        Use:
            prop :data, type: ~TS"{ key: string; value: number }"
            # or
            prop :data, DataSerializer
        """
      ]

    @generic_types [:map, :list, :any]

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)

      source_file
      |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
      |> Enum.reverse()
    end

    # Match prop declarations with generic types
    defp traverse({:prop, meta, [prop_name, type | _rest]} = ast, issues, issue_meta)
         when is_atom(prop_name) and type in @generic_types do
      new_issue = issue_for(issue_meta, meta[:line], prop_name, type)
      {ast, [new_issue | issues]}
    end

    defp traverse(ast, issues, _issue_meta), do: {ast, issues}

    defp issue_for(issue_meta, line_no, prop_name, type) do
      suggestion =
        case type do
          :map -> "type: ~TS\"{ key: value }\" or a Serializer"
          :list -> "list: ItemSerializer or type: ~TS\"ItemType[]\""
          :any -> "a specific type or Serializer"
        end

      format_issue(
        issue_meta,
        message:
          "Prop `:#{prop_name}` uses generic type `:#{type}`. Consider using #{suggestion} for better type safety.",
        trigger: "prop",
        line_no: line_no
      )
    end
  end
end
