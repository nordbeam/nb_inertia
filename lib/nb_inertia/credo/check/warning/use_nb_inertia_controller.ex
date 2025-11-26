# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.UseNbInertiaController do
    @moduledoc """
      Warns when using `Inertia.Controller` directly instead of `NbInertia.Controller`.

    NbInertia.Controller provides enhanced functionality including:
    - Declarative page DSL with `inertia_page` macro
    - Compile-time prop validation
    - Automatic TypeScript type generation (with nb_ts)
    - Shared props support
    - Modal rendering support

    ## Example

    Instead of:

        defmodule MyAppWeb.UserController do
          use MyAppWeb, :controller
          use Inertia.Controller  # Bad: loses nb_inertia features

          def index(conn, _params) do
            Inertia.Controller.render_inertia(conn, "Users/Index", %{users: users})
          end
        end

    Use:

        defmodule MyAppWeb.UserController do
          use MyAppWeb, :controller
          use NbInertia.Controller  # Good: enables full nb_inertia functionality

          inertia_page :users_index do
            prop :users, :list
          end

          def index(conn, _params) do
            render_inertia(conn, :users_index, users: list_users())
          end
        end

    """
    use Credo.Check,
      id: "EX5001",
      base_priority: :high,
      category: :warning,
      explanations: [
        check: """
        Using `Inertia.Controller` directly bypasses the enhanced functionality
        provided by `NbInertia.Controller`.

        Replace:
            use Inertia.Controller

        With:
            use NbInertia.Controller

        This enables:
        - Declarative page definitions with `inertia_page`
        - Compile-time prop validation
        - TypeScript type generation (with nb_ts)
        - Modal rendering support
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

    # Match `use Inertia.Controller` with or without options
    defp traverse(
           {:use, meta, [{:__aliases__, _, [:Inertia, :Controller]} | _opts]} = ast,
           issues,
           issue_meta
         ) do
      new_issue = issue_for(issue_meta, meta[:line], "Inertia.Controller")
      {ast, [new_issue | issues]}
    end

    defp traverse(ast, issues, _issue_meta) do
      {ast, issues}
    end

    defp issue_for(issue_meta, line_no, trigger) do
      format_issue(
        issue_meta,
        message: "Use `NbInertia.Controller` instead of `#{trigger}` for enhanced functionality.",
        trigger: trigger,
        line_no: line_no
      )
    end
  end
end
