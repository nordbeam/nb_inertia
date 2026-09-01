defmodule NbInertia.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  defp inertia_conn(method \\ :get, path \\ "/") do
    version =
      conn(:get, "/")
      |> init_test_session(%{})
      |> assign(:flash, %{})
      |> NbInertia.Plug.call([])
      |> then(& &1.private[:inertia_version])

    method
    |> conn(path)
    |> init_test_session(%{})
    |> assign(:flash, %{})
    |> put_req_header("x-inertia", "true")
    |> put_req_header("x-inertia-version", version)
    |> NbInertia.Plug.call([])
  end

  describe "redirect handling" do
    test "does not crash on 3xx responses without a location header" do
      conn =
        inertia_conn()
        |> resp(302, "")
        |> send_resp()

      assert conn.status == 302
      assert get_resp_header(conn, "location") == []
      assert get_resp_header(conn, "x-inertia-location") == []
      assert get_resp_header(conn, "x-inertia-redirect") == []
    end

    test "external fragment redirects use the v3 location response" do
      conn =
        inertia_conn()
        |> put_resp_header("location", "https://example.com/docs#install")
        |> resp(302, "")
        |> send_resp()

      assert conn.status == 409

      assert get_resp_header(conn, "x-inertia-location") == [
               "https://example.com/docs#install"
             ]

      assert get_resp_header(conn, "x-inertia-redirect") == []
    end

    test "prefetch responses do not trigger fragment redirects" do
      conn =
        inertia_conn()
        |> put_private(:inertia_prefetch, true)
        |> put_resp_header("location", "/docs#install")
        |> resp(302, "")
        |> send_resp()

      assert conn.status == 302
      assert get_resp_header(conn, "x-inertia-redirect") == []
    end

    test "empty successful Inertia responses redirect back to the referer" do
      conn =
        inertia_conn(:post, "/actions")
        |> put_req_header("referer", "https://example.test/users?page=2#ignored")
        |> resp(200, "")
        |> send_resp()

      assert conn.status == 303
      assert get_resp_header(conn, "location") == ["/users?page=2"]
    end
  end

  test "sets Vary: X-Inertia for ordinary HTML responses" do
    conn =
      conn(:get, "/")
      |> init_test_session(%{})
      |> assign(:flash, %{})
      |> NbInertia.Plug.call([])

    assert get_resp_header(conn, "vary") == ["X-Inertia"]
  end

  test "exposes the same asset version used by the plug" do
    conn =
      conn(:get, "/")
      |> init_test_session(%{})
      |> assign(:flash, %{})
      |> NbInertia.Plug.call([])

    assert conn.private[:inertia_version] == NbInertia.Plug.asset_version()
  end

  test "merges X-Inertia with existing Vary response values" do
    conn =
      conn(:get, "/")
      |> init_test_session(%{})
      |> assign(:flash, %{})
      |> put_resp_header("vary", "Accept-Encoding, Precognition")
      |> NbInertia.Plug.call([])
      |> send_resp(200, "ok")

    assert get_resp_header(conn, "vary") == ["Accept-Encoding, Precognition, X-Inertia"]
  end

  test "persists clearHistory and preserveFragment through redirects" do
    redirected =
      inertia_conn()
      |> NbInertia.CoreController.clear_history()
      |> NbInertia.CoreController.preserve_fragment()
      |> put_resp_header("location", "/next")
      |> resp(302, "")
      |> send_resp()

    session = get_session(redirected)
    assert session["inertia_clear_history"] == true
    assert session["inertia_preserve_fragment"] == true

    next_conn =
      conn(:get, "/next")
      |> init_test_session(session)
      |> assign(:flash, %{})
      |> NbInertia.Plug.call([])

    assert next_conn.private[:inertia_clear_history] == true
    assert next_conn.private[:inertia_preserve_fragment] == true
  end
end
