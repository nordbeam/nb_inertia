# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.ModalWithoutBaseUrl do
    @moduledoc """
    Warns when the `modal` macro is used in a Page module without the
    required `base_url` option.

    The `base_url` specifies where to navigate when the modal is closed.
    Without it, modal behavior will be incorrect.

    Note: This check is for the `modal` macro in Page modules. The existing
    `ModalRequiresBaseUrl` check covers `render_inertia_modal/3,4` in controllers.

    ## Example

    Instead of:

        defmodule MyAppWeb.UsersPage.Show do
          use NbInertia.Page

          modal size: :lg, position: :center  # Missing base_url!

          def mount(conn, %{"id" => id}) do
            %{user: Accounts.get_user!(id)}
          end
        end

    Provide the base_url:

        defmodule MyAppWeb.UsersPage.Show do
          use NbInertia.Page

          modal base_url: "/users", size: :lg, position: :center

          def mount(conn, %{"id" => id}) do
            %{user: Accounts.get_user!(id)}
          end
        end

    Or set it dynamically in mount/2:

        defmodule MyAppWeb.UsersPage.Show do
          use NbInertia.Page

          modal size: :lg

          def mount(conn, %{"id" => id}) do
            conn
            |> modal_config(base_url: ~p"/users/\#{id}")
            |> props(%{user: Accounts.get_user!(id)})
          end
        end

    """
    use Credo.Check,
      id: "EX5034",
      base_priority: :high,
      category: :warning,
      explanations: [
        check: """
        The `modal` macro in Page modules requires a `:base_url` option,
        unless it is set dynamically via `modal_config/2` in `mount/2`.

        The base_url specifies the URL to navigate to when the modal is closed.
        Without it, the modal cannot properly handle close behavior.

        Either provide it statically:
            modal base_url: "/users", size: :lg

        Or dynamically in mount/2:
            def mount(conn, %{"id" => id}) do
              conn
              |> modal_config(base_url: ~p"/users/\#{id}")
              |> props(%{user: get_user!(id)})
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
        has_use_page: false,
        has_modal: false,
        modal_has_base_url: false,
        modal_line: nil,
        has_dynamic_modal_config: false
      }

      final_state = Credo.Code.prewalk(source_file, &traverse(&1, &2), initial_state)

      check_final(final_state)
    end

    # Track `use NbInertia.Page`
    defp traverse(
           {:use, _meta, [{:__aliases__, _, [:NbInertia, :Page]} | _]} = ast,
           state
         ) do
      {ast, %{state | has_use_page: true}}
    end

    # Track `modal opts` macro call
    defp traverse({:modal, meta, [opts]} = ast, state) when is_list(opts) do
      has_base_url = Keyword.has_key?(opts, :base_url)

      {ast,
       %{
         state
         | has_modal: true,
           modal_has_base_url: has_base_url,
           modal_line: meta[:line]
       }}
    end

    # Track `modal_config(conn, ...)` call in mount — indicates dynamic base_url
    defp traverse({:modal_config, _meta, _args} = ast, state) do
      {ast, %{state | has_dynamic_modal_config: true}}
    end

    defp traverse(ast, state), do: {ast, state}

    defp check_final(state) do
      if state.has_use_page and state.has_modal and not state.modal_has_base_url and
           not state.has_dynamic_modal_config do
        [issue_for(state.issue_meta, state.modal_line)]
      else
        []
      end
    end

    defp issue_for(issue_meta, line_no) do
      format_issue(
        issue_meta,
        message:
          "`modal` macro is missing the `:base_url` option. Provide `base_url: \"/path\"` or set it dynamically with `modal_config/2` in `mount/2`.",
        trigger: "modal",
        line_no: line_no
      )
    end
  end
end
