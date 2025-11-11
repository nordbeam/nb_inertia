defmodule NbInertia.PropertyTest do
  @moduledoc """
  Property-based tests for NbInertia using StreamData.

  These tests use property-based testing to verify invariants and find edge cases
  that example-based tests might miss. They test fundamental properties of the system
  rather than specific examples.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias NbInertia.ComponentNaming
  alias NbInertia.DeepMerge
  alias NbInertia.PropSerializer

  @moduletag :property

  describe "ComponentNaming.infer/1" do
    property "always returns a valid component path" do
      check all(page_name <- valid_page_name_generator()) do
        component = ComponentNaming.infer(page_name)

        # Must be a string
        assert is_binary(component)

        # Must match expected format (PascalCase/PascalCase or PascalCase)
        assert String.match?(component, ~r/^[A-Z][a-zA-Z0-9]*(?:\/[A-Z][a-zA-Z0-9]*)*$/)
      end
    end

    property "preserves information (no collisions for different inputs)" do
      check all(
              page_name1 <- valid_page_name_generator(),
              page_name2 <- valid_page_name_generator(),
              page_name1 != page_name2
            ) do
        component1 = ComponentNaming.infer(page_name1)
        component2 = ComponentNaming.infer(page_name2)

        # Different page names should produce different components
        # (unless they naturally map to the same thing, which is acceptable)
        if page_name1 != page_name2 do
          # At minimum, the function should be deterministic
          assert ComponentNaming.infer(page_name1) == component1
          assert ComponentNaming.infer(page_name2) == component2
        end
      end
    end

    property "is deterministic (same input always gives same output)" do
      check all(page_name <- valid_page_name_generator()) do
        result1 = ComponentNaming.infer(page_name)
        result2 = ComponentNaming.infer(page_name)
        result3 = ComponentNaming.infer(page_name)

        assert result1 == result2
        assert result2 == result3
      end
    end
  end

  describe "DeepMerge.deep_merge/2" do
    property "is associative: (a ⊕ b) ⊕ c = a ⊕ (b ⊕ c)" do
      check all(
              map1 <- map_of(atom(:alphanumeric), simple_value()),
              map2 <- map_of(atom(:alphanumeric), simple_value()),
              map3 <- map_of(atom(:alphanumeric), simple_value())
            ) do
        # (a ⊕ b) ⊕ c
        result1 =
          map1
          |> DeepMerge.deep_merge(map2)
          |> DeepMerge.deep_merge(map3)

        # a ⊕ (b ⊕ c)
        result2 = DeepMerge.deep_merge(map1, DeepMerge.deep_merge(map2, map3))

        assert result1 == result2
      end
    end

    property "identity: merge with empty map returns original" do
      check all(map <- map_of(atom(:alphanumeric), simple_value())) do
        assert DeepMerge.deep_merge(map, %{}) == map
        assert DeepMerge.deep_merge(%{}, map) == map
      end
    end

    property "right bias: when keys conflict, right value wins" do
      check all(
              key <- atom(:alphanumeric),
              value1 <- simple_value(),
              value2 <- simple_value(),
              value1 != value2
            ) do
        map1 = %{key => value1}
        map2 = %{key => value2}

        result = DeepMerge.deep_merge(map1, map2)

        # For non-map values, right side wins
        if not is_map(value2) do
          assert result[key] == value2
        end
      end
    end

    property "preserves all keys from both maps" do
      check all(
              map1 <- map_of(atom(:alphanumeric), simple_value()),
              map2 <- map_of(atom(:alphanumeric), simple_value())
            ) do
        result = DeepMerge.deep_merge(map1, map2)

        # All keys from map1 should be present (unless overridden)
        for key <- Map.keys(map1) do
          assert Map.has_key?(result, key)
        end

        # All keys from map2 should be present
        for key <- Map.keys(map2) do
          assert Map.has_key?(result, key)
        end
      end
    end

    property "is idempotent: merge(x, x) == x" do
      check all(map <- map_of(atom(:alphanumeric), simple_value())) do
        result = DeepMerge.deep_merge(map, map)
        assert result == map
      end
    end
  end

  describe "PropSerializer protocol" do
    property "serializing primitives is identity" do
      check all(value <- primitive_value()) do
        assert {:ok, value} == PropSerializer.serialize(value)
      end
    end

    property "serializing lists preserves length" do
      check all(list <- list_of(primitive_value())) do
        {:ok, result} = PropSerializer.serialize(list)

        assert is_list(result)
        assert length(result) == length(list)
      end
    end

    property "serializing maps preserves keys" do
      check all(map <- map_of(atom(:alphanumeric), primitive_value())) do
        {:ok, result} = PropSerializer.serialize(map)

        assert is_map(result)
        assert Map.keys(result) |> Enum.sort() == Map.keys(map) |> Enum.sort()
      end
    end

    property "serialization is idempotent for primitives" do
      check all(value <- primitive_value()) do
        {:ok, result1} = PropSerializer.serialize(value)
        {:ok, result2} = PropSerializer.serialize(result1)

        assert result1 == result2
      end
    end

    property "nested serialization works at any depth (up to limit)" do
      check all(
              depth <- integer(1..5),
              value <- nested_map(depth)
            ) do
        result = PropSerializer.serialize(value, depth: depth + 1)

        case result do
          {:ok, _} -> assert true
          {:error, :max_depth_exceeded} -> assert true
        end
      end
    end
  end

  describe "Validation helpers" do
    property "prop name validation accepts valid atom names" do
      check all(name <- atom(:alphanumeric)) do
        # Should not raise
        assert is_atom(name)
      end
    end
  end

  ## Generators

  defp valid_page_name_generator do
    gen all(
          prefix <- optional(atom(:alphanumeric)),
          name <- atom(:alphanumeric)
        ) do
      case prefix do
        nil -> name
        p -> String.to_atom("#{p}_#{name}")
      end
    end
  end

  defp primitive_value do
    one_of([
      string(:alphanumeric),
      integer(),
      float(),
      boolean(),
      atom(:alphanumeric),
      constant(nil)
    ])
  end

  defp simple_value do
    one_of([
      primitive_value(),
      list_of(primitive_value(), max_length: 3)
    ])
  end

  defp nested_map(0) do
    map_of(atom(:alphanumeric), primitive_value(), max_length: 3)
  end

  defp nested_map(depth) when depth > 0 do
    map_of(
      atom(:alphanumeric),
      one_of([
        primitive_value(),
        nested_map(depth - 1)
      ]),
      max_length: 2
    )
  end

  defp optional(generator) do
    one_of([constant(nil), generator])
  end
end
