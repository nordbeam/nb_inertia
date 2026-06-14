defmodule NbInertia.Perf.Benchmark do
  @moduledoc false

  import Bitwise

  alias NbInertia.Perf.Fixtures
  alias NbInertia.Perf.Fixtures.Controller
  alias NbInertia.PropRuntime

  defmodule Scenario do
    @moduledoc false

    defstruct [:name, :size, :description, :run]
  end

  defmodule Result do
    @moduledoc false

    defstruct [
      :name,
      :size,
      :description,
      :operations,
      :sample_count,
      :avg_us,
      :p50_us,
      :p95_us,
      :min_us,
      :max_us,
      :reductions_per_op,
      :memory_delta_bytes,
      :binary_delta_bytes,
      :gc_count,
      :gc_words_reclaimed_per_op,
      :checksum
    ]
  end

  @default_samples 10
  @default_iterations [small: 120, medium: 60, large: 20]
  @default_warmup [small: 20, medium: 10, large: 4]

  @scenario_order [
    :controller_rendering,
    :core_controller_rendering,
    :prop_runtime_processing,
    :prop_serializer_recursion,
    :shared_prop_resolution,
    :camelization,
    :flash_plug_overhead,
    :modal_composition,
    :ssr_call_preparation
  ]

  def scenario_names, do: @scenario_order

  def scenarios(sizes \\ Fixtures.sizes()) do
    sizes
    |> List.wrap()
    |> Enum.flat_map(&scenarios_for_size/1)
  end

  def run(opts \\ []) do
    {:ok, _started} = Application.ensure_all_started(:telemetry)

    sizes = opts |> Keyword.get(:sizes, Fixtures.sizes()) |> normalize_sizes()
    names = opts |> Keyword.get(:scenarios, @scenario_order) |> normalize_scenario_names()

    sizes
    |> scenarios()
    |> Enum.filter(&(&1.name in names))
    |> Enum.map(&measure(&1, opts))
  end

  def format_results(results) do
    rows =
      Enum.map(results, fn result ->
        [
          Atom.to_string(result.name),
          Atom.to_string(result.size),
          Integer.to_string(result.operations),
          format_float(result.avg_us),
          format_float(result.p50_us),
          format_float(result.p95_us),
          format_float(result.reductions_per_op),
          Integer.to_string(result.memory_delta_bytes),
          Integer.to_string(result.binary_delta_bytes),
          format_float(result.gc_words_reclaimed_per_op)
        ]
      end)

    table(
      [
        "scenario",
        "size",
        "ops",
        "avg_us",
        "p50_us",
        "p95_us",
        "reductions/op",
        "mem_delta_b",
        "bin_delta_b",
        "gc_words/op"
      ],
      rows
    )
  end

  defp scenarios_for_size(size) do
    conn = Fixtures.inertia_conn(size)
    raw_conn = Fixtures.raw_conn(size)
    controller_props = Fixtures.controller_props(size)
    core_props = Fixtures.core_props(size)
    camelized_props = Fixtures.camelized_props(size)
    runtime_props = Fixtures.runtime_props(size)
    runtime_configs = Fixtures.runtime_prop_configs(size)
    runtime_dsl_opts = PropRuntime.dsl_opts_map(runtime_configs)
    inline_shared_props = Fixtures.inline_shared_prop_configs(size)
    serializer_value = Fixtures.serializer_value(size)
    modal_fixture = Fixtures.modal_fixture(size)
    ssr_payload = Fixtures.ssr_payload(size)

    [
      scenario(
        :controller_rendering,
        size,
        "NbInertia.Controller render_inertia_page/4 with shared props and DSL modifiers",
        fn ->
          conn
          |> Controller.render_dashboard(controller_props)
          |> conn_marker()
        end
      ),
      scenario(
        :core_controller_rendering,
        size,
        "NbInertia.CoreController.render_inertia/3 with merge/defer/once/scroll props",
        fn ->
          conn
          |> NbInertia.CoreController.render_inertia("Perf/Core", core_props)
          |> conn_marker()
        end
      ),
      scenario(
        :prop_runtime_processing,
        size,
        "PropRuntime from/default filling and DSL prop assignment",
        fn ->
          props = PropRuntime.apply_from_and_defaults(conn, runtime_props, runtime_configs)
          processed_conn = PropRuntime.assign_props(conn, props, runtime_dsl_opts)
          map_size(processed_conn.private[:inertia_shared] || %{})
        end
      ),
      scenario(
        :prop_serializer_recursion,
        size,
        "PropSerializer recursive map/list/struct traversal",
        fn ->
          {:ok, serialized} = NbInertia.PropSerializer.serialize(serializer_value, [])
          serialized.users |> length()
        end
      ),
      scenario(
        :shared_prop_resolution,
        size,
        "Shared prop module resolution plus inline from/default shared props",
        fn ->
          conn
          |> PropRuntime.resolve_shared_props(Fixtures.shared_modules(), inline_shared_props,
            action: :index,
            controller_module: Controller,
            deep_merge: true
          )
          |> map_size()
        end
      ),
      scenario(
        :camelization,
        size,
        "Nested prop key camelization through CoreController rendering",
        fn ->
          conn
          |> NbInertia.CoreController.camelize_props(true)
          |> NbInertia.CoreController.render_inertia("Perf/Camelized", camelized_props)
          |> conn_marker()
        end
      ),
      scenario(
        :flash_plug_overhead,
        size,
        "NbInertia.Plug setup, session flash loading, flash merge, and camelized response flash",
        fn ->
          plugged_conn =
            raw_conn
            |> NbInertia.Plug.call([])
            |> NbInertia.Flash.inertia_flash(:selected_record_id, Fixtures.count_for(size))

          plugged_conn
          |> NbInertia.Flash.get_flash_for_response(camelize: true)
          |> map_size()
        end
      ),
      scenario(
        :modal_composition,
        size,
        "Modal struct/config composition and modal prop preparation",
        fn ->
          modal_props = NbInertia.Controller.build_modal_props(modal_fixture.props)
          config_bytes = modal_fixture.modal.config |> Jason.encode!() |> byte_size()
          map_size(modal_props) + config_bytes + byte_size(modal_fixture.modal.base_url)
        end
      ),
      scenario(
        :ssr_call_preparation,
        size,
        "SSR page payload construction/encoding without requiring an SSR runtime",
        fn ->
          ssr_payload
          |> Jason.encode!()
          |> byte_size()
        end
      )
    ]
  end

  defp scenario(name, size, description, run) do
    %Scenario{name: name, size: size, description: description, run: run}
  end

  defp measure(%Scenario{} = scenario, opts) do
    requested_iterations =
      iterations_for(scenario.size, Keyword.get(opts, :iterations, @default_iterations))

    samples = max(Keyword.get(opts, :samples, @default_samples), 1)
    ops_per_sample = max(div(requested_iterations, samples), 1)
    operations = ops_per_sample * samples
    warmup_ops = iterations_for(scenario.size, Keyword.get(opts, :warmup, @default_warmup))

    _ = run_batch(scenario.run, warmup_ops)
    :erlang.garbage_collect(self())

    before_memory = memory_bytes()
    before_binary_memory = binary_memory_bytes()
    before_reductions = reductions_total()
    before_gc = gc_stats()

    {sample_us, checksum} =
      Enum.reduce(1..samples, {[], 0}, fn _sample, {sample_acc, checksum_acc} ->
        {duration_us, sample_checksum} =
          timed_us(fn -> run_batch(scenario.run, ops_per_sample) end)

        per_op_us = duration_us / ops_per_sample
        {[per_op_us | sample_acc], bxor(checksum_acc, sample_checksum)}
      end)

    after_gc = gc_stats()
    after_reductions = reductions_total()
    after_binary_memory = binary_memory_bytes()
    after_memory = memory_bytes()

    sample_us = Enum.reverse(sample_us)

    %Result{
      name: scenario.name,
      size: scenario.size,
      description: scenario.description,
      operations: operations,
      sample_count: samples,
      avg_us: average(sample_us),
      p50_us: percentile(sample_us, 50),
      p95_us: percentile(sample_us, 95),
      min_us: Enum.min(sample_us),
      max_us: Enum.max(sample_us),
      reductions_per_op: max(after_reductions - before_reductions, 0) / operations,
      memory_delta_bytes: after_memory - before_memory,
      binary_delta_bytes: after_binary_memory - before_binary_memory,
      gc_count: elem(after_gc, 0) - elem(before_gc, 0),
      gc_words_reclaimed_per_op: max(elem(after_gc, 1) - elem(before_gc, 1), 0) / operations,
      checksum: checksum
    }
  end

  defp run_batch(_fun, count) when count <= 0, do: 0

  defp run_batch(fun, count) do
    Enum.reduce(1..count, 0, fn _index, acc ->
      bxor(acc, :erlang.phash2(fun.()))
    end)
  end

  defp timed_us(fun) do
    start = System.monotonic_time()
    result = fun.()
    stop = System.monotonic_time()
    duration_us = System.convert_time_unit(stop - start, :native, :microsecond)
    {max(duration_us, 1), result}
  end

  defp iterations_for(_size, value) when is_integer(value), do: value

  defp iterations_for(size, value) when is_list(value) do
    Keyword.get(value, size, Keyword.fetch!(@default_iterations, size))
  end

  defp normalize_sizes(:all), do: Fixtures.sizes()

  defp normalize_sizes(sizes) do
    sizes
    |> List.wrap()
    |> Enum.map(&normalize_size!/1)
  end

  defp normalize_size!(size) when size in [:small, :medium, :large], do: size

  defp normalize_size!(size) when is_binary(size) do
    size
    |> String.to_existing_atom()
    |> normalize_size!()
  rescue
    ArgumentError -> raise ArgumentError, "unknown benchmark size #{inspect(size)}"
  end

  defp normalize_scenario_names(:all), do: @scenario_order

  defp normalize_scenario_names(names) do
    names
    |> List.wrap()
    |> Enum.map(&normalize_scenario_name!/1)
  end

  defp normalize_scenario_name!(name) when name in @scenario_order, do: name

  defp normalize_scenario_name!(name) when is_binary(name) do
    name
    |> String.to_existing_atom()
    |> normalize_scenario_name!()
  rescue
    ArgumentError -> raise ArgumentError, "unknown benchmark scenario #{inspect(name)}"
  end

  defp conn_marker(conn) do
    {conn.status, byte_size(conn.resp_body || "")}
  end

  defp memory_bytes do
    {:memory, bytes} = Process.info(self(), :memory)
    bytes
  end

  defp binary_memory_bytes do
    {:binary, binaries} = Process.info(self(), :binary)

    Enum.reduce(binaries, 0, fn {_binary, size, _ref_count}, acc ->
      acc + size
    end)
  end

  defp reductions_total do
    {total, _since_last_call} = :erlang.statistics(:reductions)
    total
  end

  defp gc_stats do
    :erlang.statistics(:garbage_collection)
  end

  defp average(values), do: Enum.sum(values) / length(values)

  defp percentile(values, percentile) do
    sorted = Enum.sort(values)
    index = ceil(percentile / 100 * length(sorted)) - 1
    Enum.at(sorted, max(index, 0))
  end

  defp table(headers, rows) do
    widths =
      headers
      |> Enum.with_index()
      |> Enum.map(fn {header, index} ->
        rows
        |> Enum.map(fn row -> row |> Enum.at(index) |> String.length() end)
        |> Enum.max(fn -> 0 end)
        |> max(String.length(header))
      end)

    [
      format_row(headers, widths),
      widths |> Enum.map(&String.duplicate("-", &1)) |> format_row(widths)
      | Enum.map(rows, &format_row(&1, widths))
    ]
    |> Enum.join("\n")
  end

  defp format_row(values, widths) do
    values
    |> Enum.zip(widths)
    |> Enum.map_join("  ", fn {value, width} -> String.pad_trailing(value, width) end)
  end

  defp format_float(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 2)
  defp format_float(value), do: to_string(value)
end
