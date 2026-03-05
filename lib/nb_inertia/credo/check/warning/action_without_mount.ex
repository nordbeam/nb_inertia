# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.ActionWithoutMount do
    @moduledoc """
    Warns when a Page module defines `action/3` without `mount/2`.

    While compile-time checks enforce that `mount/2` must exist, this Credo check
    catches partial work-in-progress where `action/3` has been written but `mount/2`
    has not yet been added. This provides earlier feedback in editors.

    ## Example

    Instead of:

        defmodule MyAppWeb.UsersPage.Create do
          use NbInertia.Page

          prop :user, UserSerializer

          # Has action/3 but no mount/2!
          def action(conn, params, :create) do
            case Accounts.create_user(params) do
              {:ok, user} -> redirect(conn, to: "/users")
              {:error, changeset} -> {:error, changeset}
            end
          end
        end

    Also define mount/2:

        defmodule MyAppWeb.UsersPage.Create do
          use NbInertia.Page

          prop :user, UserSerializer

          def mount(_conn, _params) do
            %{user: %User{}}
          end

          def action(conn, params, :create) do
            case Accounts.create_user(params) do
              {:ok, user} -> redirect(conn, to: "/users")
              {:error, changeset} -> {:error, changeset}
            end
          end
        end

    """
    use Credo.Check,
      id: "EX5031",
      base_priority: :high,
      category: :warning,
      explanations: [
        check: """
        Page modules that define `action/3` must also define `mount/2`.

        The `mount/2` callback handles GET requests and is required for all
        Page modules. The `action/3` callback handles mutations (POST, PUT,
        PATCH, DELETE) and is optional, but it cannot exist without `mount/2`.

        If you see this warning, you likely need to add the `mount/2` callback.
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
        has_mount: false,
        has_action: false,
        action_line: nil
      }

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)

      # Check last module at end of file
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
           has_mount: false,
           has_action: false,
           action_line: nil
       }}
    end

    # Track `use NbInertia.Page`
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Page]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_use_page: true}}
    end

    # Track `def mount(_, _)` with 2 args
    defp traverse({:def, _meta, [{:mount, _, args} | _]} = ast, state)
         when is_list(args) and length(args) == 2 do
      {ast, %{state | has_mount: true}}
    end

    # Track `def action(_, _, _)` with 3 args
    defp traverse({:def, meta, [{:action, _, args} | _]} = ast, state)
         when is_list(args) and length(args) == 3 do
      {ast, %{state | has_action: true, action_line: meta[:line]}}
    end

    defp traverse(ast, state), do: {ast, state}

    defp maybe_add_issue(state) do
      if should_report?(state) do
        issue = issue_for(state.issue_meta, state.action_line, state.current_module)
        %{state | issues: [issue | state.issues]}
      else
        state
      end
    end

    defp check_module(state) do
      issues =
        if should_report?(state) do
          [issue_for(state.issue_meta, state.action_line, state.current_module) | state.issues]
        else
          state.issues
        end

      Enum.reverse(issues)
    end

    defp should_report?(state) do
      state.has_use_page and state.has_action and not state.has_mount and
        state.current_module != nil
    end

    defp issue_for(issue_meta, line_no, module_name) do
      format_issue(
        issue_meta,
        message:
          "`#{inspect(module_name)}` defines `action/3` but not `mount/2`. Page modules must define `mount/2` before `action/3`.",
        trigger: "action",
        line_no: line_no
      )
    end
  end
end
