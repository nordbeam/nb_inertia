defmodule NbInertia.PropRuntimeTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias NbInertia.PropRuntime

  if Code.ensure_loaded?(NbSerializer) do
    defmodule UserSerializer do
      use NbSerializer.Serializer

      schema do
        field(:id, :number)
        field(:name, :string)
      end
    end

    defmodule SerializedSharedProps do
      use NbInertia.SharedProps

      inertia_shared do
        prop(:current_user, UserSerializer)
        prop(:locale, :string)
      end

      @impl NbInertia.SharedProps.Behaviour
      def build_props(conn, _opts) do
        %{
          current_user: conn.assigns.current_user,
          locale: conn.assigns.locale
        }
      end
    end
  end

  describe "apply_from_and_defaults/3" do
    test "fills missing props from assigns and defaults without overriding explicit values" do
      conn =
        conn(:get, "/")
        |> assign(:locale, "en")
        |> assign(:user_timezone, "UTC")

      prop_configs = [
        %{name: :locale, opts: [from: :assigns]},
        %{name: :timezone, opts: [from: :user_timezone]},
        %{name: :theme, opts: [default: "light"]}
      ]

      result =
        PropRuntime.apply_from_and_defaults(conn, %{theme: "dark"}, prop_configs)

      assert result == %{locale: "en", theme: "dark", timezone: "UTC"}
    end
  end

  describe "resolve_inline_shared_props/2" do
    test "resolves inline shared props from assigns and defaults" do
      conn =
        conn(:get, "/")
        |> assign(:locale, "en")

      inline_shared_props = [
        %{name: :locale, opts: [from: :assigns]},
        %{name: :api_version, opts: [default: "v1"]},
        %{name: :ignored, opts: []}
      ]

      assert PropRuntime.resolve_inline_shared_props(conn, inline_shared_props) == %{
               locale: "en",
               api_version: "v1"
             }
    end
  end

  if Code.ensure_loaded?(NbSerializer) do
    describe "resolve_shared_props/4" do
      test "shared prop modules expose serialize_props/2 for serializer-backed props" do
        assert function_exported?(__MODULE__.SerializedSharedProps, :serialize_props, 1)
        assert function_exported?(__MODULE__.SerializedSharedProps, :serialize_props, 2)
      end

      test "uses serialize_props from shared modules when available" do
        conn =
          conn(:get, "/")
          |> assign(:current_user, %{id: 1, name: "Alice"})
          |> assign(:locale, "en")

        shared_props =
          PropRuntime.resolve_shared_props(conn, [__MODULE__.SerializedSharedProps], nil)

        assert shared_props[:locale] == "en"
        assert shared_props[:current_user][:id] == 1
        assert shared_props[:current_user][:name] == "Alice"
      end
    end
  end
end
