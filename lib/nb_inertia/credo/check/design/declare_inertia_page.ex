defmodule NbInertia.Credo.Check.Design.DeclareInertiaPage do
  @moduledoc """
  Warns when using `render_inertia/3` with an atom page reference in a controller
  that doesn't appear to have `use NbInertia.Controller`.

  When using nb_inertia's atom-based page references (e.g., `:users_index`),
  you must:
  1. Add `use NbInertia.Controller` to your controller
  2. Declare the page using `inertia_page :page_name do ... end`

  ## Example

  Instead of:

      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        # Missing: use NbInertia.Controller

        def index(conn, _params) do
          render_inertia(conn, :users_index, users: users)  # Will fail at runtime!
        end
      end

  Use:

      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
        end

        def index(conn, _params) do
          render_inertia(conn, :users_index, users: list_users())
        end
      end

  """
  use Credo.Check,
    id: "EX5005",
    base_priority: :normal,
    category: :design,
    explanations: [
      check: """
      When using atom-based page references with `render_inertia/3`, ensure:

      1. Your controller has `use NbInertia.Controller`
      2. You've declared the page with `inertia_page :page_name do ... end`

      This enables:
      - Compile-time prop validation
      - Automatic component name inference
      - TypeScript type generation (with nb_ts)

      Example:
          defmodule MyController do
            use NbInertia.Controller

            inertia_page :my_page do
              prop :data, :map
            end

            def action(conn, _params) do
              render_inertia(conn, :my_page, data: %{})
            end
          end
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    # First pass: collect module info
    module_info = collect_module_info(source_file)

    # Second pass: check render_inertia calls
    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, {issue_meta, module_info}))
    |> Enum.reverse()
  end

  # Collect information about modules in the file
  defp collect_module_info(source_file) do
    source_file
    |> Credo.Code.prewalk(&collect_info(&1, &2), %{
      has_nb_inertia_controller: false,
      declared_pages: MapSet.new(),
      current_module: nil
    })
  end

  # Track `use NbInertia.Controller`
  defp collect_info(
         {:use, _meta, [{:__aliases__, _, [:NbInertia, :Controller]} | _]} = ast,
         acc
       ) do
    {ast, %{acc | has_nb_inertia_controller: true}}
  end

  # Track `inertia_page :name do ... end`
  defp collect_info({:inertia_page, _meta, [page_name | _]} = ast, acc)
       when is_atom(page_name) do
    {ast, %{acc | declared_pages: MapSet.put(acc.declared_pages, page_name)}}
  end

  defp collect_info(ast, acc), do: {ast, acc}

  # Check render_inertia calls with atom page references
  defp traverse(
         {:render_inertia, meta, [_conn, page_name | _rest]} = ast,
         issues,
         {issue_meta, module_info}
       )
       when is_atom(page_name) do
    cond do
      # If the module doesn't have NbInertia.Controller, warn
      not module_info.has_nb_inertia_controller ->
        new_issue = issue_for_missing_use(issue_meta, meta[:line], page_name)
        {ast, [new_issue | issues]}

      # If the page isn't declared, warn
      not MapSet.member?(module_info.declared_pages, page_name) ->
        new_issue = issue_for_undeclared_page(issue_meta, meta[:line], page_name)
        {ast, [new_issue | issues]}

      true ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _context) do
    {ast, issues}
  end

  defp issue_for_missing_use(issue_meta, line_no, page_name) do
    format_issue(
      issue_meta,
      message:
        "Using atom page reference `:#{page_name}` requires `use NbInertia.Controller` in this module.",
      trigger: "render_inertia",
      line_no: line_no
    )
  end

  defp issue_for_undeclared_page(issue_meta, line_no, page_name) do
    format_issue(
      issue_meta,
      message:
        "Page `:#{page_name}` is not declared. Add `inertia_page :#{page_name} do ... end` to this controller.",
      trigger: "render_inertia",
      line_no: line_no
    )
  end
end
