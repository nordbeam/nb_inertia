# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.MixedPageAndController do
    @moduledoc """
    Warns when both `use NbInertia.Page` and `use NbInertia.Controller` are
    used in the same module.

    Page modules and Controller modules are two distinct patterns for building
    Inertia pages. A module should use one pattern or the other, not both.

    ## Example

    Instead of:

        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page
          use NbInertia.Controller  # Conflicting!

          inertia_page :index do
            prop :users, :list
          end

          def mount(_conn, _params), do: %{users: []}
        end

    Use only one pattern:

        # Page module pattern
        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page

          prop :users, :list

          def mount(_conn, _params), do: %{users: []}
        end

        # OR Controller pattern
        defmodule MyAppWeb.UserController do
          use NbInertia.Controller

          inertia_page :index do
            prop :users, :list
          end

          def index(conn, _params) do
            render_inertia(conn, :index, users: [])
          end
        end

    """
    use Credo.Check,
      id: "EX5036",
      base_priority: :high,
      category: :warning,
      explanations: [
        check: """
        A module should use either `NbInertia.Page` or `NbInertia.Controller`,
        but not both.

        `NbInertia.Page` is the LiveView-style pattern with `mount/2` and `action/3`.
        `NbInertia.Controller` is the traditional controller pattern with `inertia_page` blocks.

        These patterns have different lifecycles and cannot coexist in one module.
        Choose one pattern based on your preference.
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
        has_use_page: false,
        has_use_controller: false
      }

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)

      check_module(final_state)
    end

    # Track module definition
    defp traverse({:defmodule, meta, [{:__aliases__, _, parts} | _]} = ast, state) do
      state = maybe_add_issue(state)

      module_name = Module.concat(parts)

      {ast,
       %{
         state
         | current_module: module_name,
           module_line: meta[:line],
           has_use_page: false,
           has_use_controller: false
       }}
    end

    # Track `use NbInertia.Page`
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Page]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_use_page: true}}
    end

    # Track `use NbInertia.Controller`
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Controller]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_use_controller: true}}
    end

    defp traverse(ast, state), do: {ast, state}

    defp maybe_add_issue(state) do
      if should_report?(state) do
        issue = issue_for(state.issue_meta, state.module_line, state.current_module)
        %{state | issues: [issue | state.issues]}
      else
        state
      end
    end

    defp check_module(state) do
      issues =
        if should_report?(state) do
          [issue_for(state.issue_meta, state.module_line, state.current_module) | state.issues]
        else
          state.issues
        end

      Enum.reverse(issues)
    end

    defp should_report?(state) do
      state.has_use_page and state.has_use_controller and state.current_module != nil
    end

    defp issue_for(issue_meta, line_no, module_name) do
      format_issue(
        issue_meta,
        message:
          "`#{inspect(module_name)}` uses both `NbInertia.Page` and `NbInertia.Controller`. Use one pattern or the other, not both.",
        trigger: "defmodule",
        line_no: line_no
      )
    end
  end
end
