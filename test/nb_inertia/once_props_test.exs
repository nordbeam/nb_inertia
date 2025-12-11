defmodule NbInertia.OncePropsTest do
  @moduledoc """
  Tests for once props functionality.

  Once props are client-cached props that persist across page navigations,
  ideal for data that rarely changes, is expensive to compute, or is large.
  """
  use ExUnit.Case, async: true

  import NbInertia.CoreController

  describe "inertia_once/1" do
    test "creates once prop with default config" do
      fun = fn -> [:a, :b, :c] end
      result = inertia_once(fun)

      assert {:once, config} = result
      assert config.callback == fun
      assert config.fresh == false
      assert config.until == nil
      assert config.as == nil
    end

    test "raises for non-zero-arity functions" do
      assert_raise ArgumentError, fn ->
        inertia_once(fn _x -> :ok end)
      end
    end

    test "raises for non-function values" do
      assert_raise ArgumentError, fn ->
        inertia_once("not a function")
      end
    end
  end

  describe "inertia_once/2" do
    test "creates once prop with fresh option" do
      fun = fn -> :data end
      result = inertia_once(fun, fresh: true)

      assert {:once, config} = result
      assert config.fresh == true
    end

    test "creates once prop with as option (string)" do
      fun = fn -> :data end
      result = inertia_once(fun, as: "cached_data")

      assert {:once, config} = result
      assert config.as == "cached_data"
    end

    test "creates once prop with as option (atom)" do
      fun = fn -> :data end
      result = inertia_once(fun, as: :cached_data)

      assert {:once, config} = result
      assert config.as == "cached_data"
    end

    test "creates once prop with until option (keyword duration)" do
      fun = fn -> :data end
      result = inertia_once(fun, until: [hours: 24])

      assert {:once, config} = result
      assert is_integer(config.until)
      # Should be roughly 24 hours from now (within a few seconds)
      now = System.system_time(:millisecond)
      expected = now + 24 * 3_600_000
      assert_in_delta config.until, expected, 5000
    end

    test "creates once prop with until option (DateTime)" do
      fun = fn -> :data end
      future = DateTime.add(DateTime.utc_now(), 3600, :second)
      result = inertia_once(fun, until: future)

      assert {:once, config} = result
      assert config.until == DateTime.to_unix(future, :millisecond)
    end

    test "creates once prop with until option (Unix ms timestamp)" do
      fun = fn -> :data end
      timestamp = 1_700_000_000_000
      result = inertia_once(fun, until: timestamp)

      assert {:once, config} = result
      assert config.until == timestamp
    end

    test "creates once prop with all options" do
      fun = fn -> :data end

      result =
        inertia_once(fun, fresh: true, until: [days: 1], as: "my_data")

      assert {:once, config} = result
      assert config.fresh == true
      assert config.as == "my_data"
      assert is_integer(config.until)
    end
  end

  describe "once_fresh/1,2" do
    test "sets fresh to true by default" do
      result =
        inertia_once(fn -> :data end)
        |> once_fresh()

      assert {:once, config} = result
      assert config.fresh == true
    end

    test "sets fresh to specified boolean" do
      result =
        inertia_once(fn -> :data end)
        |> once_fresh(false)

      assert {:once, config} = result
      assert config.fresh == false
    end

    test "works with defer_once props" do
      result =
        inertia_defer(fn -> :data end)
        |> defer_once()
        |> once_fresh(true)

      assert {:defer_once, {_fun, "default", config}} = result
      assert config.fresh == true
    end
  end

  describe "once_until/2" do
    test "sets expiration with duration keyword" do
      result =
        inertia_once(fn -> :data end)
        |> once_until(hours: 12)

      assert {:once, config} = result
      now = System.system_time(:millisecond)
      expected = now + 12 * 3_600_000
      assert_in_delta config.until, expected, 5000
    end

    test "sets expiration with DateTime" do
      future = DateTime.add(DateTime.utc_now(), 7200, :second)

      result =
        inertia_once(fn -> :data end)
        |> once_until(future)

      assert {:once, config} = result
      assert config.until == DateTime.to_unix(future, :millisecond)
    end

    test "sets expiration with days" do
      result =
        inertia_once(fn -> :data end)
        |> once_until(days: 7)

      assert {:once, config} = result
      now = System.system_time(:millisecond)
      expected = now + 7 * 86_400_000
      assert_in_delta config.until, expected, 5000
    end

    test "sets expiration with minutes" do
      result =
        inertia_once(fn -> :data end)
        |> once_until(minutes: 30)

      assert {:once, config} = result
      now = System.system_time(:millisecond)
      expected = now + 30 * 60_000
      assert_in_delta config.until, expected, 5000
    end

    test "sets expiration with seconds" do
      result =
        inertia_once(fn -> :data end)
        |> once_until(seconds: 300)

      assert {:once, config} = result
      now = System.system_time(:millisecond)
      expected = now + 300 * 1000
      assert_in_delta config.until, expected, 5000
    end

    test "works with defer_once props" do
      result =
        inertia_defer(fn -> :data end)
        |> defer_once()
        |> once_until(hours: 6)

      assert {:defer_once, {_fun, "default", config}} = result
      assert is_integer(config.until)
    end
  end

  describe "once_as/2" do
    test "sets custom key with string" do
      result =
        inertia_once(fn -> :data end)
        |> once_as("shared_data")

      assert {:once, config} = result
      assert config.as == "shared_data"
    end

    test "sets custom key with atom" do
      result =
        inertia_once(fn -> :data end)
        |> once_as(:shared_data)

      assert {:once, config} = result
      assert config.as == "shared_data"
    end

    test "works with defer_once props" do
      result =
        inertia_defer(fn -> :data end)
        |> defer_once()
        |> once_as("my_key")

      assert {:defer_once, {_fun, "default", config}} = result
      assert config.as == "my_key"
    end
  end

  describe "defer_once/1" do
    test "converts defer prop to defer_once" do
      result =
        inertia_defer(fn -> :data end)
        |> defer_once()

      assert {:defer_once, {fun, "default", config}} = result
      assert is_function(fun, 0)
      assert config.fresh == false
      assert config.until == nil
      assert config.as == nil
    end

    test "preserves defer group" do
      result =
        inertia_defer(fn -> :data end, "slow")
        |> defer_once()

      assert {:defer_once, {_fun, "slow", _config}} = result
    end

    test "raises for non-defer props" do
      assert_raise ArgumentError, fn ->
        defer_once(fn -> :data end)
      end
    end
  end

  describe "pipe-friendly chaining" do
    test "supports full pipeline" do
      result =
        inertia_once(fn -> [:plans] end)
        |> once_fresh(true)
        |> once_until(hours: 24)
        |> once_as("subscription_plans")

      assert {:once, config} = result
      assert config.fresh == true
      assert config.as == "subscription_plans"
      assert is_integer(config.until)
    end

    test "supports defer_once full pipeline" do
      result =
        inertia_defer(fn -> [:permissions] end, "auth")
        |> defer_once()
        |> once_fresh(false)
        |> once_until(days: 1)
        |> once_as("user_permissions")

      assert {:defer_once, {_fun, "auth", config}} = result
      assert config.fresh == false
      assert config.as == "user_permissions"
      assert is_integer(config.until)
    end
  end
end
