defmodule NbInertia.Plugs.FlashTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias NbInertia.Flash

  # Helper to set up a conn that NbInertia.Plug can process.
  # NbInertia.Plug expects conn.assigns.flash to exist (set by :fetch_live_flash).
  defp setup_conn(method, path, session \\ %{}) do
    conn(method, path)
    |> init_test_session(session)
    |> assign(:flash, %{})
    |> NbInertia.Plug.call([])
  end

  describe "flash loading via NbInertia.Plug" do
    test "loads flash from session" do
      conn = setup_conn(:get, "/", %{nb_inertia_flash: %{"message" => "From session!"}})
      assert Flash.get_inertia_flash(conn) == %{"message" => "From session!"}
    end

    test "clears flash from session after loading" do
      conn = setup_conn(:get, "/", %{nb_inertia_flash: %{"message" => "From session!"}})
      assert get_session(conn, :nb_inertia_flash) == nil
    end

    test "handles missing session flash gracefully" do
      conn = setup_conn(:get, "/", %{})
      assert Flash.get_inertia_flash(conn) == %{}
    end
  end

  describe "flash persistence via NbInertia.Plug" do
    test "persists flash on 302 redirect" do
      conn =
        setup_conn(:get, "/")
        |> Flash.inertia_flash(:message, "Hello!")
        |> put_status(302)
        |> resp(302, "Redirecting")
        |> send_resp()

      assert get_session(conn, :nb_inertia_flash) == %{"message" => "Hello!"}
    end

    test "persists flash on 301 redirect" do
      conn =
        setup_conn(:get, "/")
        |> Flash.inertia_flash(:message, "Hello!")
        |> put_status(301)
        |> resp(301, "Moved")
        |> send_resp()

      assert get_session(conn, :nb_inertia_flash) == %{"message" => "Hello!"}
    end

    test "does not persist flash on 200 response" do
      conn =
        setup_conn(:get, "/")
        |> Flash.inertia_flash(:message, "Hello!")
        |> put_status(200)
        |> resp(200, "OK")
        |> send_resp()

      assert get_session(conn, :nb_inertia_flash) == nil
    end

    test "does not persist empty flash" do
      conn =
        setup_conn(:get, "/")
        |> put_status(302)
        |> resp(302, "Redirecting")
        |> send_resp()

      assert get_session(conn, :nb_inertia_flash) == nil
    end
  end

  describe "redirect persistence scenarios" do
    test "flash survives POST -> redirect -> GET flow" do
      # Step 1: POST request, set flash, redirect
      conn1 =
        setup_conn(:post, "/users")
        |> Flash.inertia_flash(:message, "User created!")
        |> put_status(302)
        |> resp(302, "")
        |> send_resp()

      session_flash = get_session(conn1, :nb_inertia_flash)
      assert session_flash == %{"message" => "User created!"}

      # Step 2: GET request with persisted session — flash should be available
      conn2 = setup_conn(:get, "/users/1", %{nb_inertia_flash: session_flash})
      assert Flash.get_inertia_flash(conn2) == %{"message" => "User created!"}
      assert get_session(conn2, :nb_inertia_flash) == nil
    end
  end
end
