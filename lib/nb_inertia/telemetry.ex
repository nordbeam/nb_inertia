defmodule NbInertia.Telemetry do
  @moduledoc """
  Telemetry events emitted by NbInertia for monitoring and observability.

  NbInertia emits several `:telemetry` events that you can attach handlers to
  for monitoring, metrics collection, and debugging. This follows standard Elixir
  conventions and integrates seamlessly with Phoenix LiveDashboard.

  ## Events

  ### Render Events

  * `[:nb_inertia, :render, :start]` - Emitted when an Inertia page render begins
    - Measurements: `%{system_time: integer()}`
    - Metadata: `%{component: String.t(), action: atom(), controller: module()}`

  * `[:nb_inertia, :render, :stop]` - Emitted when an Inertia page render completes
    - Measurements: `%{duration: integer()}` (in native time units)
    - Metadata: `%{component: String.t(), action: atom(), controller: module()}`

  * `[:nb_inertia, :render, :exception]` - Emitted when an Inertia page render fails
    - Measurements: `%{duration: integer()}`
    - Metadata: `%{component: String.t(), action: atom(), controller: module(), kind: atom(), reason: term(), stacktrace: list()}`

  ### SSR Events

  * `[:nb_inertia, :ssr, :start]` - Emitted when SSR rendering begins
    - Measurements: `%{system_time: integer()}`
    - Metadata: `%{component: String.t(), props_count: integer()}`

  * `[:nb_inertia, :ssr, :stop]` - Emitted when SSR rendering completes
    - Measurements: `%{duration: integer()}`
    - Metadata: `%{component: String.t(), html_size: integer()}`

  * `[:nb_inertia, :ssr, :exception]` - Emitted when SSR rendering fails
    - Measurements: `%{duration: integer()}`
    - Metadata: `%{component: String.t(), kind: atom(), reason: term(), stacktrace: list()}`

  ### Serialization Events

  * `[:nb_inertia, :serialization, :start]` - Emitted when prop serialization begins
    - Measurements: `%{system_time: integer()}`
    - Metadata: `%{serializer: module(), data_type: atom(), count: integer()}`

  * `[:nb_inertia, :serialization, :stop]` - Emitted when prop serialization completes
    - Measurements: `%{duration: integer()}`
    - Metadata: `%{serializer: module(), result_size: integer()}`

  * `[:nb_inertia, :serialization, :exception]` - Emitted when prop serialization fails
    - Measurements: `%{duration: integer()}`
    - Metadata: `%{serializer: module(), kind: atom(), reason: term(), stacktrace: list()}`

  ### Validation Events

  * `[:nb_inertia, :validation, :error]` - Emitted when compile-time validation fails
    - Measurements: `%{}`
    - Metadata: `%{page: atom(), error_type: atom(), details: term()}`

  ## Usage

  ### Attaching Handlers

  You can attach telemetry handlers in your application's `start/2` function:

      defmodule MyApp.Application do
        use Application

        def start(_type, _args) do
          :telemetry.attach_many(
            "my-app-nb-inertia-handler",
            [
              [:nb_inertia, :render, :start],
              [:nb_inertia, :render, :stop],
              [:nb_inertia, :render, :exception]
            ],
            &MyApp.Telemetry.handle_event/4,
            nil
          )

          # ... rest of your application setup
        end
      end

      defmodule MyApp.Telemetry do
        require Logger

        def handle_event([:nb_inertia, :render, :stop], measurements, metadata, _config) do
          duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

          Logger.info(
            "Rendered Inertia page",
            component: metadata.component,
            action: metadata.action,
            duration_ms: duration_ms
          )
        end

        def handle_event([:nb_inertia, :render, :exception], measurements, metadata, _config) do
          Logger.error(
            "Failed to render Inertia page",
            component: metadata.component,
            error: inspect(metadata.reason)
          )
        end

        def handle_event(_event, _measurements, _metadata, _config), do: :ok
      end

  ### Phoenix LiveDashboard Integration

  NbInertia telemetry events work seamlessly with Phoenix LiveDashboard.
  Add metrics to your dashboard module:

      defmodule MyAppWeb.Telemetry do
        use Supervisor
        import Telemetry.Metrics

        def start_link(arg) do
          Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
        end

        def init(_arg) do
          children = [
            {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
            {TelemetryMetricsPrometheus, metrics: metrics()}
          ]

          Supervisor.init(children, strategy: :one_for_one)
        end

        def metrics do
          [
            # Inertia render timing
            distribution("nb_inertia.render.stop.duration",
              unit: {:native, :millisecond},
              tags: [:component, :action],
              description: "Inertia page render duration"
            ),

            # Inertia render count
            counter("nb_inertia.render.stop.count",
              tags: [:component, :action],
              description: "Total Inertia page renders"
            ),

            # Inertia render errors
            counter("nb_inertia.render.exception.count",
              tags: [:component, :kind],
              description: "Total Inertia render errors"
            ),

            # SSR timing
            distribution("nb_inertia.ssr.stop.duration",
              unit: {:native, :millisecond},
              tags: [:component],
              description: "SSR render duration"
            ),

            # Serialization timing
            distribution("nb_inertia.serialization.stop.duration",
              unit: {:native, :millisecond},
              tags: [:serializer],
              description: "Prop serialization duration"
            )
          ]
        end

        defp periodic_measurements do
          []
        end
      end

  ## Span-based Tracing

  For more detailed tracing, you can use the span helpers:

      def my_action(conn, _params) do
        NbInertia.Telemetry.span(:render, %{component: "Users/Index"}, fn ->
          # Your render logic here
          render_inertia(conn, :users_index, users: users)
        end)
      end
  """

  @doc """
  Executes a function within a telemetry span, emitting start/stop/exception events.

  This is a convenience wrapper around `:telemetry.span/3` that follows NbInertia's
  event naming conventions.

  ## Parameters

    - `event_suffix` - The suffix for the event (e.g., `:render`, `:ssr`, `:serialization`)
    - `metadata` - A map of metadata to include in all events
    - `fun` - The function to execute

  ## Examples

      NbInertia.Telemetry.span(:render, %{component: "Users/Index"}, fn ->
        render_inertia(conn, :users_index, users: users)
      end)

  """
  @spec span(atom(), map(), (-> result)) :: result when result: term()
  def span(event_suffix, metadata, fun) when is_atom(event_suffix) and is_map(metadata) do
    :telemetry.span([:nb_inertia, event_suffix], metadata, fun)
  end

  @doc """
  Emits a telemetry event for render start.

  ## Parameters

    - `metadata` - A map containing `:component`, `:action`, and `:controller` keys

  ## Examples

      NbInertia.Telemetry.render_start(%{
        component: "Users/Index",
        action: :index,
        controller: MyAppWeb.UserController
      })
  """
  @spec render_start(map()) :: :ok
  def render_start(metadata) when is_map(metadata) do
    :telemetry.execute(
      [:nb_inertia, :render, :start],
      %{system_time: System.system_time()},
      metadata
    )
  end

  @doc """
  Emits a telemetry event for render stop.

  ## Parameters

    - `duration` - The render duration in native time units
    - `metadata` - A map containing `:component`, `:action`, and `:controller` keys

  ## Examples

      start_time = System.monotonic_time()
      # ... render logic ...
      duration = System.monotonic_time() - start_time

      NbInertia.Telemetry.render_stop(duration, %{
        component: "Users/Index",
        action: :index,
        controller: MyAppWeb.UserController
      })
  """
  @spec render_stop(integer(), map()) :: :ok
  def render_stop(duration, metadata) when is_integer(duration) and is_map(metadata) do
    :telemetry.execute(
      [:nb_inertia, :render, :stop],
      %{duration: duration},
      metadata
    )
  end

  @doc """
  Emits a telemetry event for render exception.

  ## Parameters

    - `duration` - The time until exception in native time units
    - `kind` - The exception kind (`:error`, `:exit`, `:throw`)
    - `reason` - The exception reason
    - `stacktrace` - The exception stacktrace
    - `metadata` - A map containing `:component`, `:action`, and `:controller` keys

  ## Examples

      try do
        render_inertia(conn, :users_index, users: users)
      rescue
        e ->
          NbInertia.Telemetry.render_exception(
            duration,
            :error,
            e,
            __STACKTRACE__,
            %{component: "Users/Index", action: :index, controller: __MODULE__}
          )
          reraise e, __STACKTRACE__
      end
  """
  @spec render_exception(integer(), atom(), term(), list(), map()) :: :ok
  def render_exception(duration, kind, reason, stacktrace, metadata) do
    :telemetry.execute(
      [:nb_inertia, :render, :exception],
      %{duration: duration},
      Map.merge(metadata, %{kind: kind, reason: reason, stacktrace: stacktrace})
    )
  end

  @doc """
  Emits a telemetry event for SSR start.
  """
  @spec ssr_start(map()) :: :ok
  def ssr_start(metadata) when is_map(metadata) do
    :telemetry.execute(
      [:nb_inertia, :ssr, :start],
      %{system_time: System.system_time()},
      metadata
    )
  end

  @doc """
  Emits a telemetry event for SSR stop.
  """
  @spec ssr_stop(integer(), map()) :: :ok
  def ssr_stop(duration, metadata) when is_integer(duration) and is_map(metadata) do
    :telemetry.execute(
      [:nb_inertia, :ssr, :stop],
      %{duration: duration},
      metadata
    )
  end

  @doc """
  Emits a telemetry event for SSR exception.
  """
  @spec ssr_exception(integer(), atom(), term(), list(), map()) :: :ok
  def ssr_exception(duration, kind, reason, stacktrace, metadata) do
    :telemetry.execute(
      [:nb_inertia, :ssr, :exception],
      %{duration: duration},
      Map.merge(metadata, %{kind: kind, reason: reason, stacktrace: stacktrace})
    )
  end

  @doc """
  Emits a telemetry event for serialization start.
  """
  @spec serialization_start(map()) :: :ok
  def serialization_start(metadata) when is_map(metadata) do
    :telemetry.execute(
      [:nb_inertia, :serialization, :start],
      %{system_time: System.system_time()},
      metadata
    )
  end

  @doc """
  Emits a telemetry event for serialization stop.
  """
  @spec serialization_stop(integer(), map()) :: :ok
  def serialization_stop(duration, metadata) when is_integer(duration) and is_map(metadata) do
    :telemetry.execute(
      [:nb_inertia, :serialization, :stop],
      %{duration: duration},
      metadata
    )
  end

  @doc """
  Emits a telemetry event for serialization exception.
  """
  @spec serialization_exception(integer(), atom(), term(), list(), map()) :: :ok
  def serialization_exception(duration, kind, reason, stacktrace, metadata) do
    :telemetry.execute(
      [:nb_inertia, :serialization, :exception],
      %{duration: duration},
      Map.merge(metadata, %{kind: kind, reason: reason, stacktrace: stacktrace})
    )
  end

  @doc """
  Emits a telemetry event for validation errors.
  """
  @spec validation_error(map()) :: :ok
  def validation_error(metadata) when is_map(metadata) do
    :telemetry.execute(
      [:nb_inertia, :validation, :error],
      %{},
      metadata
    )
  end
end
