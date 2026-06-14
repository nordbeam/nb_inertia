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
  end
end
