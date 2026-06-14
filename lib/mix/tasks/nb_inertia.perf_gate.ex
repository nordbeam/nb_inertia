defmodule Mix.Tasks.NbInertia.PerfGate do
  @moduledoc """
  Runs the lightweight nb_inertia performance budget gate.

      mix nb_inertia.perf_gate
      mix nb_inertia.perf_gate --budget bench/perf_budgets.exs

  The gate is intentionally small-fixture based. Use `mix nb_inertia.bench` for
  full local comparison runs.
  """

  use Mix.Task

  @shortdoc "Checks nb_inertia performance smoke budgets"

  @default_budget_path "bench/perf_budgets.exs"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("compile")

    opts = parse_args!(args)
    budget_path = Keyword.get(opts, :budget, @default_budget_path)
    budgets = load_budgets!(budget_path)

    benchmark_opts =
      opts
      |> Keyword.drop([:budget])
      |> Keyword.put_new(:sizes, [:small])
      |> Keyword.put_new(:iterations, 40)
      |> Keyword.put_new(:warmup, 8)
      |> Keyword.put_new(:samples, 8)

    results = NbInertia.Perf.Benchmark.run(benchmark_opts)
    failures = NbInertia.Perf.Budget.check(results, budgets)

    Mix.shell().info("\nnb_inertia performance gate")
    Mix.shell().info(NbInertia.Perf.Benchmark.format_results(results))
    Mix.shell().info("")
    Mix.shell().info(NbInertia.Perf.Budget.format_failures(failures))

    if failures != [] do
      Mix.raise("Performance budget gate failed")
    end
  end

  defp parse_args!(args) do
    {parsed, _rest, invalid} =
      OptionParser.parse(args,
        strict: [
          budget: :string,
          scenarios: :string,
          iterations: :integer,
          warmup: :integer,
          samples: :integer
        ]
      )

    if invalid != [] do
      Mix.raise("Invalid performance gate options: #{inspect(invalid)}")
    end

    []
    |> put_option(parsed, :budget)
    |> put_csv_option(parsed, :scenarios)
    |> put_option(parsed, :iterations)
    |> put_option(parsed, :warmup)
    |> put_option(parsed, :samples)
  end

  defp load_budgets!(path) do
    path = Path.expand(path)

    unless File.exists?(path) do
      Mix.raise("Performance budget file not found: #{path}")
    end

    {budgets, _binding} = Code.eval_file(path)

    unless is_map(budgets) do
      Mix.raise("Performance budget file must return a map: #{path}")
    end

    budgets
  end

  defp put_csv_option(opts, parsed, key) do
    case Keyword.fetch(parsed, key) do
      {:ok, value} ->
        Keyword.put(opts, key, split_csv(value))

      :error ->
        opts
    end
  end

  defp put_option(opts, parsed, key) do
    case Keyword.fetch(parsed, key) do
      {:ok, value} -> Keyword.put(opts, key, value)
      :error -> opts
    end
  end

  defp split_csv(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end
end
