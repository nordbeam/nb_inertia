defmodule NbInertia.Perf.Budget do
  @moduledoc false

  def check(results, budgets) when is_list(results) and is_map(budgets) do
    Enum.flat_map(results, &check_result(&1, budgets))
  end

  def format_failures([]), do: "All performance budgets passed."

  def format_failures(failures) do
    failures
    |> Enum.map_join("\n", fn failure ->
      "- #{failure.scenario}/#{failure.size} #{failure.metric}: #{failure.actual} exceeded #{failure.limit}"
    end)
  end

  defp check_result(result, budgets) do
    result_budget =
      budgets
      |> Map.get(result.name, %{})
      |> Map.get(result.size, %{})

    result_budget
    |> Enum.flat_map(fn {metric, limit} ->
      actual = metric_value(result, metric)

      if actual && actual > limit do
        [
          %{
            scenario: result.name,
            size: result.size,
            metric: metric,
            actual: format_metric(actual),
            limit: format_metric(limit)
          }
        ]
      else
        []
      end
    end)
  end

  defp metric_value(result, :max_avg_us), do: result.avg_us
  defp metric_value(result, :max_p95_us), do: result.p95_us
  defp metric_value(result, :max_reductions_per_op), do: result.reductions_per_op
  defp metric_value(result, :max_memory_delta_bytes), do: result.memory_delta_bytes
  defp metric_value(result, :max_binary_delta_bytes), do: result.binary_delta_bytes
  defp metric_value(_result, _metric), do: nil

  defp format_metric(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 2)
  defp format_metric(value), do: to_string(value)
end
