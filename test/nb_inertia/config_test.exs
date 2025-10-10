defmodule NbInertia.ConfigTest do
  use ExUnit.Case, async: false

  alias NbInertia.Config

  describe "get/2" do
    test "returns configured value" do
      Application.put_env(:nb_inertia, :test_key, :test_value)
      assert Config.get(:test_key) == :test_value
      Application.delete_env(:nb_inertia, :test_key)
    end

    test "returns default when key not set" do
      assert Config.get(:nonexistent, :default) == :default
    end
  end

  describe "camelize_props?/0" do
    test "defaults to true" do
      Application.delete_env(:nb_inertia, :camelize_props)
      assert Config.camelize_props?() == true
    end

    test "returns configured value" do
      Application.put_env(:nb_inertia, :camelize_props, false)
      assert Config.camelize_props?() == false
      Application.delete_env(:nb_inertia, :camelize_props)
    end
  end
end
