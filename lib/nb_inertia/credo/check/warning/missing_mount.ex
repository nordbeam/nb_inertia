# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.MissingMount do
    @moduledoc """
    Warns when a Page module using `use NbInertia.Page` does not define a `mount/2` callback.

    The `mount/2` callback is required for Page modules. While this is also enforced
    at compile time by `__before_compile__`, having a Credo check provides earlier
    feedback in editors and CI pipelines before compilation.

    ## Example

    Instead of:

        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page

          prop :users, :list
          # Missing mount/2!
        end

    Define the required callback:

        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page

          prop :users, :list

          def mount(_conn, _params) do
            %{users: Accounts.list_users()}
          end
        end

    """
    use Credo.Check,
      id: "EX5030",
      base_priority: :high,
      category: :warning,
      explanations: [
        check: """
        Page modules using `use NbInertia.Page` must define a `mount/2` callback.

        The `mount/2` callback initializes props for GET requests. Without it,
        the page cannot render.

        Example:
            defmodule MyAppWeb.UsersPage.Index do
              use NbInertia.Page

              prop :users, :list

              def mount(_conn, _params) do
                %{users: Accounts.list_users()}
              end
            end
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
        has_mount: false
      }

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)

      # Check last module at end of file
      check_module(final_state)
    end

    # Track module definition
    defp traverse({:defmodule, meta, [{:__aliases__, _, parts} | _]} = ast, state) do
      # Check previous module first
      state = maybe_add_issue(state)

      module_name = Module.concat(parts)

      {ast,
       %{
         state
         | current_module: module_name,
           module_line: meta[:line],
           has_use_page: false,
           has_mount: false
       }}
    end

    # Track `use NbInertia.Page`
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Page]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_use_page: true}}
    end

    # Track `def mount(...)` with 2 args
    defp traverse({:def, _meta, [{:mount, _, args} | _]} = ast, state)
         when is_list(args) and length(args) == 2 do
      {ast, %{state | has_mount: true}}
    end

    defp traverse(ast, state), do: {ast, state}

    defp maybe_add_issue(state) do
      if state.has_use_page and not state.has_mount and state.current_module != nil do
        issue = issue_for(state.issue_meta, state.module_line, state.current_module)
        %{state | issues: [issue | state.issues]}
      else
        state
      end
    end

    defp check_module(state) do
      issues =
        if state.has_use_page and not state.has_mount and state.current_module != nil do
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
          "`#{inspect(module_name)}` uses `NbInertia.Page` but does not define `mount/2`. Page modules must define a `mount/2` callback.",
        trigger: "defmodule",
        line_no: line_no
      )
    end
  end
end
