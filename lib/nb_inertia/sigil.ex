defmodule NbInertia.Sigil do
  @moduledoc """
  Provides `~TSX` and `~JSX` sigils for colocating frontend components in Page modules.

  These sigils are **no-ops in Elixir** — they simply return the string content unchanged.
  The real work is done by `NbInertia.Extractor`, which finds all Page modules with
  `render/0` containing sigil content, generates a TypeScript type preamble from prop
  declarations, and writes the complete `.tsx`/`.jsx` file to `.nb_inertia/pages/`.

  ## Usage

      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, list: UserSerializer
        prop :total, :integer

        def mount(_conn, _params) do
          %{users: Accounts.list_users(), total: Accounts.count_users()}
        end

        def render do
          ~TSX\"\"\"
          export default function UsersIndex({ users, total }: Props) {
            return <div>{total} users</div>
          }
          \"\"\"
        end
      end

  ## ~JSX Variant

  For JavaScript projects (no TypeScript), use `~JSX` instead. Extracted files
  will use the `.jsx` extension and no type preamble will be generated.

      def render do
        ~JSX\"\"\"
        export default function UsersIndex({ users }) {
          return <div>{users.length} users</div>
        }
        \"\"\"
      end
  """

  @doc """
  TSX sigil for colocated React/TypeScript components.

  Returns the string content unchanged. The extraction pipeline
  (`NbInertia.Extractor`) processes the content at compile time
  to generate `.tsx` files with type preambles.
  """
  defmacro sigil_TSX({:<<>>, _meta, [content]}, _modifiers) when is_binary(content) do
    content
  end

  defmacro sigil_TSX({:<<>>, _meta, _pieces} = content, _modifiers) do
    quote do
      unquote(content)
    end
  end

  @doc """
  JSX sigil for colocated React/JavaScript components.

  Returns the string content unchanged. The extraction pipeline
  (`NbInertia.Extractor`) processes the content at compile time
  to generate `.jsx` files without type preambles.
  """
  defmacro sigil_JSX({:<<>>, _meta, [content]}, _modifiers) when is_binary(content) do
    content
  end

  defmacro sigil_JSX({:<<>>, _meta, _pieces} = content, _modifiers) do
    quote do
      unquote(content)
    end
  end
end
