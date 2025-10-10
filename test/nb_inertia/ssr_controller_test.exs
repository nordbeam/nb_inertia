defmodule NbInertia.SSRControllerTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  import NbInertia.Controller

  describe "enable_ssr/1" do
    test "sets SSR enabled flag in conn private" do
      conn = conn(:get, "/")
      conn = enable_ssr(conn)

      assert conn.private[:nb_inertia_ssr_enabled] == true
    end

    test "can be chained with other conn operations" do
      conn =
        conn(:get, "/")
        |> enable_ssr()
        |> Plug.Conn.put_private(:other_key, :value)

      assert conn.private[:nb_inertia_ssr_enabled] == true
      assert conn.private[:other_key] == :value
    end
  end

  describe "disable_ssr/1" do
    test "sets SSR disabled flag in conn private" do
      conn = conn(:get, "/")
      conn = disable_ssr(conn)

      assert conn.private[:nb_inertia_ssr_enabled] == false
    end

    test "overrides previous enable_ssr call" do
      conn =
        conn(:get, "/")
        |> enable_ssr()
        |> disable_ssr()

      assert conn.private[:nb_inertia_ssr_enabled] == false
    end
  end

  describe "ssr_enabled?/1" do
    test "returns true when explicitly enabled" do
      conn =
        conn(:get, "/")
        |> enable_ssr()

      assert ssr_enabled?(conn) == true
    end

    test "returns false when explicitly disabled" do
      conn =
        conn(:get, "/")
        |> disable_ssr()

      assert ssr_enabled?(conn) == false
    end

    test "returns SSR module state when not explicitly set" do
      conn = conn(:get, "/")

      # Should return whatever NbInertia.SSR.ssr_enabled?() returns
      # The function handles the case when SSR process isn't running
      result = ssr_enabled?(conn)
      assert is_boolean(result)
      # In test environment without SSR configured, this should be false
      refute result
    end

    test "per-request setting takes precedence over global config" do
      # Even if SSR is globally enabled, disable_ssr should work
      conn =
        conn(:get, "/")
        |> disable_ssr()

      assert ssr_enabled?(conn) == false
    end
  end

  describe "SSR workflow" do
    test "typical enable flow" do
      conn =
        conn(:get, "/dashboard")
        |> enable_ssr()

      assert ssr_enabled?(conn)
    end

    test "typical disable flow" do
      conn =
        conn(:get, "/settings")
        |> disable_ssr()

      refute ssr_enabled?(conn)
    end

    test "conditional SSR based on request" do
      # Simulate enabling SSR only for certain pages
      enable_ssr_for_page = fn conn, page ->
        if page in ["Dashboard", "Profile"] do
          enable_ssr(conn)
        else
          disable_ssr(conn)
        end
      end

      dashboard_conn =
        conn(:get, "/dashboard")
        |> enable_ssr_for_page.("Dashboard")

      settings_conn =
        conn(:get, "/settings")
        |> enable_ssr_for_page.("Settings")

      assert ssr_enabled?(dashboard_conn)
      refute ssr_enabled?(settings_conn)
    end
  end
end
