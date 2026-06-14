defmodule NbInertia.ModalPropsTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  defmodule UserSerializer do
    use NbSerializer.Serializer

    schema do
      field(:first_name, :string)
    end
  end

  defmodule OptsEchoSerializer do
    def serialize(data, opts) do
      %{data: data, opts: Map.new(opts)}
    end
  end

  defmodule ModalBaseEndpoint do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, _opts) do
      page =
        Jason.encode!(%{
          component: "Users/Index",
          props: %{users: []},
          url: request_path(conn),
          version: "test-version"
        })

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, page)
    end

    defp request_path(conn) do
      IO.iodata_to_binary([conn.request_path, request_url_qs(conn.query_string)])
    end

    defp request_url_qs(""), do: ""
    defp request_url_qs(qs), do: [??, qs]
  end

  defmodule ModalController do
    use NbInertia.Controller

    inertia_page :users_show, component: "Users/Show" do
      prop(:user, :map)
    end

    def atom_page_ref(conn) do
      render_inertia_modal(conn, :users_show, [user: %{id: 1, first_name: "Ada"}],
        base_url: "/users"
      )
    end

    def string_component_with_mixed_props_and_opts(conn) do
      render_inertia_modal(conn, "Users/Show",
        user: {UserSerializer, %{first_name: "Ada"}},
        base_url: "/users"
      )
    end

    def string_component_with_serializer_tuple(conn) do
      render_inertia_modal(
        conn,
        "Users/Show",
        [
          payload: {OptsEchoSerializer, "value", opts: [scope: "full"]}
        ],
        base_url: "/users"
      )
    end

    def string_component_with_styling(conn) do
      render_inertia_modal(conn, "Users/Show", [user: %{id: 1}],
        base_url: "/users",
        max_width: "42rem",
        padding_classes: "p-8",
        panel_classes: "rounded border",
        backdrop_classes: "bg-slate-950/80"
      )
    end
  end

  setup do
    previous = Application.get_env(:nb_inertia, :camelize_props)

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(:nb_inertia, :camelize_props)
      else
        Application.put_env(:nb_inertia, :camelize_props, previous)
      end
    end)
  end

  defp modal_conn(path \\ "/users/1") do
    conn(:get, path)
    |> put_req_header("x-inertia", "true")
    |> put_req_header("x-inertia-version", "test-version")
    |> put_private(:phoenix_endpoint, ModalBaseEndpoint)
  end

  defp decoded_page(conn), do: Jason.decode!(conn.resp_body)
  defp decoded_modal(conn), do: decoded_page(conn)["props"]["_nb_modal"]

  test "camelizes top-level modal prop keys when enabled" do
    Application.put_env(:nb_inertia, :camelize_props, true)

    assert NbInertia.Controller.build_modal_props(
             edited_user: {UserSerializer, %{first_name: "Ada"}}
           ) == %{editedUser: %{firstName: "Ada"}}
  end

  test "keeps top-level modal prop keys unchanged when camelization is disabled" do
    Application.put_env(:nb_inertia, :camelize_props, false)

    assert NbInertia.Controller.build_modal_props(
             edited_user: {UserSerializer, %{first_name: "Ada"}}
           ) == %{edited_user: %{first_name: "Ada"}}
  end

  test "passes through non-serializer tuples unchanged" do
    Application.put_env(:nb_inertia, :camelize_props, false)

    assert NbInertia.Controller.build_modal_props(status: {:ok, %{id: 1}}) == %{
             status: {:ok, %{id: 1}}
           }
  end

  test "supports helper tuples with nested serializer opts" do
    Application.put_env(:nb_inertia, :camelize_props, false)

    result =
      NbInertia.Controller.build_modal_props(
        payload: {OptsEchoSerializer, "value", opts: [scope: :full]}
      )

    assert result[:payload][:data] == "value"
    assert result[:payload][:opts][:scope] == :full
    assert result[:payload][:opts][:camelize] == false
    assert result[:payload][:opts][:keep_raw_markers] == true
  end

  test "atom page ref modal preserves props and full request path in composed page data" do
    Application.put_env(:nb_inertia, :camelize_props, true)

    conn =
      "/users/1?tab=activity&sort=asc"
      |> modal_conn()
      |> ModalController.atom_page_ref()

    page = decoded_page(conn)
    modal = page["props"]["_nb_modal"]

    assert page["component"] == "Users/Index"
    assert page["url"] == "/users/1?tab=activity&sort=asc"
    assert modal["component"] == "Users/Show"
    assert modal["url"] == "/users/1?tab=activity&sort=asc"
    assert modal["props"]["user"] == %{"id" => 1, "first_name" => "Ada"}
  end

  test "string component modal preserves and serializes mixed keyword props" do
    Application.put_env(:nb_inertia, :camelize_props, true)

    modal =
      modal_conn()
      |> ModalController.string_component_with_mixed_props_and_opts()
      |> decoded_modal()

    assert modal["component"] == "Users/Show"
    assert modal["baseUrl"] == "/users"
    assert modal["props"]["user"] == %{"firstName" => "Ada"}
  end

  test "string component modal serializes helper tuple props with opts" do
    Application.put_env(:nb_inertia, :camelize_props, false)

    modal =
      modal_conn()
      |> ModalController.string_component_with_serializer_tuple()
      |> decoded_modal()

    assert modal["props"]["payload"]["data"] == "value"
    assert modal["props"]["payload"]["opts"]["scope"] == "full"
    assert modal["props"]["payload"]["opts"]["camelize"] == false
    assert modal["props"]["payload"]["opts"]["keep_raw_markers"] == true
  end

  test "modal styling options pass through as frontend-compatible camelCase config" do
    conn =
      modal_conn()
      |> ModalController.string_component_with_styling()

    config = decoded_modal(conn)["config"]

    assert config["maxWidth"] == "42rem"
    assert config["paddingClasses"] == "p-8"
    assert config["panelClasses"] == "rounded border"
    assert config["backdropClasses"] == "bg-slate-950/80"

    [config_header] = get_resp_header(conn, "x-inertia-modal-config")
    header_config = Jason.decode!(config_header)

    assert header_config["maxWidth"] == "42rem"
    assert header_config["paddingClasses"] == "p-8"
    assert header_config["panelClasses"] == "rounded border"
    assert header_config["backdropClasses"] == "bg-slate-950/80"
  end
end
