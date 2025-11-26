# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.MixedInertiaControllerType do
    @moduledoc """
    Warns when a module uses both `use MyAppWeb, :controller` and
    `use NbInertia.Controller` together, which can cause conflicts.

    ## Example

    Instead of:

        defmodule MyAppWeb.ItemsController do
          use MyAppWeb, :controller
          use NbInertia.Controller

          # ...
        end

    Use:

        defmodule MyAppWeb.ItemsController do
          use NbInertia.Controller

          # ...
        end

    Or for traditional Phoenix controllers that don't use Inertia:

        defmodule MyAppWeb.ApiController do
          use MyAppWeb, :controller

          # ...
        end

    """
    use Credo.Check,
      id: "EX5015",
      base_priority: :normal,
      category: :warning,
      explanations: [
        check: """
        A controller should use either `use MyAppWeb, :controller` OR
        `use NbInertia.Controller`, but not both together.

        `NbInertia.Controller` already includes controller functionality
        and provides the declarative page DSL. Using both can cause
        conflicts and confusion.
        """
      ]

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)

      initial_state = %{
        issue_meta: issue_meta,
        issues: [],
        current_module: nil,
        module_line: nil,
        has_use_controller: false,
        has_nb_inertia_controller: false
      }

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)

      # Check at end of file
      check_mixed_usage(final_state)
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
           has_use_controller: false,
           has_nb_inertia_controller: false
       }}
    end

    # Track use MyAppWeb, :controller
    defp traverse(
           {:use, _meta, [{:__aliases__, _, _app_web}, :controller | _]} = ast,
           state
         ) do
      {ast, %{state | has_use_controller: true}}
    end

    # Track use NbInertia.Controller
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Controller]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_nb_inertia_controller: true}}
    end

    defp traverse(ast, state), do: {ast, state}

    defp maybe_add_issues_for_previous_module(state) do
      if state.has_use_controller and state.has_nb_inertia_controller and state.current_module do
        issue = issue_for(state.issue_meta, state.module_line, state.current_module)
        %{state | issues: [issue | state.issues]}
      else
        state
      end
    end

    defp check_mixed_usage(state) do
      issues =
        if state.has_use_controller and state.has_nb_inertia_controller and state.current_module do
          [issue_for(state.issue_meta, state.module_line, state.current_module) | state.issues]
        else
          state.issues
        end

      Enum.reverse(issues)
    end

    defp issue_for(issue_meta, line_no, module_name) do
      format_issue(
        issue_meta,
        message:
          "`#{inspect(module_name)}` uses both `:controller` and `NbInertia.Controller`. Use only `NbInertia.Controller` for Inertia pages.",
        trigger: "defmodule",
        line_no: line_no
      )
    end
  end
end
