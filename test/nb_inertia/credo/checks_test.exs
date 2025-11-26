defmodule NbInertia.Credo.ChecksTest do
  use ExUnit.Case, async: false

  alias NbInertia.Credo.Check.Warning.UseNbInertiaController
  alias NbInertia.Credo.Check.Warning.AvoidRawInertiaRender
  alias NbInertia.Credo.Check.Warning.ModalRequiresBaseUrl
  alias NbInertia.Credo.Check.Warning.MissingInertiaPageProps
  alias NbInertia.Credo.Check.Warning.UntypedInertiaProps
  alias NbInertia.Credo.Check.Warning.MissingSerializerInertiaProps
  alias NbInertia.Credo.Check.Warning.MissingInertiaSharedProps
  alias NbInertia.Credo.Check.Warning.InconsistentOptionalProps
  alias NbInertia.Credo.Check.Warning.MixedInertiaControllerType
  alias NbInertia.Credo.Check.Readability.PropFromAssigns
  alias NbInertia.Credo.Check.Readability.InertiaPageComponentNameCase
  alias NbInertia.Credo.Check.Design.DeclareInertiaPage
  alias NbInertia.Credo.Check.Design.FormInputsOptionalFieldConsistency

  # Start Credo services before running tests
  setup_all do
    Application.ensure_all_started(:credo)
    :ok
  end

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

  describe "MissingInertiaPageProps" do
    test "warns when render_inertia passes props not declared in inertia_page" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :users_show do
          prop :user, UserSerializer
        end

        def show(conn, _params) do
          render_inertia(conn, :users_show,
            user: %{},
            extra_field: "not declared"
          )
        end
      end
      """

      issues = run_check(MissingInertiaPageProps, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":extra_field"
      assert hd(issues).message =~ "not declared"
    end

    test "does not warn when all props are declared" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :users_show do
          prop :user, UserSerializer
          prop :stats, :map
        end

        def show(conn, _params) do
          render_inertia(conn, :users_show,
            user: %{},
            stats: %{}
          )
        end
      end
      """

      issues = run_check(MissingInertiaPageProps, source)
      assert issues == []
    end

    test "does not warn when no inertia_page is declared" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, _params) do
          render_inertia(conn, :users_show, user: %{})
        end
      end
      """

      issues = run_check(MissingInertiaPageProps, source)
      assert issues == []
    end
  end

  describe "UntypedInertiaProps" do
    test "warns when prop uses generic :map type" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :dashboard do
          prop :config, :map
        end
      end
      """

      issues = run_check(UntypedInertiaProps, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":config"
      assert hd(issues).message =~ ":map"
    end

    test "warns when prop uses generic :list type" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :index do
          prop :items, :list
        end
      end
      """

      issues = run_check(UntypedInertiaProps, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":items"
      assert hd(issues).message =~ ":list"
    end

    test "warns when prop uses :any type" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :show do
          prop :data, :any
        end
      end
      """

      issues = run_check(UntypedInertiaProps, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":data"
      assert hd(issues).message =~ ":any"
    end

    test "does not warn when prop uses specific types" do
      source = """
      defmodule MyAppWeb.UserController do
        use NbInertia.Controller

        inertia_page :show do
          prop :name, :string
          prop :count, :number
          prop :user, UserSerializer
        end
      end
      """

      issues = run_check(UntypedInertiaProps, source)
      assert issues == []
    end
  end

  describe "MissingSerializerInertiaProps" do
    test "warns when prop uses dot access without serializer" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, _params) do
          render_inertia(conn, :show,
            config: widget.config
          )
        end
      end
      """

      issues = run_check(MissingSerializerInertiaProps, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":config"
      assert hd(issues).message =~ "serializer"
    end

    test "does not warn when using serializer tuple" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, _params) do
          render_inertia(conn, :show,
            user: {UserSerializer, user}
          )
        end
      end
      """

      issues = run_check(MissingSerializerInertiaProps, source)
      assert issues == []
    end

    test "does not warn for simple values" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, _params) do
          render_inertia(conn, :show,
            name: "test",
            count: 42
          )
        end
      end
      """

      issues = run_check(MissingSerializerInertiaProps, source)
      assert issues == []
    end
  end

  describe "MissingInertiaSharedProps" do
    test "warns when expected shared props are missing" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        inertia_shared(FormErrors)

        inertia_page :index do
          prop :items, :list
        end
      end
      """

      issues =
        run_check(MissingInertiaSharedProps, source, expected: [Auth, FormErrors, UIPreferences])

      assert length(issues) == 2
      messages = Enum.map(issues, & &1.message)
      assert Enum.any?(messages, &(&1 =~ "Auth"))
      assert Enum.any?(messages, &(&1 =~ "UIPreferences"))
    end

    test "does not warn when all expected shared props are declared" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        inertia_shared(Auth)
        inertia_shared(FormErrors)
        inertia_shared(UIPreferences)

        inertia_page :index do
          prop :items, :list
        end
      end
      """

      issues =
        run_check(MissingInertiaSharedProps, source, expected: [Auth, FormErrors, UIPreferences])

      assert issues == []
    end

    test "does not warn when no expected shared props configured" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        inertia_page :index do
          prop :items, :list
        end
      end
      """

      issues = run_check(MissingInertiaSharedProps, source, [])
      assert issues == []
    end

    test "does not warn for excluded modules" do
      source = """
      defmodule MyAppWeb.PublicController do
        use NbInertia.Controller

        inertia_page :index do
          prop :items, :list
        end
      end
      """

      issues =
        run_check(MissingInertiaSharedProps, source,
          expected: [Auth],
          exclude_modules: [MyAppWeb.PublicController]
        )

      assert issues == []
    end
  end

  describe "InconsistentOptionalProps" do
    test "warns when prop is set to nil" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, _params) do
          render_inertia(conn, :show,
            user: user,
            settings: nil
          )
        end
      end
      """

      issues = run_check(InconsistentOptionalProps, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":settings"
      assert hd(issues).message =~ "nil"
    end

    test "does not warn when props have values" do
      source = """
      defmodule MyAppWeb.UserController do
        def show(conn, _params) do
          render_inertia(conn, :show,
            user: user,
            settings: %{}
          )
        end
      end
      """

      issues = run_check(InconsistentOptionalProps, source)
      assert issues == []
    end
  end

  describe "MixedInertiaControllerType" do
    test "warns when using both :controller and NbInertia.Controller" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use MyAppWeb, :controller
        use NbInertia.Controller

        inertia_page :index do
          prop :items, :list
        end
      end
      """

      issues = run_check(MixedInertiaControllerType, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":controller"
      assert hd(issues).message =~ "NbInertia.Controller"
    end

    test "does not warn when using only NbInertia.Controller" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        inertia_page :index do
          prop :items, :list
        end
      end
      """

      issues = run_check(MixedInertiaControllerType, source)
      assert issues == []
    end

    test "does not warn when using only :controller" do
      source = """
      defmodule MyAppWeb.ApiController do
        use MyAppWeb, :controller

        def index(conn, _params) do
          json(conn, %{status: "ok"})
        end
      end
      """

      issues = run_check(MixedInertiaControllerType, source)
      assert issues == []
    end
  end

  describe "InertiaPageComponentNameCase" do
    test "warns when component name is snake_case" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        inertia_page :index, component: "items_index" do
          prop :items, :list
        end
      end
      """

      issues = run_check(InertiaPageComponentNameCase, source)
      assert length(issues) == 1
      assert hd(issues).message =~ "items_index"
      assert hd(issues).message =~ "PascalCase"
    end

    test "warns when component name path is lowercase" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        inertia_page :index, component: "items/index" do
          prop :items, :list
        end
      end
      """

      issues = run_check(InertiaPageComponentNameCase, source)
      assert length(issues) == 1
    end

    test "does not warn when component name is PascalCase" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        inertia_page :index, component: "Items/Index" do
          prop :items, :list
        end
      end
      """

      issues = run_check(InertiaPageComponentNameCase, source)
      assert issues == []
    end

    test "does not warn when no explicit component name" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        inertia_page :index do
          prop :items, :list
        end
      end
      """

      issues = run_check(InertiaPageComponentNameCase, source)
      assert issues == []
    end
  end

  describe "FormInputsOptionalFieldConsistency" do
    test "warns when optional fields differ between create and edit forms" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        form_inputs :create_item do
          input :name, :string
          input :description, :string, optional: true
        end

        form_inputs :edit_item do
          input :name, :string, optional: true
          input :description, :string, optional: true
        end
      end
      """

      issues = run_check(FormInputsOptionalFieldConsistency, source)
      assert length(issues) == 1
      assert hd(issues).message =~ ":name"
      assert hd(issues).message =~ "inconsistent"
    end

    test "does not warn when optional fields are consistent" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        form_inputs :create_item do
          input :name, :string
          input :description, :string, optional: true
        end

        form_inputs :edit_item do
          input :name, :string
          input :description, :string, optional: true
        end
      end
      """

      issues = run_check(FormInputsOptionalFieldConsistency, source)
      assert issues == []
    end

    test "does not warn for unrelated forms" do
      source = """
      defmodule MyAppWeb.ItemsController do
        use NbInertia.Controller

        form_inputs :search_items do
          input :query, :string
        end

        form_inputs :filter_items do
          input :query, :string, optional: true
        end
      end
      """

      issues = run_check(FormInputsOptionalFieldConsistency, source)
      assert issues == []
    end
  end

  # Helper to run a Credo check on source code
  defp run_check(check_module, source_code, params \\ []) do
    source_file = source_to_source_file(source_code)
    check_module.run(source_file, params)
  end

  defp source_to_source_file(source_code) do
    # Use Credo's parse function (requires Credo services to be started)
    Credo.SourceFile.parse(source_code, "test.ex")
  end
end
