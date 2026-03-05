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

  describe "sigils in Page module context" do
    defmodule SigilPage do
      use NbInertia.Page, component: "Test/Sigil"

      prop(:name, :string)

      def mount(_conn, _params) do
        %{name: "test"}
      end

      def render do
        ~TSX"""
        export default function SigilTest({ name }: Props) {
          return <h1>{name}</h1>
        }
        """
      end
    end

    defmodule JsxSigilPage do
      use NbInertia.Page, component: "Test/JsxSigil"

      prop(:name, :string)

      def mount(_conn, _params) do
        %{name: "test"}
      end

      def render do
        ~JSX"""
        export default function JsxTest({ name }) {
          return <h1>{name}</h1>
        }
        """
      end
    end

    test "~TSX works inside render/0 in a Page module" do
      result = SigilPage.render()
      assert result =~ "export default function SigilTest"
      assert result =~ "{name}"
    end

    test "~JSX works inside render/0 in a Page module" do
      result = JsxSigilPage.render()
      assert result =~ "export default function JsxTest"
    end

    test "Page module with render/0 reports __inertia_has_render__ as true" do
      assert SigilPage.__inertia_has_render__() == true
      assert JsxSigilPage.__inertia_has_render__() == true
    end
  end
end
