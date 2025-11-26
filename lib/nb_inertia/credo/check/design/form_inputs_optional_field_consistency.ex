# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Design.FormInputsOptionalFieldConsistency do
    @moduledoc """
    Warns when `form_inputs` blocks have inconsistent optional fields between
    create and edit variants or when optional fields are marked inconsistently.

    ## Example

    Instead of:

        defmodule MyAppWeb.ItemsController do
          use NbInertia.Controller

          # Create form - name is required
          form_inputs :create_item do
            input :name, :string
            input :description, :string, optional: true
          end

          # Edit form - name is optional (inconsistent!)
          form_inputs :edit_item do
            input :name, :string, optional: true
            input :description, :string, optional: true
          end
        end

    Use consistent optional fields across related forms.

    """
    use Credo.Check,
      id: "EX5017",
      base_priority: :low,
      category: :design,
      explanations: [
        check: """
        Related form_inputs blocks (create/edit pairs) should have consistent
        optional field declarations.

        If a field is required in the create form, it should typically be
        required in the edit form as well, unless there's a specific reason
        for the difference.

        This check looks for form_inputs blocks with similar names
        (e.g., create_item/edit_item) and warns about optional field
        inconsistencies.
        """
      ]

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)

      initial_state = %{
        issue_meta: issue_meta,
        issues: [],
        form_inputs: %{},
        current_form: nil
      }

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)

      # Check for inconsistencies after collecting all form_inputs
      check_inconsistencies(final_state)
    end

    # Track form_inputs declaration
    defp traverse({:form_inputs, meta, [form_name | rest]} = ast, state)
         when is_atom(form_name) do
      inputs = extract_inputs_from_block(rest)
      form_data = %{line: meta[:line], inputs: inputs}
      new_forms = Map.put(state.form_inputs, form_name, form_data)
      {ast, %{state | form_inputs: new_forms}}
    end

    defp traverse(ast, state), do: {ast, state}

    defp extract_inputs_from_block(rest) do
      Enum.flat_map(rest, fn
        [do: {:__block__, _, statements}] ->
          extract_input_fields(statements)

        [do: statement] ->
          extract_input_fields([statement])

        [{:do, {:__block__, _, statements}} | _] ->
          extract_input_fields(statements)

        [{:do, statement} | _] ->
          extract_input_fields([statement])

        _ ->
          []
      end)
    end

    defp extract_input_fields(statements) do
      Enum.flat_map(statements, fn
        {:input, _, [name, _type | opts_rest]} when is_atom(name) ->
          opts = List.first(opts_rest) || []
          optional = if is_list(opts), do: Keyword.get(opts, :optional, false), else: false
          [%{name: name, optional: optional}]

        _ ->
          []
      end)
    end

    defp check_inconsistencies(state) do
      form_pairs = find_related_forms(Map.keys(state.form_inputs))

      issues =
        Enum.flat_map(form_pairs, fn {create_name, edit_name} ->
          create_form = Map.get(state.form_inputs, create_name)
          edit_form = Map.get(state.form_inputs, edit_name)

          if create_form && edit_form do
            find_inconsistent_fields(
              state.issue_meta,
              create_name,
              create_form,
              edit_name,
              edit_form
            )
          else
            []
          end
        end)

      Enum.reverse(issues ++ state.issues)
    end

    # Find create/edit pairs based on naming convention
    defp find_related_forms(form_names) do
      form_names
      |> Enum.filter(&String.starts_with?(to_string(&1), "create_"))
      |> Enum.flat_map(fn create_name ->
        base_name = String.replace_prefix(to_string(create_name), "create_", "")
        edit_name = String.to_atom("edit_#{base_name}")

        if edit_name in form_names do
          [{create_name, edit_name}]
        else
          []
        end
      end)
    end

    defp find_inconsistent_fields(issue_meta, create_name, create_form, edit_name, edit_form) do
      create_fields = Map.new(create_form.inputs, &{&1.name, &1.optional})
      edit_fields = Map.new(edit_form.inputs, &{&1.name, &1.optional})

      # Find fields that exist in both but have different optional status
      common_fields =
        MapSet.intersection(
          MapSet.new(Map.keys(create_fields)),
          MapSet.new(Map.keys(edit_fields))
        )

      Enum.flat_map(common_fields, fn field_name ->
        create_optional = Map.get(create_fields, field_name)
        edit_optional = Map.get(edit_fields, field_name)

        if create_optional != edit_optional do
          [
            format_issue(
              issue_meta,
              message:
                "Field `:#{field_name}` has inconsistent optional status: `#{create_name}` (optional: #{create_optional}) vs `#{edit_name}` (optional: #{edit_optional}).",
              trigger: "form_inputs",
              line_no: edit_form.line
            )
          ]
        else
          []
        end
      end)
    end
  end
end
