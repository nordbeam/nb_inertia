defmodule NbInertia.PagePhase3Test do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  # ══════════════════════════════════════════════════════════
  # Test Page Modules — Modal Support
  # ══════════════════════════════════════════════════════════

  defmodule ModalPage do
    use NbInertia.Page, component: "Test/Modal"

    modal(
      base_url: "/users",
      size: :lg,
      position: :center
    )

    prop(:user, :map)

    def mount(_conn, _params) do
      %{user: %{id: 1, name: "Alice"}}
    end
  end

  defmodule SlideoverPage do
    use NbInertia.Page, component: "Test/Slideover"

    modal(
      slideover: true,
      position: :right,
      size: :lg,
      base_url: "/settings",
      close_button: true,
      close_explicitly: false
    )

    prop(:settings, :map)

    def mount(_conn, _params) do
      %{settings: %{theme: "dark"}}
    end
  end

  defmodule DynamicBaseUrlPage do
    use NbInertia.Page, component: "Test/DynamicModal"

    modal(
      base_url: &"/users/#{&1["id"]}",
      size: :md
    )

    prop(:user, :map)

    def mount(_conn, _params) do
      %{user: %{id: 42, name: "Bob"}}
    end
  end

  defmodule ModalConfigOverridePage do
    use NbInertia.Page, component: "Test/ModalOverride"

    modal(
      base_url: "/default",
      size: :md
    )

    prop(:data, :map)

    def mount(conn, _params) do
      conn
      |> NbInertia.Page.modal_config(base_url: "/overridden", size: :xl)
      |> NbInertia.Page.props(%{data: %{value: "test"}})
    end
  end

  defmodule NoModalPage do
    use NbInertia.Page, component: "Test/NoModal"

    prop(:items, :list)

    def mount(_conn, _params) do
      %{items: []}
    end
  end

  defmodule ModalWithActionPage do
    use NbInertia.Page, component: "Test/ModalAction"

    modal(
      base_url: "/items",
      size: :md
    )

    prop(:item, :map)

    def mount(_conn, _params) do
      %{item: %{id: 1}}
    end

    def action(conn, _params, :delete) do
      close_modal(conn)
    end

    def action(conn, _params, :create) do
      redirect_modal_success(conn, "Created!", to: "/items")
    end

    def action(conn, _params, :update) do
      redirect_modal_error(conn, "Failed!", to: "/items")
    end
  end

  # ══════════════════════════════════════════════════════════
  # Test Shared Props Module (mock)
  # ══════════════════════════════════════════════════════════

  defmodule MockSharedProps do
    @behaviour NbInertia.SharedProps.Behaviour

    @impl true
    def build_props(_conn, _opts) do
      %{locale: "en", theme: "default"}
    end
  end

  defmodule AnotherSharedProps do
    @behaviour NbInertia.SharedProps.Behaviour

    @impl true
    def build_props(_conn, _opts) do
      %{feature_flags: %{new_ui: true}}
    end
  end

  # ══════════════════════════════════════════════════════════
  # Test Page Modules — Shared Props
  # ══════════════════════════════════════════════════════════

  defmodule SharedModulePage do
    use NbInertia.Page, component: "Test/SharedModule"

    shared(NbInertia.PagePhase3Test.MockSharedProps)

    prop(:users, :list)

    def mount(_conn, _params) do
      %{users: []}
    end
  end

  defmodule MultipleSharedModulesPage do
    use NbInertia.Page, component: "Test/MultiShared"

    shared(NbInertia.PagePhase3Test.MockSharedProps)
    shared(NbInertia.PagePhase3Test.AnotherSharedProps)

    prop(:data, :map)

    def mount(_conn, _params) do
      %{data: %{}}
    end
  end

  defmodule InlineSharedPage do
    use NbInertia.Page, component: "Test/InlineShared"

    shared do
      prop(:locale, :string)
      prop(:api_version, :string)
    end

    prop(:items, :list)

    def mount(_conn, _params) do
      %{items: ["a", "b"]}
    end
  end

  defmodule RuntimeInlineSharedPage do
    use NbInertia.Page, component: "Test/RuntimeInlineShared"

    shared do
      prop(:locale, :string, from: :assigns)
      prop(:api_version, :string, default: "v1")
    end

    prop(:items, :list)

    def mount(_conn, _params) do
      %{items: ["a", "b"]}
    end
  end

  defmodule RuntimeSharedModalPage do
    use NbInertia.Page, component: "Test/RuntimeSharedModal"

    modal(base_url: "/users", size: :md)

    shared(NbInertia.PagePhase3Test.MockSharedProps)

    shared do
      prop(:locale, :string, from: :assigns)
    end

    prop(:items, :list)

    def mount(_conn, _params) do
      %{items: ["a", "b"]}
    end
  end

  defmodule NoSharedPage do
    use NbInertia.Page, component: "Test/NoShared"

    prop(:data, :string)

    def mount(_conn, _params) do
      %{data: "hello"}
    end
  end

  defp inertia_conn(page_module, assigns) do
    version =
      conn(:get, "/")
      |> init_test_session(%{})
      |> assign(:flash, %{})
      |> NbInertia.Plug.call([])
      |> then(& &1.private[:inertia_version])

    conn =
      conn(:get, "/")
      |> init_test_session(%{})
      |> assign(:flash, %{})
      |> put_private(:phoenix_action, :show)
      |> put_private(:phoenix_controller, NbInertia.PageController)
      |> put_private(:nb_inertia_page_module, page_module)

    conn =
      Enum.reduce(assigns, conn, fn {key, value}, acc ->
        assign(acc, key, value)
      end)

    conn
    |> put_req_header("x-inertia", "true")
    |> put_req_header("x-inertia-version", version)
    |> NbInertia.Plug.call([])
  end

  defmodule ModalBaseEndpoint do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, _opts) do
      page =
        Jason.encode!(%{
          component: "Users/Index",
          props: %{users: []},
          url: conn.request_path,
          version: "test-version"
        })

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, page)
    end
  end

  defp modal_inertia_conn(page_module, assigns) do
    page_module
    |> inertia_conn(assigns)
    |> put_private(:phoenix_endpoint, ModalBaseEndpoint)
  end

  # ══════════════════════════════════════════════════════════
  # Test Page Modules — Precognition
  # ══════════════════════════════════════════════════════════

  defmodule PrecognitionPage do
    use NbInertia.Page, component: "Test/Precognition"

    prop(:roles, :list)

    form_inputs :user_form do
      field(:name, :string)
      field(:email, :string)
    end

    def mount(_conn, _params) do
      %{roles: ["admin", "user"]}
    end

    def action(conn, %{"user" => _params}, :create) do
      # Use precognition with a simple error map for testing
      errors = %{name: ["is required"], email: ["is invalid"]}

      precognition conn, errors do
        # Real submission logic — would only run for non-precognition requests
        Phoenix.Controller.redirect(conn, to: "/users")
      end
    end
  end

  defmodule PrecognitionWithFieldsPage do
    use NbInertia.Page, component: "Test/PrecognitionFields"

    prop(:data, :map)

    def mount(_conn, _params) do
      %{data: %{}}
    end

    def action(conn, _params, :create) do
      errors = %{name: ["required"], email: ["invalid"], age: ["too young"]}

      precognition conn, errors, only: precognition_fields(conn) do
        Phoenix.Controller.redirect(conn, to: "/success")
      end
    end
  end

  # ══════════════════════════════════════════════════════════
  # Test Page Modules — History Controls
  # ══════════════════════════════════════════════════════════

  defmodule HistoryPage do
    use NbInertia.Page,
      component: "Test/History",
      encrypt_history: true,
      clear_history: true,
      preserve_fragment: true

    prop(:data, :string)

    def mount(_conn, _params) do
      %{data: "sensitive"}
    end
  end

  defmodule HistoryOverridePage do
    use NbInertia.Page, component: "Test/HistoryOverride"

    prop(:data, :string)

    def mount(conn, _params) do
      conn
      |> encrypt_history(true)
      |> clear_history(true)
      |> preserve_fragment(true)
      |> NbInertia.Page.props(%{data: "override"})
    end
  end

  # ══════════════════════════════════════════════════════════
  # Test Page Module — Additional Helpers
  # ══════════════════════════════════════════════════════════

  defmodule HelpersPage do
    use NbInertia.Page, component: "Test/Helpers"

    prop(:data, :map)

    def mount(conn, _params) do
      conn
      |> mark_shared_prop_keys([:locale, :user])
      |> force_inertia_redirect()
      |> NbInertia.Page.props(%{data: %{}})
    end
  end

  # ══════════════════════════════════════════════════════════
  # Tests — Modal Support
  # ══════════════════════════════════════════════════════════

  describe "modal macro" do
    test "stores modal config correctly" do
      config = ModalPage.__inertia_modal__()
      assert config[:base_url] == "/users"
      assert config[:size] == :lg
      assert config[:position] == :center
    end

    test "stores slideover config" do
      config = SlideoverPage.__inertia_modal__()
      assert config[:slideover] == true
      assert config[:position] == :right
      assert config[:size] == :lg
      assert config[:base_url] == "/settings"
      assert config[:close_button] == true
      assert config[:close_explicitly] == false
    end

    test "stores dynamic base_url as function" do
      config = DynamicBaseUrlPage.__inertia_modal__()
      assert is_function(config[:base_url], 1)
      assert config[:base_url].(%{"id" => "42"}) == "/users/42"
      assert config[:size] == :md
    end

    test "returns nil when no modal configured" do
      assert NoModalPage.__inertia_modal__() == nil
    end
  end

  describe "__inertia_modal__/0" do
    test "returns modal config for modal pages" do
      assert is_list(ModalPage.__inertia_modal__())
    end

    test "returns nil for non-modal pages" do
      assert NoModalPage.__inertia_modal__() == nil
    end
  end

  describe "modal_config/2" do
    test "stores overrides in conn.private" do
      conn = %Plug.Conn{private: %{}}
      conn = NbInertia.Page.modal_config(conn, base_url: "/new-url", size: :xl)
      assert conn.private[:nb_inertia_page_modal_overrides] == [base_url: "/new-url", size: :xl]
    end

    test "modal config overrides work in mount/2" do
      conn = %Plug.Conn{private: %{}}
      result = ModalConfigOverridePage.mount(conn, %{})
      assert %Plug.Conn{} = result

      assert result.private[:nb_inertia_page_modal_overrides] == [
               base_url: "/overridden",
               size: :xl
             ]

      assert result.private[:nb_inertia_page_props] == %{data: %{value: "test"}}
    end
  end

  describe "modal action helpers" do
    test "close_modal/1 is importable in action/3" do
      # ModalWithActionPage.action/3 uses close_modal — verify it compiles
      assert ModalWithActionPage.__inertia_has_action__() == true
    end

    test "redirect_modal_success/3 is importable in action/3" do
      # Verified by compilation of ModalWithActionPage
      assert ModalWithActionPage.__inertia_has_action__() == true
    end

    test "redirect_modal_error/3 is importable in action/3" do
      # Verified by compilation of ModalWithActionPage
      assert ModalWithActionPage.__inertia_has_action__() == true
    end
  end

  # ══════════════════════════════════════════════════════════
  # Tests — Shared Props
  # ══════════════════════════════════════════════════════════

  describe "shared module macro" do
    test "accumulates shared modules" do
      modules = SharedModulePage.__inertia_shared_modules__()
      assert modules == [NbInertia.PagePhase3Test.MockSharedProps]
    end

    test "accumulates multiple shared modules in order" do
      modules = MultipleSharedModulesPage.__inertia_shared_modules__()

      assert modules == [
               NbInertia.PagePhase3Test.MockSharedProps,
               NbInertia.PagePhase3Test.AnotherSharedProps
             ]
    end

    test "returns empty list when no shared modules" do
      assert NoSharedPage.__inertia_shared_modules__() == []
    end
  end

  describe "__inertia_shared_modules__/0" do
    test "returns shared modules list" do
      assert is_list(SharedModulePage.__inertia_shared_modules__())
    end
  end

  describe "shared inline props" do
    test "stores inline shared prop declarations" do
      inline = InlineSharedPage.__inertia_shared_inline__()
      assert is_list(inline)
      assert length(inline) == 2

      locale_prop = Enum.find(inline, &(&1.name == :locale))
      assert locale_prop.type == :string

      api_prop = Enum.find(inline, &(&1.name == :api_version))
      assert api_prop.type == :string
    end

    test "inline shared props do not interfere with page props" do
      # The page's own props should be unaffected by shared do...end
      props = InlineSharedPage.__inertia_props__()
      assert length(props) == 1
      assert hd(props).name == :items
    end

    test "returns nil when no inline shared props" do
      assert NoSharedPage.__inertia_shared_inline__() == nil
    end

    test "inline shared props are applied at runtime when declared with sources" do
      conn =
        RuntimeInlineSharedPage
        |> inertia_conn(locale: "en")
        |> NbInertia.PageController.show(%{})

      page = Jason.decode!(conn.resp_body)

      assert page["props"]["items"] == ["a", "b"]
      assert page["props"]["locale"] == "en"
      assert page["props"]["apiVersion"] == "v1"
      assert Enum.sort(page["sharedProps"]) == Enum.sort(["apiVersion", "locale"])
    end

    test "shared props are included in modal responses" do
      conn =
        RuntimeSharedModalPage
        |> modal_inertia_conn(locale: "fr")
        |> NbInertia.PageController.show(%{})

      page = Jason.decode!(conn.resp_body)
      modal_props = get_in(page, ["props", "_nb_modal", "props"])

      assert modal_props["items"] == ["a", "b"]
      assert modal_props["locale"] == "fr"
      assert modal_props["theme"] == "default"
    end
  end

  describe "__inertia_shared_inline__/0" do
    test "returns inline shared props" do
      assert is_list(InlineSharedPage.__inertia_shared_inline__())
    end

    test "returns nil when not declared" do
      assert NoSharedPage.__inertia_shared_inline__() == nil
    end
  end

  describe "shared prop collision validation" do
    test "raises when inline shared props collide with page props" do
      code = """
      defmodule TestInlineSharedPropCollision do
        use NbInertia.Page

        shared do
          prop :locale, :string, from: :assigns
        end

        prop :locale, :string

        def mount(_conn, _params) do
          %{locale: "en"}
        end
      end
      """

      assert_raise CompileError, ~r/Prop name collision detected/, fn ->
        Code.compile_string(code)
      end
    end
  end

  # ══════════════════════════════════════════════════════════
  # Tests — Precognition
  # ══════════════════════════════════════════════════════════

  describe "precognition in Page modules" do
    test "precognition macro is available in action/3" do
      # PrecognitionPage compiles successfully with precognition macro
      assert PrecognitionPage.__inertia_has_action__() == true
    end

    test "precognition with field filtering compiles" do
      assert PrecognitionWithFieldsPage.__inertia_has_action__() == true
    end

    test "precognition_request?/1 is available" do
      # Verify the function is importable by checking PrecognitionPage compiled
      conn = %Plug.Conn{private: %{precognition: false}}
      refute NbInertia.Plugs.Precognition.precognition_request?(conn)
    end

    test "precognition_fields/1 is available" do
      conn = %Plug.Conn{private: %{precognition_validate_only: ["name", "email"]}}
      assert NbInertia.Plugs.Precognition.precognition_fields(conn) == ["name", "email"]
    end

    test "precognition returns redirect for non-precognition request" do
      conn =
        Plug.Test.conn(:post, "/users", %{"user" => %{"name" => "test"}})
        |> Plug.Conn.put_private(:precognition, false)
        |> Plug.Conn.put_private(:precognition_validate_only, nil)

      result = PrecognitionPage.action(conn, %{"user" => %{"name" => "test"}}, :create)
      # For non-precognition requests, the do block runs, which redirects
      assert %Plug.Conn{} = result
      assert result.status == 302
    end

    test "precognition returns 422 for precognition request with errors" do
      conn =
        Plug.Test.conn(:post, "/users", %{"user" => %{"name" => "test"}})
        |> Plug.Conn.put_private(:precognition, true)
        |> Plug.Conn.put_private(:precognition_validate_only, nil)

      result = PrecognitionPage.action(conn, %{"user" => %{"name" => "test"}}, :create)
      assert %Plug.Conn{} = result
      assert result.status == 422
      assert result.state == :sent
    end
  end

  # ══════════════════════════════════════════════════════════
  # Tests — History Controls
  # ══════════════════════════════════════════════════════════

  describe "history controls — module-level" do
    test "encrypt_history option is stored" do
      opts = HistoryPage.__inertia_options__()
      assert opts.encrypt_history == true
    end

    test "clear_history option is stored" do
      opts = HistoryPage.__inertia_options__()
      assert opts.clear_history == true
    end

    test "preserve_fragment option is stored" do
      opts = HistoryPage.__inertia_options__()
      assert opts.preserve_fragment == true
    end
  end

  describe "history controls — per-request overrides" do
    test "encrypt_history/1 works in mount/2" do
      conn = %Plug.Conn{private: %{}}
      result = HistoryOverridePage.mount(conn, %{})
      assert %Plug.Conn{} = result
      assert result.private[:inertia_encrypt_history] == true
    end

    test "clear_history/1 works in mount/2" do
      conn = %Plug.Conn{private: %{}}
      result = HistoryOverridePage.mount(conn, %{})
      assert %Plug.Conn{} = result
      assert result.private[:inertia_clear_history] == true
    end

    test "preserve_fragment/1 works in mount/2" do
      conn = %Plug.Conn{private: %{}}
      result = HistoryOverridePage.mount(conn, %{})
      assert %Plug.Conn{} = result
      assert result.private[:inertia_preserve_fragment] == true
    end
  end

  # ══════════════════════════════════════════════════════════
  # Tests — Additional Helpers
  # ══════════════════════════════════════════════════════════

  describe "additional helpers" do
    test "mark_shared_prop_keys/2 is available in mount/2" do
      conn = %Plug.Conn{private: %{}}
      result = HelpersPage.mount(conn, %{})
      assert %Plug.Conn{} = result
      assert result.private[:inertia_shared_prop_keys] == [:locale, :user]
    end

    test "force_inertia_redirect/1 is available in mount/2" do
      conn = %Plug.Conn{private: %{}}
      result = HelpersPage.mount(conn, %{})
      assert %Plug.Conn{} = result
      assert result.private[:inertia_force_redirect] == true
    end
  end
end
