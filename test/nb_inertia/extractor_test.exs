defmodule NbInertia.ExtractorTest do
  use ExUnit.Case, async: true

  alias NbInertia.Extractor
  alias NbInertia.Extractor.Preamble

  # ══════════════════════════════════════════════════════════
  # Mock Serializer modules
  # ══════════════════════════════════════════════════════════

  defmodule UserSerializer do
    def __nb_serializer__, do: :ok
  end

  defmodule MyApp.PostSerializer do
    def __nb_serializer__, do: :ok
  end

  defmodule MyApp.API.CommentSerializer do
    def __nb_serializer__, do: :ok
  end

  # ══════════════════════════════════════════════════════════
  # Test Page Modules for Extraction
  # ══════════════════════════════════════════════════════════

  defmodule SimpleTsxPage do
    use NbInertia.Page, component: "Test/SimpleTsx"

    prop(:title, :string)
    prop(:count, :integer)

    def mount(_conn, _params) do
      %{title: "Hello", count: 42}
    end

    def render do
      ~TSX"""
      export default function SimpleTsx({ title, count }: Props) {
        return <div>{title}: {count}</div>
      }
      """
    end
  end

  defmodule SerializerPage do
    use NbInertia.Page, component: "Users/Index"

    prop(:users, list: NbInertia.ExtractorTest.UserSerializer)
    prop(:total, :integer)

    def mount(_conn, _params) do
      %{users: [], total: 0}
    end

    def render do
      ~TSX"""
      export default function UsersIndex({ users, total }: Props) {
        return <div>{total} users</div>
      }
      """
    end
  end

  defmodule JsxPage do
    use NbInertia.Page, component: "Test/JsxOnly"

    prop(:items, :list)

    def mount(_conn, _params) do
      %{items: []}
    end

    @doc false
    def __inertia_render_format__, do: :jsx

    def render do
      ~JSX"""
      export default function JsxOnly({ items }) {
        return <ul>{items.map(i => <li key={i}>{i}</li>)}</ul>
      }
      """
    end
  end

  defmodule NoRenderPage do
    use NbInertia.Page, component: "Test/NoRender"

    prop(:data, :string)

    def mount(_conn, _params) do
      %{data: "hello"}
    end

    # No render/0 — standalone file pattern
  end

  defmodule AllPropTypesPage do
    use NbInertia.Page, component: "Test/AllTypes"

    prop(:name, :string)
    prop(:age, :integer)
    prop(:score, :float)
    prop(:active, :boolean)
    prop(:tags, :list)
    prop(:meta, :map)
    prop(:user, NbInertia.ExtractorTest.UserSerializer)
    prop(:users, list: NbInertia.ExtractorTest.UserSerializer)
    prop(:labels, list: :string)
    prop(:status, enum: ["active", "inactive"])
    prop(:nullable_field, :map, nullable: true)
    prop(:optional_field, :string, default: "")

    def mount(_conn, _params) do
      %{
        name: "test",
        age: 30,
        score: 9.5,
        active: true,
        tags: [],
        meta: %{},
        user: %{},
        users: [],
        labels: [],
        status: "active",
        nullable_field: nil,
        optional_field: ""
      }
    end

    def render do
      ~TSX"""
      export default function AllTypes(props: Props) {
        return <div>All types</div>
      }
      """
    end
  end

  # ══════════════════════════════════════════════════════════
  # Preamble Tests
  # ══════════════════════════════════════════════════════════

  describe "Preamble.prop_to_ts_type/1" do
    test "string prop" do
      assert Preamble.prop_to_ts_type(%{name: :name, type: :string, opts: []}) == "string"
    end

    test "integer prop" do
      assert Preamble.prop_to_ts_type(%{name: :count, type: :integer, opts: []}) == "number"
    end

    test "float prop" do
      assert Preamble.prop_to_ts_type(%{name: :score, type: :float, opts: []}) == "number"
    end

    test "number prop" do
      assert Preamble.prop_to_ts_type(%{name: :count, type: :number, opts: []}) == "number"
    end

    test "boolean prop" do
      assert Preamble.prop_to_ts_type(%{name: :active, type: :boolean, opts: []}) == "boolean"
    end

    test "list prop (untyped)" do
      assert Preamble.prop_to_ts_type(%{name: :tags, type: :list, opts: []}) == "any[]"
    end

    test "map prop" do
      assert Preamble.prop_to_ts_type(%{name: :meta, type: :map, opts: []}) ==
               "Record<string, any>"
    end

    test "typed list of strings" do
      assert Preamble.prop_to_ts_type(%{name: :labels, opts: [list: :string]}) == "string[]"
    end

    test "typed list of integers" do
      assert Preamble.prop_to_ts_type(%{name: :scores, opts: [list: :integer]}) == "number[]"
    end

    test "typed list of serializer" do
      assert Preamble.prop_to_ts_type(%{name: :users, opts: [list: UserSerializer]}) ==
               "User[]"
    end

    test "single serializer" do
      assert Preamble.prop_to_ts_type(%{name: :user, serializer: UserSerializer, opts: []}) ==
               "User"
    end

    test "enum type" do
      assert Preamble.prop_to_ts_type(%{name: :status, opts: [enum: ["a", "b"]]}) ==
               "'a' | 'b'"
    end

    test "list of enums" do
      assert Preamble.prop_to_ts_type(%{name: :roles, opts: [list: [enum: ["admin", "user"]]]}) ==
               "('admin' | 'user')[]"
    end

    test "nullable prop" do
      assert Preamble.prop_to_ts_type(%{name: :x, type: :map, opts: [nullable: true]}) ==
               "Record<string, any> | null"
    end

    test "nullable serializer" do
      assert Preamble.prop_to_ts_type(%{
               name: :user,
               serializer: UserSerializer,
               opts: [nullable: true]
             }) == "User | null"
    end
  end

  describe "Preamble.serializer_type_name/1" do
    test "strips Serializer suffix" do
      assert Preamble.serializer_type_name(UserSerializer) == "User"
    end

    test "handles namespaced serializer" do
      assert Preamble.serializer_type_name(MyApp.PostSerializer) == "Post"
    end

    test "handles deeply namespaced serializer" do
      assert Preamble.serializer_type_name(MyApp.API.CommentSerializer) == "Comment"
    end

    test "handles module without Serializer suffix" do
      assert Preamble.serializer_type_name(MyApp.Item) == "Item"
    end
  end

  describe "Preamble.extract_imports/1" do
    test "no imports for primitive types" do
      props = [
        %{name: :name, type: :string, opts: []},
        %{name: :count, type: :integer, opts: []},
        %{name: :active, type: :boolean, opts: []}
      ]

      assert Preamble.extract_imports(props) == []
    end

    test "imports single serializer" do
      props = [
        %{name: :user, serializer: UserSerializer, opts: []}
      ]

      assert Preamble.extract_imports(props) == [{"User", UserSerializer}]
    end

    test "imports list serializer" do
      props = [
        %{name: :users, opts: [list: UserSerializer]}
      ]

      assert Preamble.extract_imports(props) == [{"User", UserSerializer}]
    end

    test "deduplicates imports" do
      props = [
        %{name: :user, serializer: UserSerializer, opts: []},
        %{name: :users, opts: [list: UserSerializer]}
      ]

      # Same type, should be deduped
      imports = Preamble.extract_imports(props)
      assert length(imports) == 1
      assert [{"User", UserSerializer}] = imports
    end

    test "multiple different serializer imports" do
      props = [
        %{name: :user, serializer: UserSerializer, opts: []},
        %{name: :post, serializer: MyApp.PostSerializer, opts: []}
      ]

      imports = Preamble.extract_imports(props)
      assert length(imports) == 2
      type_names = Enum.map(imports, fn {name, _} -> name end)
      assert "Post" in type_names
      assert "User" in type_names
    end

    test "no imports for primitive list types" do
      props = [
        %{name: :tags, opts: [list: :string]}
      ]

      assert Preamble.extract_imports(props) == []
    end

    test "no imports for enum types" do
      props = [
        %{name: :status, opts: [enum: ["active", "inactive"]]}
      ]

      assert Preamble.extract_imports(props) == []
    end
  end

  describe "Preamble.generate/2" do
    test "generates preamble with header and interface" do
      props = [
        %{name: :name, type: :string, opts: []},
        %{name: :count, type: :integer, opts: []}
      ]

      result = Preamble.generate(props, module: MyAppWeb.UsersPage.Index)

      assert result =~ "// AUTO-GENERATED from MyAppWeb.UsersPage.Index"
      assert result =~ "interface Props {"
      assert result =~ "  name: string"
      assert result =~ "  count: number"
      assert result =~ "}"
    end

    test "generates import for serializer types" do
      props = [
        %{name: :users, opts: [list: UserSerializer]},
        %{name: :total, type: :integer, opts: []}
      ]

      result = Preamble.generate(props)

      assert result =~ "import type { User } from '@/types'"
      assert result =~ "interface Props {"
      assert result =~ "  users: User[]"
      assert result =~ "  total: number"
    end

    test "generates custom import path" do
      props = [
        %{name: :user, serializer: UserSerializer, opts: []}
      ]

      result = Preamble.generate(props, types_import_path: "@/generated/types")

      assert result =~ "import type { User } from '@/generated/types'"
    end

    test "generates source path comment" do
      props = [%{name: :x, type: :string, opts: []}]

      result =
        Preamble.generate(props,
          module: MyAppWeb.UsersPage.Index,
          source_path: "lib/my_app_web/inertia/users_page/index.ex"
        )

      assert result =~ "// Source: lib/my_app_web/inertia/users_page/index.ex"
    end

    test "default-backed fields stay required" do
      props = [
        %{name: :name, type: :string, opts: []},
        %{name: :theme, type: :string, opts: [default: "light"]}
      ]

      result = Preamble.generate(props)

      assert result =~ "  name: string"
      assert result =~ "  theme: string"
      refute result =~ "  theme?: string"
    end

    test "partial and deferred fields use ? syntax while lazy stays required" do
      props = [
        %{name: :partial_data, type: :map, opts: [partial: true]},
        %{name: :deferred_data, type: :map, opts: [defer: true]},
        %{name: :lazy_data, type: :map, opts: [lazy: true]}
      ]

      result = Preamble.generate(props)

      assert result =~ "  partial_data?: Record<string, any>"
      assert result =~ "  deferred_data?: Record<string, any>"
      assert result =~ "  lazy_data: Record<string, any>"
      refute result =~ "  lazy_data?: Record<string, any>"
    end

    test "nullable fields use union syntax" do
      props = [
        %{name: :data, type: :map, opts: [nullable: true]}
      ]

      result = Preamble.generate(props)

      assert result =~ "  data: Record<string, any> | null"
    end

    test "generates complete preamble matching spec example" do
      props = [
        %{name: :users, opts: [list: UserSerializer]},
        %{name: :total, type: :integer, opts: []}
      ]

      result =
        Preamble.generate(props,
          module: MyAppWeb.UsersPage.Index,
          source_path: "lib/my_app_web/inertia/users_page/index.ex"
        )

      assert result =~ "// AUTO-GENERATED from MyAppWeb.UsersPage.Index"
      assert result =~ "// Source: lib/my_app_web/inertia/users_page/index.ex"
      assert result =~ "import type { User } from '@/types'"
      assert result =~ "interface Props {"
      assert result =~ "  users: User[]"
      assert result =~ "  total: number"
      assert result =~ "}"
    end

    test "empty props still generate interface" do
      result = Preamble.generate([])
      assert result =~ "interface Props {"
      assert result =~ "}"
    end
  end

  # ══════════════════════════════════════════════════════════
  # Extractor Tests
  # ══════════════════════════════════════════════════════════

  describe "Extractor.extract_module/2" do
    setup do
      # Use a temporary directory for output
      tmp_dir = Path.join(System.tmp_dir!(), "nb_inertia_test_#{:rand.uniform(100_000)}")
      File.rm_rf!(tmp_dir)
      on_cleanup = fn -> File.rm_rf!(tmp_dir) end

      on_exit(fn -> on_cleanup.() end)

      %{output_dir: tmp_dir}
    end

    test "extracts simple TSX page", %{output_dir: output_dir} do
      result = Extractor.extract_module(SimpleTsxPage, output_dir: output_dir)

      assert {:ok, path} = result
      assert String.ends_with?(path, "Test/SimpleTsx.tsx")

      content = File.read!(path)

      # Should have header
      assert content =~ "AUTO-GENERATED"
      assert content =~ "SimpleTsxPage"

      # Should have Props interface
      assert content =~ "interface Props {"
      assert content =~ "title: string"
      assert content =~ "count: number"

      # Should have render content
      assert content =~ "export default function SimpleTsx"
      assert content =~ "{title}: {count}"
    end

    test "extracts page with serializer imports", %{output_dir: output_dir} do
      result = Extractor.extract_module(SerializerPage, output_dir: output_dir)

      assert {:ok, path} = result
      assert String.ends_with?(path, "Users/Index.tsx")

      content = File.read!(path)

      assert content =~ "import type { User } from '@/types'"
      assert content =~ "users: User[]"
      assert content =~ "total: number"
    end

    test "extracts JSX page with .jsx extension", %{output_dir: output_dir} do
      result = Extractor.extract_module(JsxPage, output_dir: output_dir)

      assert {:ok, path} = result
      assert String.ends_with?(path, "Test/JsxOnly.jsx")

      content = File.read!(path)

      # JSX should have header but NO Props interface
      assert content =~ "AUTO-GENERATED"
      assert content =~ "export default function JsxOnly"
      refute content =~ "interface Props"
    end

    test "output file path matches component name", %{output_dir: output_dir} do
      {:ok, path} = Extractor.extract_module(SimpleTsxPage, output_dir: output_dir)
      assert path == Path.join(output_dir, "Test/SimpleTsx.tsx")
    end

    test "incremental: skips if unchanged", %{output_dir: output_dir} do
      # First extraction
      {:ok, _path} = Extractor.extract_module(SimpleTsxPage, output_dir: output_dir)

      # Second extraction — should skip
      result = Extractor.extract_module(SimpleTsxPage, output_dir: output_dir, incremental: true)
      assert {:skipped, _path} = result
    end

    test "non-incremental: always writes", %{output_dir: output_dir} do
      {:ok, _path} = Extractor.extract_module(SimpleTsxPage, output_dir: output_dir)

      result =
        Extractor.extract_module(SimpleTsxPage, output_dir: output_dir, incremental: false)

      assert {:ok, _path} = result
    end

    test "extracts page with all prop types", %{output_dir: output_dir} do
      {:ok, path} = Extractor.extract_module(AllPropTypesPage, output_dir: output_dir)

      content = File.read!(path)

      assert content =~ "name: string"
      assert content =~ "age: number"
      assert content =~ "score: number"
      assert content =~ "active: boolean"
      assert content =~ "tags: any[]"
      assert content =~ "meta: Record<string, any>"
      assert content =~ "user: User"
      assert content =~ "users: User[]"
      assert content =~ "labels: string[]"
      assert content =~ "status: 'active' | 'inactive'"
      assert content =~ "nullable_field: Record<string, any> | null"
      assert content =~ "optional_field: string"
    end

    test "creates nested directories as needed", %{output_dir: output_dir} do
      {:ok, path} = Extractor.extract_module(SerializerPage, output_dir: output_dir)

      assert File.exists?(path)
      assert File.dir?(Path.dirname(path))
    end
  end

  describe "Extractor.extract_all/1" do
    setup do
      tmp_dir = Path.join(System.tmp_dir!(), "nb_inertia_test_all_#{:rand.uniform(100_000)}")
      File.rm_rf!(tmp_dir)
      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      %{output_dir: tmp_dir}
    end

    test "extracts specific modules when provided", %{output_dir: output_dir} do
      results =
        Extractor.extract_all(
          output_dir: output_dir,
          modules: [SimpleTsxPage, SerializerPage, NoRenderPage]
        )

      # Should extract SimpleTsxPage and SerializerPage, skip NoRenderPage (no render/0)
      ok_results = Enum.filter(results, &match?({:ok, _}, &1))
      assert length(ok_results) == 2
    end

    test "skips modules without render/0", %{output_dir: output_dir} do
      results =
        Extractor.extract_all(
          output_dir: output_dir,
          modules: [NoRenderPage]
        )

      # NoRenderPage has no render/0, so nothing should be extracted
      assert results == []
    end

    test "clean option removes output dir first", %{output_dir: output_dir} do
      # Create a file in the output dir
      File.mkdir_p!(output_dir)
      File.write!(Path.join(output_dir, "stale.tsx"), "old content")

      Extractor.extract_all(
        output_dir: output_dir,
        modules: [SimpleTsxPage],
        clean: true
      )

      # Stale file should be gone
      refute File.exists?(Path.join(output_dir, "stale.tsx"))
      # New file should exist
      assert File.exists?(Path.join(output_dir, "Test/SimpleTsx.tsx"))
    end

    test "idempotent: running twice produces same output", %{output_dir: output_dir} do
      modules = [SimpleTsxPage, SerializerPage]

      Extractor.extract_all(output_dir: output_dir, modules: modules)

      # Read contents
      content1 =
        Path.join(output_dir, "Test/SimpleTsx.tsx")
        |> File.read!()

      # Run again (non-incremental to force rewrite)
      Extractor.extract_all(output_dir: output_dir, modules: modules, incremental: false)

      # Read contents again
      content2 =
        Path.join(output_dir, "Test/SimpleTsx.tsx")
        |> File.read!()

      assert content1 == content2
    end
  end
end
