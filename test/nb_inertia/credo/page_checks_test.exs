defmodule NbInertia.Credo.PageChecksTest do
  use ExUnit.Case, async: false

  alias NbInertia.Credo.Check.Warning.MissingMount
  alias NbInertia.Credo.Check.Warning.ActionWithoutMount
  alias NbInertia.Credo.Check.Warning.UndeclaredPropInMount
  alias NbInertia.Credo.Check.Warning.UnusedPropInMount
  alias NbInertia.Credo.Check.Warning.ModalWithoutBaseUrl
  alias NbInertia.Credo.Check.Warning.RenderWithoutProps
  alias NbInertia.Credo.Check.Warning.MixedPageAndController
  alias NbInertia.Credo.Check.Warning.UntypedInertiaProps
  alias NbInertia.Credo.Check.Design.DeclareInertiaPage

  # Start Credo services before running tests
  setup_all do
    Application.ensure_all_started(:credo)
    :ok
  end

  # ── MissingMount ──────────────────────────────────────────────────────

  describe "MissingMount" do
    test "warns when Page module has no mount/2" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list
      end
      """

      issues = run_check(MissingMount, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "does not define `mount/2`"
      assert hd(issues).message =~ "UsersPage.Index"
    end

    test "does not warn when mount/2 is defined" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list

        def mount(_conn, _params) do
          %{users: []}
        end
      end
      """

      issues = run_check(MissingMount, source)
      assert issues == []
    end

    test "does not warn for non-Page modules" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :index do
          prop :users, :list
        end
      end
      """

      issues = run_check(MissingMount, source)
      assert issues == []
    end

    test "does not warn when mount has 2 parameters" do
      source = """
      defmodule MyAppWeb.UsersPage.Show do
        use NbInertia.Page

        prop :user, :map

        def mount(conn, %{"id" => id}) do
          %{user: %{id: id}}
        end
      end
      """

      issues = run_check(MissingMount, source)
      assert issues == []
    end
  end

  # ── ActionWithoutMount ────────────────────────────────────────────────

  describe "ActionWithoutMount" do
    test "warns when action/3 exists without mount/2" do
      source = """
      defmodule MyAppWeb.UsersPage.Create do
        use NbInertia.Page

        prop :user, :map

        def action(conn, params, :create) do
          redirect(conn, to: "/users")
        end
      end
      """

      issues = run_check(ActionWithoutMount, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "defines `action/3` but not `mount/2`"
    end

    test "does not warn when both mount/2 and action/3 exist" do
      source = """
      defmodule MyAppWeb.UsersPage.Create do
        use NbInertia.Page

        prop :user, :map

        def mount(_conn, _params) do
          %{user: %{}}
        end

        def action(conn, params, :create) do
          redirect(conn, to: "/users")
        end
      end
      """

      issues = run_check(ActionWithoutMount, source)
      assert issues == []
    end

    test "does not warn when only mount/2 exists" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list

        def mount(_conn, _params) do
          %{users: []}
        end
      end
      """

      issues = run_check(ActionWithoutMount, source)
      assert issues == []
    end

    test "does not warn for non-Page modules" do
      source = """
      defmodule MyAppWeb.SomeModule do
        def action(conn, params, :create) do
          :ok
        end
      end
      """

      issues = run_check(ActionWithoutMount, source)
      assert issues == []
    end
  end

  # ── UndeclaredPropInMount ─────────────────────────────────────────────

  describe "UndeclaredPropInMount" do
    test "warns when mount/2 returns undeclared keys" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list

        def mount(_conn, _params) do
          %{users: [], total_count: 42}
        end
      end
      """

      issues = run_check(UndeclaredPropInMount, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":total_count"
      assert hd(issues).message =~ "not declared as a prop"
    end

    test "does not warn when all mount keys are declared" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list
        prop :total_count, :integer

        def mount(_conn, _params) do
          %{users: [], total_count: 42}
        end
      end
      """

      issues = run_check(UndeclaredPropInMount, source)
      assert issues == []
    end

    test "does not warn for non-Page modules" do
      source = """
      defmodule MyAppWeb.SomeModule do
        def mount(_conn, _params) do
          %{undeclared: true}
        end
      end
      """

      issues = run_check(UndeclaredPropInMount, source)
      assert issues == []
    end

    test "handles mount with no map return" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list

        def mount(conn, _params) do
          redirect(conn, to: "/")
        end
      end
      """

      issues = run_check(UndeclaredPropInMount, source)
      assert issues == []
    end
  end

  # ── UnusedPropInMount ─────────────────────────────────────────────────

  describe "UnusedPropInMount" do
    test "warns when declared prop is not returned from mount" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list
        prop :total_count, :integer

        def mount(_conn, _params) do
          %{users: []}
        end
      end
      """

      issues = run_check(UnusedPropInMount, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":total_count"
      assert hd(issues).message =~ "not returned from `mount/2`"
    end

    test "does not warn when prop has default option" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list
        prop :total_count, :integer, default: 0

        def mount(_conn, _params) do
          %{users: []}
        end
      end
      """

      issues = run_check(UnusedPropInMount, source)
      assert issues == []
    end

    test "does not warn when prop has from option" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list
        prop :current_user, :map, from: :assigns

        def mount(_conn, _params) do
          %{users: []}
        end
      end
      """

      issues = run_check(UnusedPropInMount, source)
      assert issues == []
    end

    test "does not warn when prop has defer option" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list
        prop :stats, :map, defer: true

        def mount(_conn, _params) do
          %{users: []}
        end
      end
      """

      issues = run_check(UnusedPropInMount, source)
      assert issues == []
    end

    test "does not warn when all props are returned" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list
        prop :total_count, :integer

        def mount(_conn, _params) do
          %{users: [], total_count: 42}
        end
      end
      """

      issues = run_check(UnusedPropInMount, source)
      assert issues == []
    end

    test "does not warn for non-Page modules" do
      source = """
      defmodule MyAppWeb.SomeModule do
        prop :users, :list

        def mount(_conn, _params) do
          %{other: true}
        end
      end
      """

      issues = run_check(UnusedPropInMount, source)
      assert issues == []
    end
  end

  # ── ModalWithoutBaseUrl ───────────────────────────────────────────────

  describe "ModalWithoutBaseUrl" do
    test "warns when modal is used without base_url" do
      source = """
      defmodule MyAppWeb.UsersPage.Show do
        use NbInertia.Page

        modal size: :lg, position: :center

        prop :user, :map

        def mount(_conn, %{"id" => id}) do
          %{user: %{id: id}}
        end
      end
      """

      issues = run_check(ModalWithoutBaseUrl, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "missing the `:base_url` option"
    end

    test "does not warn when base_url is provided" do
      source = """
      defmodule MyAppWeb.UsersPage.Show do
        use NbInertia.Page

        modal base_url: "/users", size: :lg

        prop :user, :map

        def mount(_conn, %{"id" => id}) do
          %{user: %{id: id}}
        end
      end
      """

      issues = run_check(ModalWithoutBaseUrl, source)
      assert issues == []
    end

    test "does not warn when modal_config is used in mount" do
      source = """
      defmodule MyAppWeb.UsersPage.Show do
        use NbInertia.Page

        modal size: :lg

        prop :user, :map

        def mount(conn, %{"id" => id}) do
          conn
          |> modal_config(base_url: "/users")
          |> props(%{user: %{id: id}})
        end
      end
      """

      issues = run_check(ModalWithoutBaseUrl, source)
      assert issues == []
    end

    test "does not warn for non-Page modules" do
      source = """
      defmodule MyAppWeb.SomeModule do
        modal size: :lg
      end
      """

      issues = run_check(ModalWithoutBaseUrl, source)
      assert issues == []
    end

    test "does not warn when no modal is declared" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list

        def mount(_conn, _params) do
          %{users: []}
        end
      end
      """

      issues = run_check(ModalWithoutBaseUrl, source)
      assert issues == []
    end
  end

  # ── RenderWithoutProps ────────────────────────────────────────────────

  describe "RenderWithoutProps" do
    test "warns when ~TSX references Props but no props declared" do
      # Use single-line ~TSX to avoid heredoc nesting issues
      source = ~s'''
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        def mount(_conn, _params) do
          %{users: []}
        end

        def render do
          ~TSX"export default function Index({ users }: Props) { return <div />; }"
        end
      end
      '''

      issues = run_check(RenderWithoutProps, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "references `Props` but no props are declared"
    end

    test "does not warn when props are declared" do
      source = ~s'''
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list

        def mount(_conn, _params) do
          %{users: []}
        end

        def render do
          ~TSX"export default function Index({ users }: Props) { return <div />; }"
        end
      end
      '''

      issues = run_check(RenderWithoutProps, source)
      assert issues == []
    end

    test "does not warn when ~TSX does not reference Props" do
      source = ~s'''
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        def mount(_conn, _params) do
          %{users: []}
        end

        def render do
          ~TSX"export default function Index() { return <div>Hello</div>; }"
        end
      end
      '''

      issues = run_check(RenderWithoutProps, source)
      assert issues == []
    end

    test "does not warn for non-Page modules" do
      source = ~s'''
      defmodule MyAppWeb.SomeModule do
        def render do
          ~TSX"export default function Index({ data }: Props) { return <div />; }"
        end
      end
      '''

      issues = run_check(RenderWithoutProps, source)
      assert issues == []
    end
  end

  # ── MixedPageAndController ───────────────────────────────────────────

  describe "MixedPageAndController" do
    test "warns when both use NbInertia.Page and use NbInertia.Controller" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page
        use NbInertia.Controller
      end
      """

      issues = run_check(MixedPageAndController, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "uses both `NbInertia.Page` and `NbInertia.Controller`"
    end

    test "does not warn when only Page is used" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list

        def mount(_conn, _params) do
          %{users: []}
        end
      end
      """

      issues = run_check(MixedPageAndController, source)
      assert issues == []
    end

    test "does not warn when only Controller is used" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :index do
          prop :users, :list
        end
      end
      """

      issues = run_check(MixedPageAndController, source)
      assert issues == []
    end

    test "does not warn when neither is used" do
      source = """
      defmodule MyAppWeb.PlainModule do
        def hello, do: :world
      end
      """

      issues = run_check(MixedPageAndController, source)
      assert issues == []
    end
  end

  # ── Updated Existing Checks ──────────────────────────────────────────

  describe "UntypedInertiaProps (Page modules)" do
    test "warns on generic types in Page module prop declarations" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :filters, :map
        prop :users, :list

        def mount(_conn, _params) do
          %{filters: %{}, users: []}
        end
      end
      """

      issues = run_check(UntypedInertiaProps, source)
      assert length(issues) == 2
      messages = Enum.map(issues, & &1.message)
      assert Enum.any?(messages, &(&1 =~ ":filters"))
      assert Enum.any?(messages, &(&1 =~ ":users"))
    end

    test "does not warn on specific types in Page module" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :name, :string
        prop :count, :number

        def mount(_conn, _params) do
          %{name: "test", count: 42}
        end
      end
      """

      issues = run_check(UntypedInertiaProps, source)
      assert issues == []
    end
  end

  describe "DeclareInertiaPage (Page module awareness)" do
    test "does not warn for Page modules using render_inertia" do
      source = """
      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list

        def mount(_conn, _params) do
          render_inertia(conn, :some_page, users: [])
        end
      end
      """

      issues = run_check(DeclareInertiaPage, source)
      assert issues == []
    end
  end

  # ── Helpers ──────────────────────────────────────────────────────────

  defp run_check(check_module, source_code, params \\ []) do
    source_file = source_to_source_file(source_code)
    check_module.run(source_file, params)
  end

  defp source_to_source_file(source_code) do
    Credo.SourceFile.parse(source_code, "test.ex")
  end
end
