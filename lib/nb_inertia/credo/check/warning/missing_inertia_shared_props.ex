# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.MissingInertiaSharedProps do
    @moduledoc """
    Warns when Inertia controllers don't declare commonly needed shared props.

    Most Inertia controllers should declare shared props for authentication,
    form errors, and UI preferences to ensure consistent behavior across pages.

    ## Example

    Instead of:

        defmodule MyAppWeb.ItemsController do
          use NbInertia.Controller

          inertia_shared(FormErrors)
          # Missing Auth and UIPreferences!

          inertia_page :index do
            prop :items, list: ItemSerializer
          end
        end

    Use:

        defmodule MyAppWeb.ItemsController do
          use NbInertia.Controller

          inertia_shared(Auth)
          inertia_shared(FormErrors)
          inertia_shared(UIPreferences)

          inertia_page :index do
            prop :items, list: ItemSerializer
          end
        end

    ## Configuration

    You can customize the expected shared props via params:

        {NbInertia.Credo.Check.Warning.MissingInertiaSharedProps, [
          expected: [Auth, FormErrors],
          exclude_modules: [MyApp.PublicController]
        ]}

    """
    use Credo.Check,
      id: "EX5013",
      base_priority: :low,
      category: :warning,
      param_defaults: [
        expected: [],
        exclude_modules: []
      ],
      explanations: [
        check: """
        Inertia controllers should declare shared props for common data
        like authentication state, form errors, and UI preferences.

        Add shared props to your controller:
            inertia_shared(Auth)
            inertia_shared(FormErrors)
            inertia_shared(UIPreferences)

        Configure expected shared props via check params.
        """,
        params: [
          expected: "List of expected shared prop module names (atoms)",
          exclude_modules: "List of controller modules to exclude from this check"
        ]
      ]

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      expected = Params.get(params, :expected, __MODULE__)
      exclude_modules = Params.get(params, :exclude_modules, __MODULE__)

      # Skip if no expected shared props configured
      if Enum.empty?(expected) do
        []
      else
        issue_meta = IssueMeta.for(source_file, params)

        initial_state = %{
          issue_meta: issue_meta,
          issues: [],
          expected: expected,
          exclude_modules: exclude_modules,
          current_module: nil,
          has_nb_inertia_controller: false,
          declared_shared: [],
          module_line: nil
        }

        final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)

        # Check at end of file if we found a controller
        check_missing_shared(final_state)
      end
    end

    # Track module definition
    defp traverse({:defmodule, meta, [{:__aliases__, _, parts} | _]} = ast, state) do
      # Check previous module first
      state = maybe_add_issues_for_previous_module(state)

      module_name = Module.concat(parts)

      {ast,
       %{
         state
         | current_module: module_name,
           module_line: meta[:line],
           has_nb_inertia_controller: false,
           declared_shared: []
       }}
    end

    # Track use NbInertia.Controller
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Controller]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_nb_inertia_controller: true}}
    end

    # Track inertia_shared declarations
    defp traverse({:inertia_shared, _meta, [{:__aliases__, _, parts} | _]} = ast, state) do
      shared_name = Module.concat(parts)
      {ast, %{state | declared_shared: [shared_name | state.declared_shared]}}
    end

    # Also handle atom-style shared props
    defp traverse({:inertia_shared, _meta, [name | _]} = ast, state) when is_atom(name) do
      {ast, %{state | declared_shared: [name | state.declared_shared]}}
    end

    defp traverse(ast, state), do: {ast, state}

    defp maybe_add_issues_for_previous_module(state) do
      if state.has_nb_inertia_controller and state.current_module do
        issues = check_missing_for_module(state)
        %{state | issues: issues ++ state.issues}
      else
        state
      end
    end

    defp check_missing_shared(state) do
      issues =
        if state.has_nb_inertia_controller and state.current_module do
          check_missing_for_module(state) ++ state.issues
        else
          state.issues
        end

      Enum.reverse(issues)
    end

    defp check_missing_for_module(state) do
      if state.current_module in state.exclude_modules do
        []
      else
        # Get just the last part of module names for comparison
        declared_names =
          Enum.map(state.declared_shared, fn
            mod when is_atom(mod) ->
              mod |> Module.split() |> List.last() |> String.to_atom()
          end)

        expected_names =
          Enum.map(state.expected, fn
            mod when is_atom(mod) ->
              mod |> to_string() |> String.split(".") |> List.last() |> String.to_atom()
          end)

        missing = expected_names -- declared_names

        Enum.map(missing, fn shared_name ->
          issue_for(state.issue_meta, state.module_line, state.current_module, shared_name)
        end)
      end
    end

    defp issue_for(issue_meta, line_no, module_name, shared_name) do
      format_issue(
        issue_meta,
        message:
          "Controller `#{inspect(module_name)}` is missing `inertia_shared(#{shared_name})`.",
        trigger: "defmodule",
        line_no: line_no
      )
    end
  end
end
