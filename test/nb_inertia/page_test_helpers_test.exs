defmodule NbInertia.PageTestHelpersTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import NbInertia.PageTest

  # ── Test Page Modules ──────────────────────────────

  defmodule MapReturnPage do
    use NbInertia.Page, component: "Test/MapReturn"

    prop(:users, :list)
    prop(:count, :integer)

    def mount(_conn, _params) do
      %{users: ["alice", "bob"], count: 2}
    end
  end

  defmodule ConnReturnPage do
    use NbInertia.Page, component: "Test/ConnReturn"

    prop(:users, :list)

    def mount(conn, _params) do
      conn
      |> encrypt_history()
      |> props(%{users: ["alice", "bob"]})
    end
  end

  defmodule FromPropsPage do
    use NbInertia.Page, component: "Test/FromProps"

    prop(:title, :string)
    prop(:locale, :string, from: :assigns)
    prop(:timezone, :string, from: :user_timezone)

    def mount(_conn, _params) do
      %{title: "Hello"}
    end
  end

  defmodule DefaultPropsPage do
    use NbInertia.Page, component: "Test/DefaultProps"

    prop(:name, :string)
    prop(:theme, :string, default: "light")
    prop(:page_size, :integer, default: 25)

    def mount(_conn, _params) do
      %{name: "Test"}
    end
  end

  defmodule DefaultOverridePage do
    use NbInertia.Page, component: "Test/DefaultOverride"

    prop(:name, :string)
    prop(:theme, :string, default: "light")

    def mount(_conn, _params) do
      %{name: "Test", theme: "dark"}
    end
  end

  defmodule RedirectMountPage do
    use NbInertia.Page, component: "Test/RedirectMount"

    prop(:user, :map)

    def mount(conn, %{"id" => "not_found"}) do
      redirect(conn, to: "/users")
    end

    def mount(_conn, %{"id" => id}) do
      %{user: %{id: id, name: "User #{id}"}}
    end
  end

  defmodule WithActionPage do
    use NbInertia.Page, component: "Test/WithAction"

    prop(:item, :map)

    def mount(_conn, _params) do
      %{item: %{id: 1, name: "Test"}}
    end

    def action(conn, _params, :create) do
      Phoenix.Controller.redirect(conn, to: "/items/1")
    end

    def action(_conn, _params, :update) do
      {:error, %{name: ["is required"], email: ["can't be blank"]}}
    end

    def action(_conn, _params, :delete) do
      {:error, %{base: ["cannot delete"]}}
    end
  end

  defmodule NoActionPage do
    use NbInertia.Page, component: "Test/NoAction"

    prop(:data, :string)

    def mount(_conn, _params) do
      %{data: "hello"}
    end
  end

  defmodule ParamsPage do
    use NbInertia.Page, component: "Test/Params"

    prop(:user, :map)

    def mount(_conn, %{"id" => id, "tab" => tab}) do
      %{user: %{id: id, tab: tab}}
    end

    def mount(_conn, %{"id" => id}) do
      %{user: %{id: id, tab: "default"}}
    end
  end

  # ── mount_page/3 Tests ──────────────────────────────

  describe "mount_page/3" do
    test "returns props map when mount/2 returns a map" do
      conn = conn(:get, "/")
      props = mount_page(MapReturnPage, conn)

      assert props == %{users: ["alice", "bob"], count: 2}
    end

    test "returns props map when mount/2 returns a conn pipeline" do
      conn = conn(:get, "/")
      props = mount_page(ConnReturnPage, conn)

      assert props == %{users: ["alice", "bob"]}
    end

    test "resolves from: :assigns props" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.assign(:locale, "en")
        |> Plug.Conn.assign(:user_timezone, "America/New_York")

      props = mount_page(FromPropsPage, conn)

      assert props[:title] == "Hello"
      assert props[:locale] == "en"
      assert props[:timezone] == "America/New_York"
    end

    test "resolves default: props when not provided by mount" do
      conn = conn(:get, "/")
      props = mount_page(DefaultPropsPage, conn)

      assert props[:name] == "Test"
      assert props[:theme] == "light"
      assert props[:page_size] == 25
    end

    test "mount-provided values override defaults" do
      conn = conn(:get, "/")
      props = mount_page(DefaultOverridePage, conn)

      assert props[:name] == "Test"
      assert props[:theme] == "dark"
    end

    test "passes params to mount/2" do
      conn = conn(:get, "/users/42")
      props = mount_page(ParamsPage, conn, %{"id" => "42", "tab" => "settings"})

      assert props[:user] == %{id: "42", tab: "settings"}
    end

    test "passes default params" do
      conn = conn(:get, "/users/42")
      props = mount_page(ParamsPage, conn, %{"id" => "42"})

      assert props[:user] == %{id: "42", tab: "default"}
    end

    test "raises when mount/2 redirects" do
      conn = conn(:get, "/users/not_found")

      assert_raise RuntimeError, ~r/mount\/2 returned a redirect/, fn ->
        mount_page(RedirectMountPage, conn, %{"id" => "not_found"})
      end
    end

    test "raises for non-page module" do
      conn = conn(:get, "/")

      assert_raise ArgumentError, ~r/is not a Page module/, fn ->
        mount_page(Enum, conn)
      end
    end
  end

  # ── call_mount/3 Tests ──────────────────────────────

  describe "call_mount/3" do
    test "returns {:ok, map} for map return" do
      conn = conn(:get, "/")
      assert {:ok, %{users: _, count: _}} = call_mount(MapReturnPage, conn)
    end

    test "returns {:ok, conn} for conn return" do
      conn = conn(:get, "/")
      assert {:ok, %Plug.Conn{}} = call_mount(ConnReturnPage, conn)
    end

    test "returns {:redirect, conn} for redirect" do
      conn = conn(:get, "/users/not_found")

      assert {:redirect, %Plug.Conn{}} =
               call_mount(RedirectMountPage, conn, %{"id" => "not_found"})
    end

    test "normal mount returns props" do
      conn = conn(:get, "/users/1")

      assert {:ok, %{user: %{id: "1", name: "User 1"}}} =
               call_mount(RedirectMountPage, conn, %{"id" => "1"})
    end
  end

  # ── call_action/4 Tests ──────────────────────────────

  describe "call_action/4" do
    test "returns conn for redirect (successful action)" do
      conn = conn(:post, "/items")
      result = call_action(WithActionPage, conn, %{}, :create)

      assert %Plug.Conn{} = result
    end

    test "returns {:error, errors} for validation failure" do
      conn = conn(:patch, "/items/1")
      result = call_action(WithActionPage, conn, %{}, :update)

      assert {:error, errors} = result
      assert errors[:name] == ["is required"]
      assert errors[:email] == ["can't be blank"]
    end

    test "returns {:error, errors} for delete failure" do
      conn = conn(:delete, "/items/1")
      result = call_action(WithActionPage, conn, %{}, :delete)

      assert {:error, %{base: ["cannot delete"]}} = result
    end

    test "raises for page without action/3" do
      conn = conn(:post, "/")

      assert_raise ArgumentError, ~r/does not define action\/3/, fn ->
        call_action(NoActionPage, conn, %{}, :create)
      end
    end

    test "raises for non-page module" do
      conn = conn(:post, "/")

      assert_raise ArgumentError, ~r/is not a Page module/, fn ->
        call_action(Enum, conn, %{}, :create)
      end
    end
  end

  # ── assert_page_module/2 Tests ──────────────────────────────

  describe "assert_page_module/2" do
    test "passes when component matches the page module" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/MapReturn",
          props: %{users: [], count: 0}
        })

      assert assert_page_module(conn, MapReturnPage) == true
    end

    test "passes when both component and page_module match" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/WithAction",
          props: %{item: %{}}
        })
        |> Plug.Conn.put_private(:nb_inertia_page_module, WithActionPage)

      assert assert_page_module(conn, WithActionPage) == true
    end

    test "fails when component does not match" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/Other",
          props: %{}
        })

      assert_raise ExUnit.AssertionError, ~r/Expected Inertia page to be/, fn ->
        assert_page_module(conn, MapReturnPage)
      end
    end

    test "fails when page_module in conn does not match" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/MapReturn",
          props: %{}
        })
        |> Plug.Conn.put_private(:nb_inertia_page_module, ConnReturnPage)

      assert_raise ExUnit.AssertionError, ~r/Expected page module to be/, fn ->
        assert_page_module(conn, MapReturnPage)
      end
    end

    test "raises for non-page module" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_private(:inertia_page, %{component: "Enum", props: %{}})

      assert_raise ArgumentError, ~r/is not a Page module/, fn ->
        assert_page_module(conn, Enum)
      end
    end
  end

  # ── assert_page_modal/3 Tests ──────────────────────────────

  describe "assert_page_modal/3" do
    test "passes when response is modal for page module" do
      conn =
        conn(:get, "/users/1")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/WithAction",
          props: %{item: %{id: 1}}
        })
        |> Plug.Conn.put_resp_header("x-inertia-modal", "true")
        |> Plug.Conn.put_resp_header("x-inertia-modal-base-url", "/items")

      assert assert_page_modal(conn, WithActionPage) == true
    end

    test "passes with base_url option" do
      conn =
        conn(:get, "/users/1")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/WithAction",
          props: %{item: %{id: 1}}
        })
        |> Plug.Conn.put_resp_header("x-inertia-modal", "true")
        |> Plug.Conn.put_resp_header("x-inertia-modal-base-url", "/items")

      assert assert_page_modal(conn, WithActionPage, base_url: "/items") == true
    end

    test "passes with config option" do
      conn =
        conn(:get, "/users/1")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/WithAction",
          props: %{item: %{id: 1}}
        })
        |> Plug.Conn.put_resp_header("x-inertia-modal", "true")
        |> Plug.Conn.put_resp_header(
          "x-inertia-modal-config",
          Jason.encode!(%{"size" => "lg", "position" => "center"})
        )

      assert assert_page_modal(conn, WithActionPage, config: %{size: "lg"}) == true
    end

    test "fails when component matches but not a modal" do
      conn =
        conn(:get, "/items")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/WithAction",
          props: %{item: %{}}
        })

      assert_raise ExUnit.AssertionError, ~r/Expected response to be a modal/, fn ->
        assert_page_modal(conn, WithActionPage)
      end
    end

    test "fails when modal but wrong page module" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/Other",
          props: %{}
        })
        |> Plug.Conn.put_resp_header("x-inertia-modal", "true")

      assert_raise ExUnit.AssertionError, ~r/Expected Inertia page to be/, fn ->
        assert_page_modal(conn, WithActionPage)
      end
    end
  end

  # ── get_page_props/1 and get_page_component/1 Tests ─────────

  describe "get_page_props/1" do
    test "returns props from conn" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/Basic",
          props: %{users: [1, 2, 3], count: 3}
        })

      props = get_page_props(conn)
      assert props == %{users: [1, 2, 3], count: 3}
    end

    test "returns nil when no inertia page" do
      conn = conn(:get, "/")
      assert get_page_props(conn) == nil
    end
  end

  describe "get_page_component/1" do
    test "returns component name from conn" do
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Users/Index",
          props: %{}
        })

      assert get_page_component(conn) == "Users/Index"
    end

    test "returns nil when no inertia page" do
      conn = conn(:get, "/")
      assert get_page_component(conn) == nil
    end
  end

  # ── Backward Compatibility: Existing TestHelpers with Page modules ─────────

  describe "backward compatibility with NbInertia.TestHelpers" do
    # These tests verify that existing test helpers continue to work
    # with Page-module-rendered responses

    setup do
      conn =
        conn(:get, "/users")
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Test/MapReturn",
          props: %{users: ["alice", "bob"], count: 2}
        })
        |> Plug.Conn.put_private(:nb_inertia_page_module, MapReturnPage)

      {:ok, conn: conn}
    end

    test "assert_inertia_page with string works", %{conn: conn} do
      # Existing string-based assertion should still work
      assert NbInertia.TestHelpers.assert_inertia_page(conn, "Test/MapReturn") == true
    end

    test "assert_inertia_props works", %{conn: conn} do
      assert NbInertia.TestHelpers.assert_inertia_props(conn, [:users, :count]) == true
    end

    test "assert_inertia_prop works", %{conn: conn} do
      assert NbInertia.TestHelpers.assert_inertia_prop(conn, :count, 2) == true
    end

    test "refute_inertia_prop works", %{conn: conn} do
      assert NbInertia.TestHelpers.refute_inertia_prop(conn, :missing_prop) == true
    end
  end

  # ── use NbInertia.PageTest Tests ─────────

  describe "__using__ macro" do
    test "module using NbInertia.PageTest has access to both helpers" do
      # Verify the module provides the expected functions
      assert function_exported?(NbInertia.PageTest, :mount_page, 2)
      assert function_exported?(NbInertia.PageTest, :mount_page, 3)
      assert function_exported?(NbInertia.PageTest, :call_mount, 2)
      assert function_exported?(NbInertia.PageTest, :call_mount, 3)
      assert function_exported?(NbInertia.PageTest, :call_action, 4)
      assert function_exported?(NbInertia.PageTest, :assert_page_module, 2)
      assert function_exported?(NbInertia.PageTest, :assert_page_modal, 2)
      assert function_exported?(NbInertia.PageTest, :assert_page_modal, 3)
      assert function_exported?(NbInertia.PageTest, :get_page_props, 1)
      assert function_exported?(NbInertia.PageTest, :get_page_component, 1)
    end
  end
end
