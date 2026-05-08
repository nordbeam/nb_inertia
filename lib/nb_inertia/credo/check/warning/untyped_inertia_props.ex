# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.UntypedInertiaProps do
    @moduledoc """
    Warns when props use generic types (`:map`, `:list`) instead of explicit
    TypeScript types or serializers.

    Generic types lose structure information on the frontend, making it harder
    for TypeScript to provide type safety and IDE autocomplete.

    Works in both Controller `inertia_page` blocks and Page module-level `prop` declarations.

    ## Example

    Instead of:

        inertia_page :index do
          prop :filters, :map
          prop :data, :list
        end

    Use:

        inertia_page :index do
          prop :filters, shape(search: optional(:string), status: optional(:string))
          prop :data, list_of(ref(ItemSerializer))
        end

    Also applies to Page modules:

        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page

          prop :filters, :map           # Warning: generic type
          prop :data, list_of(ref(ItemSerializer))  # Good: specific type
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
            prop :data, shape(key: :string, value: :number)
            # or
            prop :data, ref(DataSerializer)
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

    # Match prop declarations with generic types as second arg: `prop :name, :map`
    defp traverse({:prop, meta, [prop_name, type | _rest]} = ast, issues, issue_meta)
         when is_atom(prop_name) and type in @generic_types do
      new_issue = issue_for(issue_meta, meta[:line], prop_name, type)
      {ast, [new_issue | issues]}
    end

    # Match prop declarations with keyword syntax: `prop :name, type: :map`
    defp traverse({:prop, meta, [prop_name, opts]} = ast, issues, issue_meta)
         when is_atom(prop_name) and is_list(opts) do
      type = Keyword.get(opts, :type)

      if type in @generic_types do
        new_issue = issue_for(issue_meta, meta[:line], prop_name, type)
        {ast, [new_issue | issues]}
      else
        {ast, issues}
      end
    end

    defp traverse(ast, issues, _issue_meta), do: {ast, issues}

    defp issue_for(issue_meta, line_no, prop_name, type) do
      suggestion =
        case type do
          :map -> "shape(...) or ref(DataSerializer)"
          :list -> "list_of(:string), list_of(ref(ItemSerializer)), or type: ~TS\"ItemType[]\""
          :any -> "a specific helper type, shape(...), union(...), ref(...), or type: ~TS\"...\""
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
