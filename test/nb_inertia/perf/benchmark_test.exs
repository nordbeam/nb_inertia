defmodule NbInertia.Perf.BenchmarkTest do
  use ExUnit.Case, async: false

  alias NbInertia.Perf.Benchmark
  alias NbInertia.Perf.Budget
  alias NbInertia.Perf.Fixtures
  alias NbInertia.Perf.Fixtures.Item

  test "prop serializer recursion fixture serializes nested item structs" do
    {:ok, serialized} =
      :small
      |> Fixtures.serializer_value()
      |> NbInertia.PropSerializer.serialize([])

    assert %{users: [first_user | _], tree: tree} = serialized
    assert %{children: [first_child | _], metadata: %{snake_case_key: "value"}} = first_user
    assert %{children: [tree_child | _]} = tree
    assert is_map(first_user)
    assert is_map(first_child)
    assert is_map(tree)
    assert is_map(tree_child)
    refute item_struct_present?(serialized)
  end

  test "runs a lightweight benchmark scenario and reports memory/reduction fields" do
    [result] =
      Benchmark.run(
        sizes: [:small],
        scenarios: [:ssr_call_preparation],
        iterations: 2,
        warmup: 0,
        samples: 1
      )

    assert result.name == :ssr_call_preparation
    assert result.size == :small
    assert result.operations == 2
    assert result.avg_us > 0
    assert result.p95_us > 0
    assert is_number(result.reductions_per_op)
    assert is_integer(result.memory_delta_bytes)
    assert is_integer(result.binary_delta_bytes)
  end

  test "budget checker reports failures for exceeded metrics" do
    [result] =
      Benchmark.run(
        sizes: [:small],
        scenarios: [:ssr_call_preparation],
        iterations: 1,
        warmup: 0,
        samples: 1
      )

    budgets = %{
      ssr_call_preparation: %{
        small: %{max_p95_us: 0}
      }
    }

    assert [
             %{
               scenario: :ssr_call_preparation,
               size: :small,
               metric: :max_p95_us
             }
           ] = Budget.check([result], budgets)
  end

  defp item_struct_present?(%Item{}), do: true

  defp item_struct_present?(map) when is_map(map) do
    Enum.any?(map, fn {_key, value} -> item_struct_present?(value) end)
  end

  defp item_struct_present?(list) when is_list(list) do
    Enum.any?(list, &item_struct_present?/1)
  end

  defp item_struct_present?(_value), do: false
end
