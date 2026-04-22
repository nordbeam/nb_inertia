defmodule NbInertia.ControllerRenderApiTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  defmodule RenderController do
    use NbInertia.Controller

    inertia_page :users_index do
      prop(:users, :list)
    end

    def atom_page(conn) do
      render_inertia(conn, :users_index, %{users: [%{id: 1}]})
    end

    def component_map(conn) do
      render_inertia(conn, "Users/Index", %{users: [%{id: 1}]})
    end

    def component_keyword(conn) do
      render_inertia(conn, "Users/Index", users: [%{id: 1}])
    end

    def component_explicit(conn) do
      render_inertia_component(conn, "Users/Index", [users: [%{id: 1}]], ssr: false)
    end
  end

  defmodule SharedLocaleProps do
    use NbInertia.SharedProps

    inertia_shared do
      prop(:locale, :string)
    end

    @impl NbInertia.SharedProps.Behaviour
    def build_props(conn, _opts) do
      %{locale: conn.assigns.locale}
    end
  end

  defmodule SharedController do
    use NbInertia.Controller

    include_shared_props(SharedLocaleProps)

    inertia_page :users_index do
      prop(:users, :list)
    end

    def index(conn) do
      render_inertia(conn, :users_index, users: [])
    end
  end

  defmodule DefaultsController do
    use NbInertia.Controller

    inertia_page :home do
      prop(:contact_form, :map, default: %{})
      prop(:locale, :string, from: :assigns)
      prop(:errors, :map, default: %{})
    end

    def show(conn) do
      render_inertia(conn, :home)
    end

    def invalid(conn) do
      conn
      |> assign_errors(%{name: "is required"})
      |> render_inertia(:home)
    end
  end

  if Code.ensure_loaded?(NbSerializer) do
    defmodule UserSerializer do
      use NbSerializer.Serializer

      schema do
        field(:id, :number)
        field(:name, :string)
      end
    end

    defmodule SerializedComponentController do
      use NbInertia.Controller

      def index(conn) do
        render_inertia_component(
          conn,
          "Users/Index",
          users: serialize(UserSerializer, [%{id: 1, name: "Ada"}])
        )
      end
    end
  end

  defp inertia_conn do
    version =
      conn(:get, "/")
      |> init_test_session(%{})
      |> assign(:flash, %{})
      |> NbInertia.Plug.call([])
      |> then(& &1.private[:inertia_version])

    conn(:get, "/")
    |> init_test_session(%{})
    |> assign(:flash, %{})
    |> put_req_header("x-inertia", "true")
    |> put_req_header("x-inertia-version", version)
    |> NbInertia.Plug.call([])
    |> put_private(:phoenix_action, :index)
    |> put_private(:phoenix_controller, __MODULE__)
  end

  defp page_props(conn) do
    conn.resp_body
    |> Jason.decode!()
    |> Map.fetch!("props")
  end

  test "atom page renders props from map syntax" do
    props = inertia_conn() |> RenderController.atom_page() |> page_props()

    assert props["users"] == [%{"id" => 1}]
  end

  test "string component renders props from map syntax" do
    props = inertia_conn() |> RenderController.component_map() |> page_props()

    assert props["users"] == [%{"id" => 1}]
  end

  test "string component renders props from keyword syntax" do
    props = inertia_conn() |> RenderController.component_keyword() |> page_props()

    assert props["users"] == [%{"id" => 1}]
  end

  test "string component mixed props and options raise a compile-time ambiguity error" do
    assert_raise CompileError, ~r/Ambiguous keyword list passed to render_inertia\/3/, fn ->
      defmodule AmbiguousComponentController do
        use NbInertia.Controller

        def index(conn) do
          render_inertia(conn, "Users/Index", users: [%{id: 1}], ssr: true)
        end
      end
    end
  end

  test "render_inertia_component allows explicit component props and options" do
    conn = inertia_conn() |> RenderController.component_explicit()
    props = page_props(conn)

    assert props["users"] == [%{"id" => 1}]
    assert conn.private[:nb_inertia_ssr_enabled] == false
  end

  test "include_shared_props registers shared prop modules without inertia_shared overloads" do
    conn =
      inertia_conn()
      |> assign(:locale, "en")
      |> SharedController.index()

    page = Jason.decode!(conn.resp_body)

    assert page["props"]["locale"] == "en"
    assert page["sharedProps"] == ["locale"]
  end

  test "atom page render materializes default and from assigns props at runtime" do
    props =
      inertia_conn()
      |> assign(:locale, "en")
      |> DefaultsController.show()
      |> page_props()

    assert props["contactForm"] == %{}
    assert props["locale"] == "en"
  end

  test "atom page render preserves assigned errors when page defaults include errors" do
    props =
      inertia_conn()
      |> DefaultsController.invalid()
      |> page_props()

    assert props["errors"] == %{"name" => "is required"}
  end

  if Code.ensure_loaded?(NbSerializer) do
    test "serialize/2 helper returns the serializer tuple shape accepted by component renders" do
      props =
        inertia_conn()
        |> __MODULE__.SerializedComponentController.index()
        |> page_props()

      assert props["users"] == [%{"id" => 1, "name" => "Ada"}]
    end
  end
end
