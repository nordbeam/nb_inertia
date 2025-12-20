defmodule NbInertia.Plugs.FlashTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias NbInertia.Flash
  alias NbInertia.Plugs.Flash, as: FlashPlug

  describe "plug call/2" do
    test "loads flash from session" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{nb_inertia_flash: %{"message" => "From session!"}})
        |> FlashPlug.call([])

      assert Flash.get_inertia_flash(conn) == %{"message" => "From session!"}
    end

    test "clears flash from session after loading" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{nb_inertia_flash: %{"message" => "From session!"}})
        |> FlashPlug.call([])

      assert get_session(conn, :nb_inertia_flash) == nil
    end

    test "handles missing session flash gracefully" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{})
        |> FlashPlug.call([])

      assert Flash.get_inertia_flash(conn) == %{}
    end

    test "persists flash on 302 redirect" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{})
        |> FlashPlug.call([])
        |> Flash.inertia_flash(:message, "Hello!")

      # Simulate a redirect response
      conn =
        conn
        |> put_status(302)
        |> resp(302, "Redirecting")
        |> send_resp()

      assert get_session(conn, :nb_inertia_flash) == %{"message" => "Hello!"}
    end

    test "persists flash on 301 redirect" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{})
        |> FlashPlug.call([])
        |> Flash.inertia_flash(:message, "Hello!")

      conn =
        conn
        |> put_status(301)
        |> resp(301, "Moved")
        |> send_resp()

      assert get_session(conn, :nb_inertia_flash) == %{"message" => "Hello!"}
    end

    test "does not persist flash on 200 response" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{})
        |> FlashPlug.call([])
        |> Flash.inertia_flash(:message, "Hello!")

      conn =
        conn
        |> put_status(200)
        |> resp(200, "OK")
        |> send_resp()

      # Flash should not be persisted for non-redirect responses
      assert get_session(conn, :nb_inertia_flash) == nil
    end

    test "does not persist empty flash" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{})
        |> FlashPlug.call([])

      conn =
        conn
        |> put_status(302)
        |> resp(302, "Redirecting")
        |> send_resp()

      assert get_session(conn, :nb_inertia_flash) == nil
    end
  end

  describe "redirect persistence scenarios" do
    test "flash survives POST -> redirect -> GET flow" do
      # Step 1: Initial request with plug
      conn1 =
        conn(:post, "/users")
        |> init_test_session(%{})
        |> FlashPlug.call([])

      # Step 2: Set flash and redirect
      conn1 =
        conn1
        |> Flash.inertia_flash(:message, "User created!")

      # Simulate redirect
      conn1 =
        conn1
        |> put_status(302)
        |> resp(302, "")
        |> send_resp()

      # Get the session data that would be persisted
      session_flash = get_session(conn1, :nb_inertia_flash)
      assert session_flash == %{"message" => "User created!"}

      # Step 3: New request with persisted session
      conn2 =
        conn(:get, "/users/1")
        |> init_test_session(%{nb_inertia_flash: session_flash})
        |> FlashPlug.call([])

      # Flash should be available
      assert Flash.get_inertia_flash(conn2) == %{"message" => "User created!"}

      # Session should be cleared
      assert get_session(conn2, :nb_inertia_flash) == nil
    end
  end
end
