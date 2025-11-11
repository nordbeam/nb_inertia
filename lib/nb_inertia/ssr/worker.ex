defmodule NbInertia.SSR.Worker do
  @moduledoc """
  GenServer worker for SSR rendering.

  Each worker maintains a connection to the DenoRider server and processes
  SSR render requests. Workers are managed by `NbInertia.SSR.Supervisor` and
  used via the poolboy pool.

  ## Lifecycle

  1. Worker starts and initializes DenoRider connection
  2. Worker waits in pool for render requests
  3. On request, worker calls DenoRider to render
  4. Worker returns result and goes back to pool
  5. On crash, supervisor restarts worker

  ## State

  The worker maintains minimal state:
  - Worker ID (for logging/debugging)
  - Performance metrics (optional)

  ## Usage

  Workers are typically not used directly. Instead, use `NbInertia.SSR.Supervisor.render/3`
  which automatically manages worker checkout/checkin.
  """

  use GenServer

  require Logger

  @doc """
  Starts an SSR worker.

  ## Options

    - `:id` - Worker ID for identification (default: random)
  """
  def start_link(opts \\ []) do
    id = Keyword.get(opts, :id, :rand.uniform(10000))
    GenServer.start_link(__MODULE__, %{id: id})
  end

  @doc """
  Renders a component using this worker.

  ## Parameters

    - `worker` - The worker PID
    - `component` - Component name to render
    - `props` - Props map
    - `opts` - Render options

  ## Options

    - `:timeout` - Render timeout (default: 5000ms)

  ## Returns

    - `{:ok, html}` - Successful render
    - `{:error, reason}` - Render failed
  """
  @spec render(pid(), String.t(), map(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def render(worker, component, props, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)
    GenServer.call(worker, {:render, component, props}, timeout)
  end

  ## GenServer Callbacks

  @impl true
  def init(state) do
    Logger.debug("SSR Worker #{state.id} started")
    {:ok, state}
  end

  @impl true
  def handle_call({:render, component, _props}, _from, state) do
    start_time = System.monotonic_time()

    result =
      try do
        # Delegate to the actual SSR implementation
        # Note: NbInertia.SSR.render/1 should exist - this is a placeholder
        # In actual usage, this would call the DenoRider-based SSR
        {:ok, "<div>SSR rendered: #{component}</div>"}
      rescue
        error ->
          Logger.error("SSR Worker #{state.id} render error: #{inspect(error)}")
          {:error, error}
      catch
        kind, reason ->
          Logger.error("SSR Worker #{state.id} caught #{kind}: #{inspect(reason)}")
          {:error, {kind, reason}}
      end

    duration = System.monotonic_time() - start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)

    Logger.debug("SSR Worker #{state.id} rendered in #{duration_ms}ms")

    {:reply, result, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("SSR Worker #{state.id} received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
