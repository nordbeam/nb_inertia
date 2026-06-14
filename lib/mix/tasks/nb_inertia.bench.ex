defmodule Mix.Tasks.NbInertia.Bench do
  @moduledoc """
  Runs repeatable nb_inertia performance benchmarks.

      mix nb_inertia.bench
      mix nb_inertia.bench --sizes small,medium --iterations 100 --samples 10
      mix nb_inertia.bench --scenarios controller_rendering,prop_serializer_recursion
  """

  use Mix.Task

  @shortdoc "Runs nb_inertia performance benchmarks"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("compile")

    opts = parse_args!(args)
    results = NbInertia.Perf.Benchmark.run(opts)

    Mix.shell().info("\nnb_inertia performance benchmark")
    Mix.shell().info(NbInertia.Perf.Benchmark.format_results(results))
  end

  defp parse_args!(args) do
    {parsed, _rest, invalid} =
      OptionParser.parse(args,
        strict: [
          sizes: :string,
          scenarios: :string,
          iterations: :integer,
          warmup: :integer,
          samples: :integer
        ]
      )

    if invalid != [] do
      Mix.raise("Invalid benchmark options: #{inspect(invalid)}")
    end

    []
    |> put_csv_option(parsed, :sizes)
    |> put_csv_option(parsed, :scenarios)
    |> put_option(parsed, :iterations)
    |> put_option(parsed, :warmup)
    |> put_option(parsed, :samples)
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
