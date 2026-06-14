defmodule NbInertia.Sigil do
  @moduledoc """
  Provides `~TSX` and `~JSX` sigils for embedding frontend snippets in Elixir code.

  These sigils are **no-ops in Elixir**: they return the string content unchanged.

  ## Usage

      import NbInertia.Sigil

      snippet = ~TSX\"\"\"
      export default function UsersIndex({ users }) {
        return <div>{users.length} users</div>
      }
      \"\"\"

  ## ~JSX Variant

  For JavaScript snippets, use `~JSX` instead.

      snippet = ~JSX\"\"\"
      export default function UsersIndex({ users }) {
        return <div>{users.length} users</div>
      }
      \"\"\"
  """

  @doc """
  TSX sigil that returns the string content unchanged.
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
  JSX sigil that returns the string content unchanged.
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
