defmodule NbInertia.Credo.ChecksTest do
  use ExUnit.Case, async: true

  alias NbInertia.Credo.Check.Warning.UseNbInertiaController
  alias NbInertia.Credo.Check.Warning.AvoidRawInertiaRender
  alias NbInertia.Credo.Check.Warning.ModalRequiresBaseUrl
  alias NbInertia.Credo.Check.Readability.PropFromAssigns
  alias NbInertia.Credo.Check.Design.DeclareInertiaPage

  describe "UseNbInertiaController" do
    test "warns when using `use Inertia.Controller`" do
      source = """
      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        use Inertia.Controller
      end
      """

      issues = run_check(UseNbInertiaController, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "Use `NbInertia.Controller` instead"
    end

    test "does not warn when using `use NbInertia.Controller`" do
      source = """
      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        use NbInertia.Controller
      end
      """

      issues = run_check(UseNbInertiaController, source)
      assert issues == []
    end

    test "warns when using `use Inertia.Controller` with options" do
      source = """
      defmodule MyAppWeb.UserController do
        use Inertia.Controller, some_option: true
      end
      """

      issues = run_check(UseNbInertiaController, source)
      assert length(issues) == 1
    end
  end

  describe "AvoidRawInertiaRender" do
    test "warns when calling Inertia.Controller.render_inertia directly" do
      source = """
      defmodule MyAppWeb.UserController do
        def index(conn, _params) do
          Inertia.Controller.render_inertia(conn, "Users/Index", %{users: []})
        end
      end
      """

      issues = run_check(AvoidRawInertiaRender, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "Use the imported `render_inertia/3`"
    end

    test "does not warn when using imported render_inertia" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
        end

        def index(conn, _params) do
          render_inertia(conn, :users_index, users: [])
        end
      end
      """

      issues = run_check(AvoidRawInertiaRender, source)
      assert issues == []
    end
  end

  describe "ModalRequiresBaseUrl" do
    test "warns when render_inertia_modal is called without base_url" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, %{"id" => id}) do
          render_inertia_modal(conn, :user_details, user: get_user(id))
        end
      end
      """

      issues = run_check(ModalRequiresBaseUrl, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "requires the `:base_url` option"
    end

    test "does not warn when base_url is provided" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, %{"id" => id}) do
          render_inertia_modal(conn, :user_details,
            [user: get_user(id)],
            base_url: "/users"
          )
        end
      end
      """

      issues = run_check(ModalRequiresBaseUrl, source)
      assert issues == []
    end

    test "warns when render_inertia_modal has only 2 args" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, _params) do
          render_inertia_modal(conn, :user_details)
        end
      end
      """

      issues = run_check(ModalRequiresBaseUrl, source)
      assert length(issues) == 1
    end

    test "does not warn when base_url is in 4-arg version" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, %{"id" => id}) do
          render_inertia_modal(conn, :user_details, [], base_url: users_path())
        end
      end
      """

      issues = run_check(ModalRequiresBaseUrl, source)
      assert issues == []
    end
  end

  describe "PropFromAssigns" do
    test "suggests using from: :assigns when accessing conn.assigns" do
      source = """
      defmodule MyAppWeb.DashboardController do
        def index(conn, _params) do
          render_inertia(conn, :dashboard,
            current_user: conn.assigns.current_user
          )
        end
      end
      """

      issues = run_check(PropFromAssigns, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "from: :assigns"
    end

    test "does not warn when not accessing conn.assigns" do
      source = """
      defmodule MyAppWeb.DashboardController do
        def index(conn, _params) do
          render_inertia(conn, :dashboard,
            users: list_users()
          )
        end
      end
      """

      issues = run_check(PropFromAssigns, source)
      assert issues == []
    end
  end

  describe "DeclareInertiaPage" do
    test "warns when using atom page ref without NbInertia.Controller" do
      source = """
      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller

        def index(conn, _params) do
          render_inertia(conn, :users_index, users: [])
        end
      end
      """

      issues = run_check(DeclareInertiaPage, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "requires `use NbInertia.Controller`"
    end

    test "warns when page is not declared" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
        end

        def index(conn, _params) do
          render_inertia(conn, :users_index, users: [])
        end

        def show(conn, _params) do
          render_inertia(conn, :users_show, user: %{})
        end
      end
      """

      issues = run_check(DeclareInertiaPage, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":users_show"
    end

    test "does not warn when page is properly declared" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
        end

        def index(conn, _params) do
          render_inertia(conn, :users_index, users: [])
        end
      end
      """

      issues = run_check(DeclareInertiaPage, source)
      assert issues == []
    end

    test "does not warn when using string component name" do
      source = """
      defmodule MyAppWeb.UserController do
        def index(conn, _params) do
          render_inertia(conn, "Users/Index", %{users: []})
        end
      end
      """

      issues = run_check(DeclareInertiaPage, source)
      assert issues == []
    end
  end

  # Helper to run a Credo check on source code
  defp run_check(check_module, source_code) do
    source_file = source_to_source_file(source_code)
    check_module.run(source_file, [])
  end

  defp source_to_source_file(source_code) do
    %Credo.SourceFile{
      filename: "test.ex",
      source: source_code,
      status: :valid
    }
  end
end
