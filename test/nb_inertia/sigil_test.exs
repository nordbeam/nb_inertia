defmodule NbInertia.SigilTest do
  use ExUnit.Case, async: true

  import NbInertia.Sigil

  describe "~TSX sigil" do
    test "returns string content" do
      result = ~TSX"""
      export default function App() { return <div>Hello</div> }
      """

      assert result == "export default function App() { return <div>Hello</div> }\n"
    end

    test "preserves multiline content" do
      result = ~TSX"""
      import { useState } from 'react'

      export default function Counter() {
        const [count, setCount] = useState(0)
        return (
          <button onClick={() => setCount(c => c + 1)}>
            Count: {count}
          </button>
        )
      }
      """

      assert result =~ "import { useState } from 'react'"
      assert result =~ "const [count, setCount] = useState(0)"
      assert result =~ "Count: {count}"
    end

    test "preserves special characters" do
      result = ~TSX"""
      const x = 'hello & "world"'
      const y = `template ${literal}`
      """

      assert result =~ ~S(const x = 'hello & "world"')
      assert result =~ "const y = `template ${literal}`"
    end

    test "handles empty content" do
      result = ~TSX"""
      """

      assert result == ""
    end

    test "handles single-line heredoc" do
      result = ~TSX"""
      export default function Empty() { return null }
      """

      assert result == "export default function Empty() { return null }\n"
    end
  end

  describe "~JSX sigil" do
    test "returns string content" do
      result = ~JSX"""
      export default function App() { return <div>Hello</div> }
      """

      assert result == "export default function App() { return <div>Hello</div> }\n"
    end

    test "preserves multiline content" do
      result = ~JSX"""
      import { useState } from 'react'

      export default function Counter() {
        const [count, setCount] = useState(0)
        return <div>{count}</div>
      }
      """

      assert result =~ "import { useState } from 'react'"
      assert result =~ "export default function Counter()"
    end
  end

  defmodule SnippetContainer do
    import NbInertia.Sigil

    def tsx_snippet do
      ~TSX"""
      export default function SigilTest({ name }: Props) {
        return <h1>{name}</h1>
      }
      """
    end

    def jsx_snippet do
      ~JSX"""
      export default function JsxTest({ name }) {
        return <h1>{name}</h1>
      }
      """
    end
  end

  describe "sigils in module functions" do
    test "~TSX works in a regular function" do
      result = SnippetContainer.tsx_snippet()
      assert result =~ "export default function SigilTest"
      assert result =~ "{name}"
    end

    test "~JSX works in a regular function" do
      result = SnippetContainer.jsx_snippet()
      assert result =~ "export default function JsxTest"
    end
  end
end
