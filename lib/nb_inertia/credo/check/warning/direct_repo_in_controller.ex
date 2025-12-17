# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.DirectRepoInController do
    @moduledoc """
    Warns when controllers call Repo functions directly instead of using context modules.

    Controllers should delegate data access to context modules (like `Accounts`, `Catalog`)
    rather than calling `Repo` directly. This maintains proper separation of concerns
    and makes the codebase more maintainable.

    ## Example

    Instead of:

        def show(conn, %{"id" => id}) do
          user = Repo.get!(User, id)
          render_inertia(conn, :show, user: {UserSerializer, user})
        end

    Use:

        def show(conn, %{"id" => id}) do
          user = Accounts.get_user!(id)
          render_inertia(conn, :show, user: {UserSerializer, user})
        end

    """
    use Credo.Check,
      id: "EX5020",
      base_priority: :normal,
      category: :warning,
      explanations: [
        check: """
        Controllers should not call Repo directly. Instead, use context modules
        (like `Accounts`, `Catalog`) to access data.

        This ensures:
        - Proper separation of concerns
        - Reusable business logic
        - Easier testing
        - Consistent data access patterns

        Instead of:
            user = Repo.get!(User, id)

        Use:
            user = Accounts.get_user!(id)
        """
      ]

    @repo_functions ~w(get get! get_by get_by! one one! all insert insert! update update! delete delete! preload aggregate exists? reload reload!)a

    @doc false
    @impl true
    def run(%SourceFile{} = source_file, params) do
      # Only check files that look like controllers
      if controller_file?(source_file.filename) do
        issue_meta = IssueMeta.for(source_file, params)

        source_file
        |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
        |> Enum.reverse()
      else
        []
      end
    end

    defp controller_file?(filename) do
      String.contains?(filename, "_controller.ex") or
        String.contains?(filename, "/controllers/")
    end

    # Match Repo.function() calls
    defp traverse(
           {{:., _, [{:__aliases__, _, module_parts}, func_name]}, meta, _args} = ast,
           issues,
           issue_meta
         )
         when func_name in @repo_functions do
      module_name = List.last(module_parts)

      if module_name == :Repo do
        new_issue = issue_for(issue_meta, meta[:line], func_name)
        {ast, [new_issue | issues]}
      else
        {ast, issues}
      end
    end

    defp traverse(ast, issues, _issue_meta), do: {ast, issues}

    defp issue_for(issue_meta, line_no, func_name) do
      format_issue(
        issue_meta,
        message:
          "Direct `Repo.#{func_name}` call in controller. Use a context module instead (e.g., `Accounts.get_user!`).",
        trigger: "Repo.#{func_name}",
        line_no: line_no
      )
    end
  end
end
