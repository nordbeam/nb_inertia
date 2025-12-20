defmodule NbInertia.FlashTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias NbInertia.Flash

  describe "inertia_flash/3 (single key-value)" do
    test "sets flash data with atom key" do
      conn = conn(:get, "/")
      conn = Flash.inertia_flash(conn, :message, "Hello!")

      assert Flash.get_inertia_flash(conn) == %{"message" => "Hello!"}
    end

    test "sets flash data with string key" do
      conn = conn(:get, "/")
      conn = Flash.inertia_flash(conn, "message", "Hello!")

      assert Flash.get_inertia_flash(conn) == %{"message" => "Hello!"}
    end

    test "accumulates multiple flash values" do
      conn =
        conn(:get, "/")
        |> Flash.inertia_flash(:message, "Hello!")
        |> Flash.inertia_flash(:new_user_id, 123)

      flash = Flash.get_inertia_flash(conn)
      assert flash["message"] == "Hello!"
      assert flash["new_user_id"] == 123
    end

    test "overwrites existing key" do
      conn =
        conn(:get, "/")
        |> Flash.inertia_flash(:message, "First")
        |> Flash.inertia_flash(:message, "Second")

      assert Flash.get_inertia_flash(conn) == %{"message" => "Second"}
    end
  end

  describe "inertia_flash/2 (map or keyword list)" do
    test "sets flash data from map" do
      conn = conn(:get, "/")
      conn = Flash.inertia_flash(conn, %{message: "Hello!", new_id: 42})

      flash = Flash.get_inertia_flash(conn)
      assert flash["message"] == "Hello!"
      assert flash["new_id"] == 42
    end

    test "sets flash data from keyword list" do
      conn = conn(:get, "/")
      conn = Flash.inertia_flash(conn, message: "Hello!", status: "success")

      flash = Flash.get_inertia_flash(conn)
      assert flash["message"] == "Hello!"
      assert flash["status"] == "success"
    end

    test "merges with existing flash data" do
      conn =
        conn(:get, "/")
        |> Flash.inertia_flash(:existing, "value")
        |> Flash.inertia_flash(new_key: "new_value")

      flash = Flash.get_inertia_flash(conn)
      assert flash["existing"] == "value"
      assert flash["new_key"] == "new_value"
    end

    test "supports nested values" do
      conn = conn(:get, "/")

      conn =
        Flash.inertia_flash(conn, %{
          toast: %{type: "success", message: "User created!"}
        })

      flash = Flash.get_inertia_flash(conn)
      assert flash["toast"] == %{type: "success", message: "User created!"}
    end
  end

  describe "get_inertia_flash/1" do
    test "returns empty map when no flash set" do
      conn = conn(:get, "/")
      assert Flash.get_inertia_flash(conn) == %{}
    end

    test "returns flash data when set" do
      conn =
        conn(:get, "/")
        |> Flash.inertia_flash(:message, "Hello!")

      assert Flash.get_inertia_flash(conn) == %{"message" => "Hello!"}
    end
  end

  describe "put_inertia_flash/2" do
    test "replaces all flash data" do
      conn =
        conn(:get, "/")
        |> Flash.inertia_flash(:old, "value")
        |> Flash.put_inertia_flash(%{"new" => "data"})

      assert Flash.get_inertia_flash(conn) == %{"new" => "data"}
    end
  end

  describe "clear/1" do
    test "clears all flash data" do
      conn =
        conn(:get, "/")
        |> Flash.inertia_flash(:message, "Hello!")
        |> Flash.clear()

      assert Flash.get_inertia_flash(conn) == %{}
    end
  end

  describe "has_flash?/1" do
    test "returns false when no flash" do
      conn = conn(:get, "/")
      refute Flash.has_flash?(conn)
    end

    test "returns true when flash exists" do
      conn =
        conn(:get, "/")
        |> Flash.inertia_flash(:message, "Hello!")

      assert Flash.has_flash?(conn)
    end

    test "returns false after clear" do
      conn =
        conn(:get, "/")
        |> Flash.inertia_flash(:message, "Hello!")
        |> Flash.clear()

      refute Flash.has_flash?(conn)
    end
  end

  describe "session persistence" do
    test "persist_to_session stores flash in session" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{})
        |> Flash.inertia_flash(:message, "Hello!")
        |> Flash.persist_to_session()

      session_flash = get_session(conn, :nb_inertia_flash)
      assert session_flash == %{"message" => "Hello!"}
    end

    test "persist_to_session does nothing when no flash" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{})
        |> Flash.persist_to_session()

      assert get_session(conn, :nb_inertia_flash) == nil
    end

    test "load_from_session loads flash and clears session" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{nb_inertia_flash: %{"message" => "From session!"}})
        |> Flash.load_from_session()

      assert Flash.get_inertia_flash(conn) == %{"message" => "From session!"}
      assert get_session(conn, :nb_inertia_flash) == nil
    end

    test "load_from_session handles missing session data" do
      conn =
        conn(:get, "/")
        |> init_test_session(%{})
        |> Flash.load_from_session()

      assert Flash.get_inertia_flash(conn) == %{}
    end
  end

  describe "get_flash_for_response/2" do
    test "returns Inertia flash data" do
      conn =
        conn(:get, "/")
        |> Flash.inertia_flash(:message, "Hello!")

      flash = Flash.get_flash_for_response(conn)
      assert flash == %{"message" => "Hello!"}
    end

    test "includes Phoenix flash when configured" do
      conn =
        conn(:get, "/")
        |> assign(:flash, %{"info" => "Phoenix flash"})
        |> Flash.inertia_flash(:message, "Inertia flash")

      flash = Flash.get_flash_for_response(conn, include_phoenix_flash: true)

      assert flash["info"] == "Phoenix flash"
      assert flash["message"] == "Inertia flash"
    end

    test "excludes Phoenix flash when configured" do
      conn =
        conn(:get, "/")
        |> assign(:flash, %{"info" => "Phoenix flash"})
        |> Flash.inertia_flash(:message, "Inertia flash")

      flash = Flash.get_flash_for_response(conn, include_phoenix_flash: false)

      refute Map.has_key?(flash, "info")
      assert flash["message"] == "Inertia flash"
    end

    test "Inertia flash takes precedence over Phoenix flash" do
      conn =
        conn(:get, "/")
        |> assign(:flash, %{"message" => "Phoenix"})
        |> Flash.inertia_flash(:message, "Inertia")

      flash = Flash.get_flash_for_response(conn, include_phoenix_flash: true)

      assert flash["message"] == "Inertia"
    end

    test "camelizes keys when configured" do
      conn =
        conn(:get, "/")
        |> put_private(:inertia_camelize_props, true)
        |> Flash.inertia_flash(:new_user_id, 123)

      flash = Flash.get_flash_for_response(conn, camelize: true)

      assert flash["newUserId"] == 123
      refute Map.has_key?(flash, "new_user_id")
    end
  end
end
