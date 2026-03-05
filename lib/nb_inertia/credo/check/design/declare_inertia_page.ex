# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Design.DeclareInertiaPage do
    @moduledoc """
    Warns when using `render_inertia/3` with an atom page reference in a controller
    that doesn't appear to have `use NbInertia.Controller`.

    Also recognizes `use NbInertia.Page` as a valid pattern — Page modules
    with `prop` declarations are valid Inertia page declarations.

    When using nb_inertia's atom-based page references (e.g., `:users_index`),
    you must:
    1. Add `use NbInertia.Controller` to your controller
    2. Declare the page using `inertia_page :page_name do ... end`

    Or use the Page module pattern:
    1. Add `use NbInertia.Page` to the module
    2. Declare props using `prop :name, :type`

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

      # Single pass: collect module info and check render_inertia calls
      # We track module scopes to handle files with multiple modules correctly
      initial_state = %{
        issue_meta: issue_meta,
        issues: [],
        # Stack of module contexts (innermost module first)
        module_stack: [],
        # Current module's info
        current_module: nil,
        has_nb_inertia_controller: false,
        has_nb_inertia_page: false,
        declared_pages: MapSet.new()
      }

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)
      Enum.reverse(final_state.issues)
    end

    # Enter a new module - push current state to stack and reset
    defp traverse({:defmodule, _meta, [{:__aliases__, _, module_parts} | _]} = ast, state) do
      module_name = Module.concat(module_parts)

      # Save current module state to stack if we're inside a module
      new_stack =
        if state.current_module do
          [
            %{
              module: state.current_module,
              has_nb_inertia_controller: state.has_nb_inertia_controller,
              has_nb_inertia_page: state.has_nb_inertia_page,
              declared_pages: state.declared_pages
            }
            | state.module_stack
          ]
        else
          state.module_stack
        end

      new_state = %{
        state
        | current_module: module_name,
          module_stack: new_stack,
          has_nb_inertia_controller: false,
          has_nb_inertia_page: false,
          declared_pages: MapSet.new()
      }

      {ast, new_state}
    end

    # Track `use NbInertia.Controller`
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Controller]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_nb_inertia_controller: true}}
    end

    # Track `use NbInertia.Page` — Page modules are valid Inertia page declarations
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Page]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_nb_inertia_page: true}}
    end

    # Track `inertia_page :name do ... end`
    # Also infer NbInertia.Controller is present, since inertia_page is only
    # available through it (handles wrappers like `use MyAppWeb, :inertia_controller`)
    defp traverse({:inertia_page, _meta, [page_name | _]} = ast, state)
         when is_atom(page_name) do
      {ast,
       %{
         state
         | has_nb_inertia_controller: true,
           declared_pages: MapSet.put(state.declared_pages, page_name)
       }}
    end

    # Check render_inertia calls with atom page references
    defp traverse(
           {:render_inertia, meta, [_conn, page_name | _rest]} = ast,
           state
         )
         when is_atom(page_name) do
      cond do
        # Skip check for Page modules — they use mount/2, not render_inertia
        state.has_nb_inertia_page ->
          {ast, state}

        # If the module doesn't have NbInertia.Controller, warn
        not state.has_nb_inertia_controller ->
          new_issue = issue_for_missing_use(state.issue_meta, meta[:line], page_name)
          {ast, %{state | issues: [new_issue | state.issues]}}

        # If the page isn't declared, warn
        not MapSet.member?(state.declared_pages, page_name) ->
          new_issue = issue_for_undeclared_page(state.issue_meta, meta[:line], page_name)
          {ast, %{state | issues: [new_issue | state.issues]}}

        true ->
          {ast, state}
      end
    end

    defp traverse(ast, state) do
      {ast, state}
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
end
