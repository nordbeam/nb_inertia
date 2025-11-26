defmodule NbInertia.Credo.Check.Warning.AvoidRawInertiaRender do
  @moduledoc """
  Warns when using `Inertia.Controller.render_inertia/3` directly.

  When using nb_inertia, you should use the `render_inertia/3` function provided
  by `NbInertia.Controller` (via `use NbInertia.Controller`) instead of calling
  the base Inertia library functions directly.

  The nb_inertia version provides:
  - Atom-based page references with automatic component name lookup
  - Compile-time prop validation
  - Automatic shared props injection
  - SSR support integration
  - Telemetry events

  ## Example

  Instead of:

      def index(conn, _params) do
        Inertia.Controller.render_inertia(conn, "Users/Index", %{users: users})
      end

  Use:

      inertia_page :users_index do
        prop :users, :list
      end

      def index(conn, _params) do
        render_inertia(conn, :users_index, users: list_users())
      end

  """
  use Credo.Check,
    id: "EX5002",
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      Calling `Inertia.Controller.render_inertia/3` directly bypasses nb_inertia's
      enhanced rendering pipeline.

      Instead of:
          Inertia.Controller.render_inertia(conn, "Component", %{...})

      Use the imported version from NbInertia.Controller:
          render_inertia(conn, :page_name, prop: value)

      This requires:
      1. Adding `use NbInertia.Controller` to your controller
      2. Declaring pages with `inertia_page :page_name do ... end`
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

  # Match `Inertia.Controller.render_inertia(...)`
  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Inertia, :Controller]}, :render_inertia]}, _call_meta,
          _args} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "Inertia.Controller.render_inertia")
    {ast, [new_issue | issues]}
  end

  # Match `Inertia.render_inertia(...)` (aliased)
  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Inertia]}, :render_inertia]}, _call_meta, _args} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line], "Inertia.render_inertia")
    {ast, [new_issue | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message:
        "Use the imported `render_inertia/3` from NbInertia.Controller instead of `#{trigger}`.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
