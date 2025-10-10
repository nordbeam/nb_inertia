defmodule NbInertiaTest do
  use ExUnit.Case, async: true

  doctest NbInertia

  test "returns version" do
    assert is_binary(NbInertia.version())
  end
end
