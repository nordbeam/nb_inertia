# Only compile this module if Credo is available
if Code.ensure_loaded?(Credo.Check) do
  defmodule NbInertia.Credo.Check.Warning.RenderWithoutProps do
    @moduledoc """
    Warns when a Page module's `~TSX` or `~JSX` sigil references `Props`
    but no props are declared in the module.

    When a colocated component references `Props`, it expects TypeScript types
    to be generated from the Page module's prop declarations. If no props are
    declared, the generated types will be empty.

    ## Example

    Instead of:

        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page

          # No prop declarations!

          def mount(_conn, _params) do
            %{users: []}
          end

          def render do
            ~TSX\"\"\"
            export default function Index({ users }: Props) {
              return <div>{users.length}</div>;
            }
            \"\"\"
          end
        end

    Declare the props:

        defmodule MyAppWeb.UsersPage.Index do
          use NbInertia.Page

          prop :users, :list

          def mount(_conn, _params) do
            %{users: []}
          end

          def render do
            ~TSX\"\"\"
            export default function Index({ users }: Props) {
              return <div>{users.length}</div>;
            }
            \"\"\"
          end
        end

    """
    use Credo.Check,
      id: "EX5035",
      base_priority: :normal,
      category: :warning,
      explanations: [
        check: """
        When `~TSX` or `~JSX` references `Props`, the Page module should have
        prop declarations to generate proper TypeScript types.

        Without prop declarations, the `Props` type will be empty (`{}`),
        which defeats the purpose of using typed props.

        Add `prop :name, :type` declarations for all props used in the component.
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
        has_props: false,
        sigil_references_props: false,
        sigil_line: nil
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

    # Track `prop :name, ...`
    defp traverse({:prop, _meta, [prop_name | _]} = ast, state)
         when is_atom(prop_name) do
      {ast, %{state | has_props: true}}
    end

    # Track ~TSX sigil that references Props
    defp traverse({:sigil_TSX, meta, [{:<<>>, _, [content]} | _]} = ast, state)
         when is_binary(content) do
      if String.contains?(content, "Props") do
        {ast, %{state | sigil_references_props: true, sigil_line: meta[:line]}}
      else
        {ast, state}
      end
    end

    # Track ~JSX sigil that references Props
    defp traverse({:sigil_JSX, meta, [{:<<>>, _, [content]} | _]} = ast, state)
         when is_binary(content) do
      if String.contains?(content, "Props") do
        {ast, %{state | sigil_references_props: true, sigil_line: meta[:line]}}
      else
        {ast, state}
      end
    end

    defp traverse(ast, state), do: {ast, state}

    defp check_final(state) do
      if state.has_use_page and state.sigil_references_props and not state.has_props do
        [issue_for(state.issue_meta, state.sigil_line)]
      else
        []
      end
    end

    defp issue_for(issue_meta, line_no) do
      format_issue(
        issue_meta,
        message:
          "Component references `Props` but no props are declared. Add `prop :name, :type` declarations to generate proper TypeScript types.",
        trigger: "~TSX",
        line_no: line_no
      )
    end
  end
end
