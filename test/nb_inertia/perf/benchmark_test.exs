defmodule NbInertia.Perf.BenchmarkTest do
  use ExUnit.Case, async: false

  alias NbInertia.Perf.Benchmark
  alias NbInertia.Perf.Budget

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
end
