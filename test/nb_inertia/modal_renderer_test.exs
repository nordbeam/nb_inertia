defmodule NbInertia.ModalRendererTest do
  use ExUnit.Case, async: false

  alias NbInertia.Modal
  alias NbInertia.Modal.HttpClient

  @endpoint NbInertia.ModalRendererTest.Endpoint

  defmodule SessionController do
    use Phoenix.Controller, formats: [:html]

    def login(conn, %{"id" => user_id}) do
      conn
      |> put_session("user_id", user_id)
      |> text("ok")
    end
  end

  defmodule UsersIndexPage do
    use NbInertia.Page, component: "Users/Index"

    prop(:users, :list)
    prop(:current_user_id, :string)
    prop(:base_request, :boolean)

    def mount(conn, _params) do
      %{
        users: [%{id: 1, name: "Ada"}],
        current_user_id: conn.assigns.current_user_id,
        base_request: NbInertia.Modal.Renderer.base_request?(conn)
      }
    end
  end

  defmodule UsersNewPage do
    use NbInertia.Page, component: "Users/New"

    prop(:form, :map)
    prop(:viewer_id, :string)

    modal(
      base_url: "/users",
      size: :lg,
      position: :center
    )

    def mount(conn, _params) do
      %{
        form: %{name: ""},
        viewer_id: conn.assigns.current_user_id
      }
    end
  end

  defmodule Router do
    use Phoenix.Router

    import NbInertia.Router

    pipeline :browser do
      plug(:accepts, ["html"])

      plug(Plug.Session,
        store: :cookie,
        key: "_nb_inertia_modal_renderer_test",
        signing_salt: "modal renderer test"
      )

      plug(:fetch_session)
      plug(:load_current_user)
      plug(NbInertia.Plug)
    end

    scope "/" do
      pipe_through(:browser)

      get("/login/:id", NbInertia.ModalRendererTest.SessionController, :login)
      inertia("/users", NbInertia.ModalRendererTest.UsersIndexPage)
      inertia("/users/new", NbInertia.ModalRendererTest.UsersNewPage)
    end

    defp load_current_user(conn, _opts) do
      assign(conn, :current_user_id, get_session(conn, "user_id"))
    end
  end

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :nb_inertia

    plug(NbInertia.ModalRendererTest.Router)
  end

  import Phoenix.ConnTest
  import Plug.Conn

  setup_all do
    previous_endpoint = Application.get_env(:nb_inertia, :endpoint)
    previous_endpoint_config = Application.get_env(:nb_inertia, Endpoint)

    Application.put_env(:nb_inertia, :endpoint, Endpoint)

    Application.put_env(:nb_inertia, Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    start_supervised!(Endpoint)

    on_exit(fn ->
      restore_env(:endpoint, previous_endpoint)
      restore_env(Endpoint, previous_endpoint_config)
    end)

    :ok
  end

  describe "XHR modal rendering" do
    test "composes the base page through the Phoenix endpoint" do
      conn =
        "42"
        |> build_session_conn()
        |> put_req_header("accept", "text/html, application/xhtml+xml")
        |> put_req_header("x-inertia", "true")
        |> put_req_header("x-inertia-version", NbInertia.Config.default_version())
        |> get("/users/new")

      assert get_resp_header(conn, "x-inertia") == ["true"]
      assert get_resp_header(conn, Modal.modal_header()) == ["true"]
      assert get_resp_header(conn, Modal.modal_base_url_header()) == ["/users"]

      page = Jason.decode!(conn.resp_body)

      assert page["component"] == "Users/Index"
      assert page["url"] == "/users/new"
      assert page["props"]["users"] == [%{"id" => 1, "name" => "Ada"}]
      assert page["props"]["currentUserId"] == "42"
      assert page["props"]["baseRequest"] == true

      assert_modal_data(page["props"]["_nb_modal"], "42")
    end
  end

  describe "direct modal URL rendering" do
    test "composes the base page HTML through the Phoenix endpoint" do
      conn =
        "42"
        |> build_session_conn()
        |> put_req_header("accept", "text/html, application/xhtml+xml")
        |> get("/users/new")

      assert get_resp_header(conn, Modal.modal_header()) == ["true"]
      assert get_resp_header(conn, Modal.modal_base_url_header()) == ["/users"]
      assert {:ok, page} = HttpClient.extract_page_data_from_html(conn.resp_body)

      assert page["component"] == "Users/Index"
      assert page["url"] == "/users/new"
      assert page["props"]["users"] == [%{"id" => 1, "name" => "Ada"}]
      assert page["props"]["currentUserId"] == "42"
      assert page["props"]["baseRequest"] == true

      assert_modal_data(page["props"]["_nb_modal"], "42")
    end
  end

  defp assert_modal_data(modal, expected_user_id) do
    assert modal["component"] == "Users/New"
    assert modal["url"] == "/users/new"
    assert modal["baseUrl"] == "/users"
    assert modal["props"]["form"] == %{"name" => ""}
    assert modal["props"]["viewerId"] == expected_user_id
    assert modal["config"]["size"] == "lg"
    assert modal["config"]["position"] == "center"
  end

  defp build_session_conn(user_id) do
    build_conn()
    |> get("/login/#{user_id}")
    |> recycle()
  end

  defp restore_env(key, nil), do: Application.delete_env(:nb_inertia, key)
  defp restore_env(key, value), do: Application.put_env(:nb_inertia, key, value)
end
