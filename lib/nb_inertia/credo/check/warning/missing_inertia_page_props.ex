# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.MissingInertiaPageProps do
    @moduledoc """
    Warns when `render_inertia/3` passes props that aren't declared in the
    corresponding `inertia_page` block.

    When using nb_inertia's declarative page DSL, all props should be declared
    in the `inertia_page` block for type safety, documentation, and maintainability.

    ## Example

    Instead of:

        inertia_page :show do
          prop :user, UserSerializer
        end

        def show(conn, params) do
          render_inertia(conn, :show,
            user: user,
            extra_field: data  # Not declared!
          )
        end

    Use:

        inertia_page :show do
          prop :user, UserSerializer
          prop :extra_field, :string
        end

        def show(conn, params) do
          render_inertia(conn, :show,
            user: user,
            extra_field: data
          )
        end

    """
    use Credo.Check,
      id: "EX5010",
      base_priority: :high,
      category: :warning,
      explanations: [
        check: """
        All props passed to `render_inertia/3` should be declared in the
        corresponding `inertia_page` block.

        This ensures:
        - Type safety with TypeScript generation
        - Clear documentation of page contracts
        - Compile-time validation of props

        Declare all props in your `inertia_page` block:
            inertia_page :page_name do
              prop :my_prop, :string
            end
        """
      ]

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)

      # Collect declared props per page
      initial_state = %{
        issue_meta: issue_meta,
        issues: [],
        declared_props: %{},
        current_page: nil
      }

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)
      Enum.reverse(final_state.issues)
    end

    # Track inertia_page declarations and their props
    defp traverse({:inertia_page, _meta, [page_name | rest]} = ast, state)
         when is_atom(page_name) do
      # Extract props from the do block
      props = extract_props_from_page(rest)
      new_declared = Map.put(state.declared_props, page_name, props)
      {ast, %{state | declared_props: new_declared}}
    end

    # Check render_inertia calls
    defp traverse(
           {:render_inertia, meta, [_conn, page_name, props_kwlist | _]} = ast,
           state
         )
         when is_atom(page_name) and is_list(props_kwlist) do
      declared = Map.get(state.declared_props, page_name, nil)

      if declared do
        # Check for undeclared props
        rendered_props = extract_rendered_prop_names(props_kwlist)
        undeclared = rendered_props -- declared

        if Enum.empty?(undeclared) do
          {ast, state}
        else
          new_issues =
            Enum.map(undeclared, fn prop_name ->
              issue_for(state.issue_meta, meta[:line], page_name, prop_name)
            end)

          {ast, %{state | issues: new_issues ++ state.issues}}
        end
      else
        # No inertia_page declaration found - skip (covered by DeclareInertiaPage check)
        {ast, state}
      end
    end

    defp traverse(ast, state), do: {ast, state}

    # Extract prop names from inertia_page do block
    defp extract_props_from_page(rest) do
      Enum.flat_map(rest, fn
        [do: {:__block__, _, statements}] ->
          extract_prop_names(statements)

        [do: statement] ->
          extract_prop_names([statement])

        [{:do, {:__block__, _, statements}} | _] ->
          extract_prop_names(statements)

        [{:do, statement} | _] ->
          extract_prop_names([statement])

        _ ->
          []
      end)
    end

    defp extract_prop_names(statements) do
      Enum.flat_map(statements, fn
        {:prop, _, [name | _]} when is_atom(name) -> [name]
        _ -> []
      end)
    end

    # Extract prop names from render_inertia call
    defp extract_rendered_prop_names(props_kwlist) do
      Enum.flat_map(props_kwlist, fn
        {name, _value} when is_atom(name) -> [name]
        _ -> []
      end)
    end

    defp issue_for(issue_meta, line_no, page_name, prop_name) do
      format_issue(
        issue_meta,
        message:
          "Prop `:#{prop_name}` is not declared in `inertia_page :#{page_name}`. Add `prop :#{prop_name}, <type>` to the page declaration.",
        trigger: "render_inertia",
        line_no: line_no
      )
    end
  end
end
