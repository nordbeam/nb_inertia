defmodule NbInertia.DslOptionsTest do
  @moduledoc """
  Tests for DSL options being applied at runtime.

  This tests the fix for the bug where DSL options like `defer: true`, `lazy: true`,
  `merge: true`, `partial: true` were only used for compile-time validation but
  not actually applied to prop values at runtime.
  """
  use ExUnit.Case, async: true

  import Plug.Test

  describe "assign_raw_prop_with_dsl_opts/4" do
    import NbInertia.Controller, only: [assign_raw_prop_with_dsl_opts: 4]

    test "applies defer: true option" do
      conn = conn(:get, "/")

      # Assign a prop with defer: true DSL option
      conn = assign_raw_prop_with_dsl_opts(conn, :stats, %{count: 10}, defer: true)

      # The prop should be wrapped in {:defer, {fn, "default"}}
      prop = conn.private[:inertia_shared][:stats]
      assert {:defer, {fun, "default"}} = prop
      assert is_function(fun, 0)
      assert fun.() == %{count: 10}
    end

    test "applies defer with group name option" do
      conn = conn(:get, "/")

      # Assign a prop with defer: "slow" DSL option
      conn = assign_raw_prop_with_dsl_opts(conn, :heavy_data, [1, 2, 3], defer: "slow")

      # The prop should be wrapped in {:defer, {fn, "slow"}}
      prop = conn.private[:inertia_shared][:heavy_data]
      assert {:defer, {fun, "slow"}} = prop
      assert is_function(fun, 0)
      assert fun.() == [1, 2, 3]
    end

    test "applies partial: true option" do
      conn = conn(:get, "/")

      # Assign a prop with partial: true DSL option
      conn = assign_raw_prop_with_dsl_opts(conn, :partial_data, "test", partial: true)

      # The prop should be wrapped in {:optional, fn} (Inertia.js internal)
      prop = conn.private[:inertia_shared][:partial_data]
      assert {:optional, fun} = prop
      assert is_function(fun, 0)
      assert fun.() == "test"
    end

    test "applies lazy: true option" do
      conn = conn(:get, "/")

      # Assign a prop with lazy: true DSL option
      conn = assign_raw_prop_with_dsl_opts(conn, :lazy_data, "lazy value", lazy: true)

      # The prop should be a function (for lazy evaluation)
      prop = conn.private[:inertia_shared][:lazy_data]
      assert is_function(prop, 0)
      assert prop.() == "lazy value"
    end

    test "applies merge: true option" do
      conn = conn(:get, "/")

      # Assign a prop with merge: true DSL option
      conn = assign_raw_prop_with_dsl_opts(conn, :settings, %{theme: "dark"}, merge: true)

      # The prop should be wrapped in {:merge, value}
      prop = conn.private[:inertia_shared][:settings]
      assert {:merge, %{theme: "dark"}} = prop
    end

    test "applies merge: :deep option" do
      conn = conn(:get, "/")

      # Assign a prop with merge: :deep DSL option
      conn =
        assign_raw_prop_with_dsl_opts(conn, :config, %{nested: %{key: "value"}}, merge: :deep)

      # The prop should be wrapped in {:deep_merge, value}
      prop = conn.private[:inertia_shared][:config]
      assert {:deep_merge, %{nested: %{key: "value"}}} = prop
    end

    test "combines defer with merge option" do
      conn = conn(:get, "/")

      # Assign a prop with both defer and merge options
      conn = assign_raw_prop_with_dsl_opts(conn, :data, %{x: 1}, defer: true, merge: true)

      # The prop should be wrapped in {:merge, {:defer, {fn, "default"}}}
      prop = conn.private[:inertia_shared][:data]
      assert {:merge, {:defer, {fun, "default"}}} = prop
      assert is_function(fun, 0)
      assert fun.() == %{x: 1}
    end

    test "preserves function values for defer" do
      conn = conn(:get, "/")

      # If value is already a function, it should be preserved
      fetch_fn = fn -> expensive_calculation() end
      conn = assign_raw_prop_with_dsl_opts(conn, :expensive, fetch_fn, defer: true)

      prop = conn.private[:inertia_shared][:expensive]
      assert {:defer, {^fetch_fn, "default"}} = prop
    end

    test "does not wrap when no special options" do
      conn = conn(:get, "/")

      # Assign a prop without special options
      conn = assign_raw_prop_with_dsl_opts(conn, :regular, "value", [])

      # The prop should be the plain value
      prop = conn.private[:inertia_shared][:regular]
      assert prop == "value"
    end

    test "defer takes precedence over partial" do
      conn = conn(:get, "/")

      # Both defer and partial specified (defer should win)
      conn = assign_raw_prop_with_dsl_opts(conn, :data, "value", defer: true, partial: true)

      prop = conn.private[:inertia_shared][:data]
      assert {:defer, {_fun, "default"}} = prop
    end

    test "applies once: true option" do
      conn = conn(:get, "/")

      conn = assign_raw_prop_with_dsl_opts(conn, :plans, [:basic, :pro], once: true)

      prop = conn.private[:inertia_shared][:plans]
      assert {:once, config} = prop
      assert is_function(config.callback, 0)
      assert config.callback.() == [:basic, :pro]
      assert config.fresh == false
      assert config.until == nil
      assert config.as == nil
    end

    test "applies once with fresh option" do
      conn = conn(:get, "/")

      conn = assign_raw_prop_with_dsl_opts(conn, :data, "value", once: [fresh: true])

      prop = conn.private[:inertia_shared][:data]
      assert {:once, config} = prop
      assert config.fresh == true
    end

    test "applies once with until option" do
      conn = conn(:get, "/")

      conn = assign_raw_prop_with_dsl_opts(conn, :data, "value", once: [until: [hours: 24]])

      prop = conn.private[:inertia_shared][:data]
      assert {:once, config} = prop
      assert is_integer(config.until)
      # Should be ~24 hours from now
      now = System.system_time(:millisecond)
      expected = now + 24 * 3_600_000
      assert_in_delta config.until, expected, 5000
    end

    test "applies once with as option" do
      conn = conn(:get, "/")

      conn = assign_raw_prop_with_dsl_opts(conn, :data, "value", once: [as: "cached_key"])

      prop = conn.private[:inertia_shared][:data]
      assert {:once, config} = prop
      assert config.as == "cached_key"
    end

    test "applies once with all options" do
      conn = conn(:get, "/")

      conn =
        assign_raw_prop_with_dsl_opts(conn, :plans, [:a, :b],
          once: [fresh: true, until: [days: 7], as: "plan_list"]
        )

      prop = conn.private[:inertia_shared][:plans]
      assert {:once, config} = prop
      assert config.fresh == true
      assert config.as == "plan_list"
      assert is_integer(config.until)
    end

    test "applies defer + once (defer_once)" do
      conn = conn(:get, "/")

      conn = assign_raw_prop_with_dsl_opts(conn, :heavy, %{data: 1}, defer: true, once: true)

      prop = conn.private[:inertia_shared][:heavy]
      assert {:defer_once, {fun, "default", config}} = prop
      assert is_function(fun, 0)
      assert fun.() == %{data: 1}
      assert config.fresh == false
    end

    test "applies defer + once with group and options" do
      conn = conn(:get, "/")

      conn =
        assign_raw_prop_with_dsl_opts(conn, :heavy, %{data: 1},
          defer: "slow",
          once: [fresh: true, as: "heavy_data"]
        )

      prop = conn.private[:inertia_shared][:heavy]
      assert {:defer_once, {fun, "slow", config}} = prop
      assert is_function(fun, 0)
      assert config.fresh == true
      assert config.as == "heavy_data"
    end

    test "once takes precedence over partial" do
      conn = conn(:get, "/")

      conn = assign_raw_prop_with_dsl_opts(conn, :data, "value", once: true, partial: true)

      prop = conn.private[:inertia_shared][:data]
      assert {:once, _config} = prop
    end

    test "once takes precedence over lazy" do
      conn = conn(:get, "/")

      conn = assign_raw_prop_with_dsl_opts(conn, :data, "value", once: true, lazy: true)

      prop = conn.private[:inertia_shared][:data]
      assert {:once, _config} = prop
    end

    test "once can be combined with merge" do
      conn = conn(:get, "/")

      conn = assign_raw_prop_with_dsl_opts(conn, :settings, %{a: 1}, once: true, merge: true)

      prop = conn.private[:inertia_shared][:settings]
      assert {:merge, {:once, config}} = prop
      assert is_function(config.callback, 0)
      assert config.callback.() == %{a: 1}
    end

    test "applies separate once_fresh, once_until, once_as DSL keys" do
      conn = conn(:get, "/")

      conn =
        assign_raw_prop_with_dsl_opts(conn, :data, "value",
          once: true,
          once_fresh: true,
          once_until: [hours: 12],
          once_as: "custom_key"
        )

      prop = conn.private[:inertia_shared][:data]
      assert {:once, config} = prop
      assert config.fresh == true
      assert config.as == "custom_key"
      assert is_integer(config.until)
    end

    defp expensive_calculation, do: :expensive_result
  end

  describe "DSL options integration with render_inertia" do
    # These tests verify that DSL options declared in inertia_page blocks
    # are properly applied when render_inertia is called

    defmodule TestController do
      use NbInertia.Controller

      # For testing, manually define the page and config functions
      # In a real app, these would be generated by inertia_page macro

      inertia_page :test_defer do
        prop(:deferred_stats, :map, defer: true)
        prop(:regular_prop, :string)
      end

      inertia_page :test_merge do
        prop(:mergeable_settings, :map, merge: true)
        prop(:deep_mergeable, :map, merge: :deep)
      end

      inertia_page :test_partial do
        prop(:partial_data, :map, partial: true)
        prop(:required_data, :string)
      end

      inertia_page :test_lazy do
        prop(:lazy_computed, :integer, lazy: true)
      end

      inertia_page :test_once do
        prop(:cached_plans, :list, once: true)
        prop(:cached_with_opts, :map, once: [fresh: true, as: "my_cache"])
      end

      inertia_page :test_defer_once do
        prop(:heavy_cached, :map, defer: true, once: true)
        prop(:heavy_with_group, :list, defer: "slow", once: [until: [hours: 24]])
      end
    end

    test "defer option from DSL is applied at runtime" do
      # Get the page config to verify DSL options are stored
      config = TestController.inertia_page_config(:test_defer)

      # Find the deferred_stats prop config
      deferred_prop = Enum.find(config.props, &(&1.name == :deferred_stats))
      assert Keyword.get(deferred_prop.opts, :defer) == true

      # The regular_prop should not have defer
      regular_prop = Enum.find(config.props, &(&1.name == :regular_prop))
      assert Keyword.get(regular_prop.opts, :defer, false) == false
    end

    test "merge options from DSL are stored correctly" do
      config = TestController.inertia_page_config(:test_merge)

      merge_prop = Enum.find(config.props, &(&1.name == :mergeable_settings))
      assert Keyword.get(merge_prop.opts, :merge) == true

      deep_merge_prop = Enum.find(config.props, &(&1.name == :deep_mergeable))
      assert Keyword.get(deep_merge_prop.opts, :merge) == :deep
    end

    test "partial option from DSL is stored correctly" do
      config = TestController.inertia_page_config(:test_partial)

      partial_prop = Enum.find(config.props, &(&1.name == :partial_data))
      assert Keyword.get(partial_prop.opts, :partial) == true

      required_prop = Enum.find(config.props, &(&1.name == :required_data))
      assert Keyword.get(required_prop.opts, :partial, false) == false
    end

    test "lazy option from DSL is stored correctly" do
      config = TestController.inertia_page_config(:test_lazy)

      lazy_prop = Enum.find(config.props, &(&1.name == :lazy_computed))
      assert Keyword.get(lazy_prop.opts, :lazy) == true
    end

    test "inertia_page_config returns nil for undeclared pages" do
      # Verify the catch-all clause works
      assert TestController.inertia_page_config(:nonexistent_page) == nil
    end

    test "once option from DSL is stored correctly" do
      config = TestController.inertia_page_config(:test_once)

      cached_prop = Enum.find(config.props, &(&1.name == :cached_plans))
      assert Keyword.get(cached_prop.opts, :once) == true

      cached_opts_prop = Enum.find(config.props, &(&1.name == :cached_with_opts))
      once_opts = Keyword.get(cached_opts_prop.opts, :once)
      assert is_list(once_opts)
      assert Keyword.get(once_opts, :fresh) == true
      assert Keyword.get(once_opts, :as) == "my_cache"
    end

    test "defer + once options from DSL are stored correctly" do
      config = TestController.inertia_page_config(:test_defer_once)

      heavy_prop = Enum.find(config.props, &(&1.name == :heavy_cached))
      assert Keyword.get(heavy_prop.opts, :defer) == true
      assert Keyword.get(heavy_prop.opts, :once) == true

      heavy_group_prop = Enum.find(config.props, &(&1.name == :heavy_with_group))
      assert Keyword.get(heavy_group_prop.opts, :defer) == "slow"
      once_opts = Keyword.get(heavy_group_prop.opts, :once)
      assert is_list(once_opts)
      assert Keyword.get(once_opts, :until) == [hours: 24]
    end
  end

  # Tests for assign_serialized with once option
  # Only run these tests if NbSerializer is available
  if Code.ensure_loaded?(NbSerializer) do
    describe "assign_serialized with once option" do
      defmodule TestPlanSerializer do
        use NbSerializer.Serializer

        schema do
          field(:id, :number)
          field(:name, :string)
          field(:price, :number)
        end
      end

      import NbInertia.Controller, only: [assign_serialized: 5]

      test "applies once: true option" do
        conn = conn(:get, "/")
        plans = [%{id: 1, name: "Basic", price: 10}, %{id: 2, name: "Pro", price: 50}]

        conn = assign_serialized(conn, :plans, TestPlanSerializer, plans, once: true)

        prop = conn.private[:inertia_shared][:plans]
        assert {:once, config} = prop
        assert is_function(config.callback, 0)

        # Verify serialization happens correctly
        result = config.callback.()
        assert is_list(result)
        assert length(result) == 2
        assert hd(result)[:name] == "Basic"
      end

      test "applies once with fresh option" do
        conn = conn(:get, "/")
        plans = [%{id: 1, name: "Basic", price: 10}]

        conn = assign_serialized(conn, :plans, TestPlanSerializer, plans, once: [fresh: true])

        prop = conn.private[:inertia_shared][:plans]
        assert {:once, config} = prop
        assert config.fresh == true
      end

      test "applies once with until option" do
        conn = conn(:get, "/")
        plans = [%{id: 1, name: "Basic", price: 10}]

        conn =
          assign_serialized(conn, :plans, TestPlanSerializer, plans, once: [until: [hours: 12]])

        prop = conn.private[:inertia_shared][:plans]
        assert {:once, config} = prop
        assert is_integer(config.until)
        now = System.system_time(:millisecond)
        expected = now + 12 * 3_600_000
        assert_in_delta config.until, expected, 5000
      end

      test "applies once with as option" do
        conn = conn(:get, "/")
        plans = [%{id: 1, name: "Basic", price: 10}]

        conn =
          assign_serialized(conn, :plans, TestPlanSerializer, plans, once: [as: "plan_cache"])

        prop = conn.private[:inertia_shared][:plans]
        assert {:once, config} = prop
        assert config.as == "plan_cache"
      end

      test "applies defer + once (defer_once)" do
        conn = conn(:get, "/")
        plans = [%{id: 1, name: "Basic", price: 10}]

        conn =
          assign_serialized(conn, :plans, TestPlanSerializer, plans, defer: true, once: true)

        prop = conn.private[:inertia_shared][:plans]
        assert {:defer_once, {fun, "default", config}} = prop
        assert is_function(fun, 0)
        assert config.fresh == false
      end

      test "applies defer + once with group and options" do
        conn = conn(:get, "/")
        plans = [%{id: 1, name: "Basic", price: 10}]

        conn =
          assign_serialized(conn, :plans, TestPlanSerializer, plans,
            defer: "slow",
            once: [fresh: true, until: [days: 1], as: "plans_cache"]
          )

        prop = conn.private[:inertia_shared][:plans]
        assert {:defer_once, {fun, "slow", config}} = prop
        assert is_function(fun, 0)
        assert config.fresh == true
        assert config.as == "plans_cache"
        assert is_integer(config.until)
      end

      test "once can be combined with merge" do
        conn = conn(:get, "/")
        plan = %{id: 1, name: "Basic", price: 10}

        conn =
          assign_serialized(conn, :plan, TestPlanSerializer, plan, once: true, merge: true)

        prop = conn.private[:inertia_shared][:plan]
        assert {:merge, {:once, config}} = prop
        assert is_function(config.callback, 0)
      end
    end
  end
end
