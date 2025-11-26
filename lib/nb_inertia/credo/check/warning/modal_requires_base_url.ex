defmodule NbInertia.Credo.Check.Warning.ModalRequiresBaseUrl do
  @moduledoc """
  Warns when `render_inertia_modal/3` or `render_inertia_modal/4` is called
  without the required `:base_url` option.

  The `:base_url` option is required for modals to function correctly. It specifies
  the URL of the page "behind" the modal, which is used when the modal is closed.

  ## Example

  Instead of:

      def show(conn, %{"id" => id}) do
        user = Accounts.get_user!(id)
        render_inertia_modal(conn, :user_details, user: user)  # Missing base_url!
      end

  Use:

      def show(conn, %{"id" => id}) do
        user = Accounts.get_user!(id)
        render_inertia_modal(conn, :user_details,
          [user: user],
          base_url: "/users"
        )
      end

  Or with nb_routes:

      def show(conn, %{"id" => id}) do
        user = Accounts.get_user!(id)
        render_inertia_modal(conn, :user_details,
          [user: user],
          base_url: users_path()
        )
      end

  """
  use Credo.Check,
    id: "EX5003",
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      The `render_inertia_modal/3,4` function requires a `:base_url` option.

      The base_url specifies where to navigate when the modal is closed.
      Without it, modal behavior will be incorrect.

      Add the base_url option:
          render_inertia_modal(conn, :page, [props], base_url: "/path")

      Or use nb_routes:
          render_inertia_modal(conn, :page, [props], base_url: some_path())
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

  # Match `render_inertia_modal(conn, page, props)` - 3 args without base_url
  defp traverse(
         {:render_inertia_modal, meta, [_conn, _page, props]} = ast,
         issues,
         issue_meta
       )
       when is_list(props) do
    if has_base_url?(props) do
      {ast, issues}
    else
      new_issue = issue_for(issue_meta, meta[:line])
      {ast, [new_issue | issues]}
    end
  end

  # Match `render_inertia_modal(conn, page, props, opts)` - 4 args, check opts for base_url
  defp traverse(
         {:render_inertia_modal, meta, [_conn, _page, _props, opts]} = ast,
         issues,
         issue_meta
       )
       when is_list(opts) do
    if has_base_url?(opts) do
      {ast, issues}
    else
      new_issue = issue_for(issue_meta, meta[:line])
      {ast, [new_issue | issues]}
    end
  end

  # Match `render_inertia_modal(conn, page)` - missing both props and base_url
  defp traverse(
         {:render_inertia_modal, meta, [_conn, _page]} = ast,
         issues,
         issue_meta
       ) do
    new_issue = issue_for(issue_meta, meta[:line])
    {ast, [new_issue | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  # Check if keyword list contains :base_url key
  # In AST, keyword list items are tuples: {:key, value}
  # The key is always an atom in keyword syntax
  defp has_base_url?(opts) when is_list(opts) do
    Enum.any?(opts, fn
      {:base_url, _value} -> true
      _ -> false
    end)
  end

  defp has_base_url?(_), do: false

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "`render_inertia_modal` requires the `:base_url` option.",
      trigger: "render_inertia_modal",
      line_no: line_no
    )
  end
end
