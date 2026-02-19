defmodule NbInertia.TestHelpersTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import NbInertia.TestHelpers

  setup do
    # Create a test connection
    conn = conn(:get, "/")

    {:ok, conn: conn}
  end

  describe "with_inertia_headers/1" do
    test "adds Inertia headers to the connection" do
      conn =
        conn(:get, "/")
        |> with_inertia_headers()

      assert Plug.Conn.get_req_header(conn, "x-inertia") == ["true"]
      assert Plug.Conn.get_req_header(conn, "x-inertia-version") == ["1.0"]
    end
  end

  describe "assert_inertia_page/2" do
    test "passes when component matches", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{}
        })

      assert assert_inertia_page(conn, "Posts/Index") == true
    end

    test "fails when component doesn't match", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{}
        })

      assert_raise ExUnit.AssertionError, ~r/Expected Inertia component/, fn ->
        assert_inertia_page(conn, "Users/Index")
      end
    end
  end

  describe "assert_inertia_props/2" do
    test "passes when all props are present", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{posts: [], total_count: 0, filter: "all"}
        })

      assert assert_inertia_props(conn, [:posts, :total_count]) == true
    end

    test "passes with string keys", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{"posts" => [], "totalCount" => 0}
        })

      assert assert_inertia_props(conn, ["posts", "totalCount"]) == true
    end

    test "fails when props are missing", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{posts: []}
        })

      assert_raise ExUnit.AssertionError, ~r/missing: \[:total_count\]/, fn ->
        assert_inertia_props(conn, [:posts, :total_count])
      end
    end
  end

  describe "assert_inertia_prop/3" do
    test "passes when prop value matches", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{total_count: 42, title: "Hello"}
        })

      assert assert_inertia_prop(conn, :total_count, 42) == true
      assert assert_inertia_prop(conn, :title, "Hello") == true
    end

    test "works with camelCase keys", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{totalCount: 42}
        })

      # Can assert using snake_case even when prop is camelCase
      assert assert_inertia_prop(conn, :total_count, 42) == true
      # Also works with the actual camelCase key
      assert assert_inertia_prop(conn, :totalCount, 42) == true
    end

    test "works with string keys", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{"totalCount" => 42}
        })

      assert assert_inertia_prop(conn, "totalCount", 42) == true
    end

    test "fails when prop value doesn't match", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{total_count: 42}
        })

      assert_raise ExUnit.AssertionError, ~r/Expected prop :total_count to equal 100/, fn ->
        assert_inertia_prop(conn, :total_count, 100)
      end
    end

    test "fails when prop doesn't exist", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{posts: []}
        })

      assert_raise ExUnit.AssertionError, ~r/Prop :missing not found/, fn ->
        assert_inertia_prop(conn, :missing, "value")
      end
    end
  end

  describe "refute_inertia_prop/2" do
    test "passes when prop is not present", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Users/Show",
          props: %{id: 1, name: "Alice", email: "alice@example.com"}
        })

      assert refute_inertia_prop(conn, :password) == true
      assert refute_inertia_prop(conn, :internal_data) == true
    end

    test "fails when prop is present", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Users/Show",
          props: %{password: "secret123"}
        })

      assert_raise ExUnit.AssertionError, ~r/Expected prop :password to NOT be present/, fn ->
        refute_inertia_prop(conn, :password)
      end
    end
  end

  describe "camelCase and snake_case conversion" do
    test "handles snake_case props when checking camelCase", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{total_count: 42}
        })

      # Can query using camelCase even when prop is snake_case
      assert assert_inertia_prop(conn, :totalCount, 42) == true
    end

    test "handles camelCase props when checking snake_case", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_private(:inertia_page, %{
          component: "Posts/Index",
          props: %{totalCount: 42}
        })

      # Can query using snake_case even when prop is camelCase
      assert assert_inertia_prop(conn, :total_count, 42) == true
    end
  end

  describe "assert_inertia_modal/2" do
    test "passes when response has modal headers", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_resp_header("x-inertia-modal", "true")
        |> Plug.Conn.put_resp_header("x-inertia-modal-base-url", "/users")

      assert assert_inertia_modal(conn) == true
    end

    test "passes with base_url option", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_resp_header("x-inertia-modal", "true")
        |> Plug.Conn.put_resp_header("x-inertia-modal-base-url", "/users")

      assert assert_inertia_modal(conn, base_url: "/users") == true
    end

    test "passes with config option", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_resp_header("x-inertia-modal", "true")
        |> Plug.Conn.put_resp_header("x-inertia-modal-config", Jason.encode!(%{"size" => "lg"}))

      assert assert_inertia_modal(conn, config: %{size: "lg"}) == true
    end

    test "fails when not a modal response", %{conn: conn} do
      assert_raise ExUnit.AssertionError, ~r/Expected response to be a modal response/, fn ->
        assert_inertia_modal(conn)
      end
    end
  end

  describe "refute_inertia_modal/1" do
    test "passes when not a modal response", %{conn: conn} do
      assert refute_inertia_modal(conn) == true
    end

    test "fails when modal response", %{conn: conn} do
      conn = Plug.Conn.put_resp_header(conn, "x-inertia-modal", "true")

      assert_raise ExUnit.AssertionError, ~r/Expected response to NOT be a modal response/, fn ->
        refute_inertia_modal(conn)
      end
    end
  end

  describe "assert_inertia_flash/2,3" do
    test "asserts flash key is present", %{conn: conn} do
      conn = Plug.Conn.put_private(conn, :nb_inertia_flash, %{"message" => "Hello!"})

      assert assert_inertia_flash(conn, :message) == true
      assert assert_inertia_flash(conn, "message") == true
    end

    test "asserts flash key with value", %{conn: conn} do
      conn = Plug.Conn.put_private(conn, :nb_inertia_flash, %{"message" => "Success!"})

      assert assert_inertia_flash(conn, :message, "Success!") == true
    end

    test "fails when flash key missing", %{conn: conn} do
      conn = Plug.Conn.put_private(conn, :nb_inertia_flash, %{})

      assert_raise ExUnit.AssertionError, ~r/Expected Inertia flash key/, fn ->
        assert_inertia_flash(conn, :message)
      end
    end

    test "fails when flash value doesn't match", %{conn: conn} do
      conn = Plug.Conn.put_private(conn, :nb_inertia_flash, %{"message" => "Hello"})

      assert_raise ExUnit.AssertionError, ~r/Expected Inertia flash :message to be/, fn ->
        assert_inertia_flash(conn, :message, "Goodbye")
      end
    end
  end

  describe "refute_inertia_flash/2" do
    test "passes when flash key not present", %{conn: conn} do
      conn = Plug.Conn.put_private(conn, :nb_inertia_flash, %{})

      assert refute_inertia_flash(conn, :error) == true
    end

    test "fails when flash key is present", %{conn: conn} do
      conn = Plug.Conn.put_private(conn, :nb_inertia_flash, %{"error" => "Bad"})

      assert_raise ExUnit.AssertionError, ~r/Expected Inertia flash key/, fn ->
        refute_inertia_flash(conn, :error)
      end
    end
  end

  describe "with_modal_headers/1" do
    test "adds modal request header", %{conn: conn} do
      conn = with_modal_headers(conn)
      assert Plug.Conn.get_req_header(conn, "x-inertia-modal-request") == ["true"]
    end
  end
end
