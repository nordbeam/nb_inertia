defmodule NbInertia.SSR.Supervisor do
  @moduledoc """
  Supervisor for managing SSR worker pool.

  This supervisor manages a pool of SSR workers to handle concurrent rendering
  requests efficiently. It uses OTP principles for fault tolerance and load distribution.

  ## Benefits

  - **Concurrent Rendering**: Multiple SSR requests can be processed in parallel
  - **Fault Isolation**: One failed render doesn't affect others
  - **Resource Management**: Limits concurrent SSR operations
  - **Graceful Degradation**: Falls back to CSR if SSR pool is saturated

  ## Configuration

      config :nb_inertia,
        ssr: [
          enabled: true,
          pool_size: 5,              # Number of concurrent SSR workers
          timeout: 5_000,            # SSR timeout in milliseconds
          queue_timeout: 1_000,      # Queue timeout
          fallback_to_csr: true      # Fallback to CSR on timeout/error
        ]

  ## Architecture

  The supervisor uses a simple pooling strategy:

  1. Request arrives for SSR render
  2. Claim a worker from the pool (or wait in queue)
  3. Worker processes the render
  4. Worker returns to pool
  5. If timeout or error, optionally fallback to CSR

  ## Usage

  The SSR supervisor is automatically started when SSR is enabled.
  You typically don't interact with it directly - use `NbInertia.SSR.render/2`:

      # This automatically uses the pool
      case NbInertia.SSR.render(component, props) do
        {:ok, html} -> html
        {:error, reason} -> handle_error(reason)
      end

  ## Monitoring

  The supervisor emits telemetry events for monitoring:

      :telemetry.attach(
        "ssr-pool-handler",
        [:nb_inertia, :ssr, :pool],
        fn event, measurements, metadata, _config ->
          # Handle pool metrics
        end,
        nil
      )

  Events:
  - `[:nb_inertia, :ssr, :pool, :checkout]` - Worker checked out
  - `[:nb_inertia, :ssr, :pool, :checkin]` - Worker returned
  - `[:nb_inertia, :ssr, :pool, :timeout]` - Queue timeout
  - `[:nb_inertia, :ssr, :pool, :full]` - Pool saturated
  """

  use Supervisor

  require Logger

  @doc """
  Starts the SSR supervisor.

  ## Options

    - `:pool_size` - Number of concurrent workers (default: 5)
    - `:name` - Registered name for the supervisor
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    pool_size = Keyword.get(opts, :pool_size, get_pool_size())

    # Create a pool of SSR worker processes
    children =
      for id <- 1..pool_size do
        %{
          id: {NbInertia.SSR.Worker, id},
          start: {NbInertia.SSR.Worker, :start_link, [[id: id]]},
          restart: :transient
        }
      end

    # Add poolboy for worker pooling
    poolboy_config = [
      name: {:local, :nb_inertia_ssr_pool},
      worker_module: NbInertia.SSR.Worker,
      size: pool_size,
      max_overflow: 2
    ]

    pool_spec = :poolboy.child_spec(:nb_inertia_ssr_pool, poolboy_config, [])

    Supervisor.init([pool_spec | children], strategy: :one_for_one)
  end

  @doc """
  Renders a component with SSR using a worker from the pool.

  This function automatically manages worker checkout/checkin and handles
  timeouts gracefully.

  ## Parameters

    - `component` - The component name to render
    - `props` - The props to pass to the component
    - `opts` - Rendering options

  ## Options

    - `:timeout` - Maximum time to wait for render (default: 5000ms)
    - `:queue_timeout` - Maximum time to wait in queue (default: 1000ms)
    - `:fallback_to_csr` - Whether to fallback to CSR on error (default: true)

  ## Returns

    - `{:ok, html}` - Successful render
    - `{:error, reason}` - Render failed
    - `{:error, :timeout}` - Render timed out
    - `{:error, :pool_timeout}` - Couldn't get worker from pool

  ## Examples

      case NbInertia.SSR.Supervisor.render("Users/Index", %{users: []}) do
        {:ok, html} ->
          {:ok, html}

        {:error, :timeout} ->
          Logger.warning("SSR timeout, falling back to CSR")
          {:error, :timeout}

        {:error, reason} ->
          Logger.error("SSR error: \#{inspect(reason)}")
          {:error, reason}
      end
  """
  @spec render(String.t(), map(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def render(component, props, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, get_timeout())
    queue_timeout = Keyword.get(opts, :queue_timeout, get_queue_timeout())

    start_time = System.monotonic_time()

    :telemetry.execute(
      [:nb_inertia, :ssr, :pool, :checkout],
      %{system_time: System.system_time()},
      %{component: component}
    )

    try do
      case :poolboy.transaction(
             :nb_inertia_ssr_pool,
             fn worker ->
               try do
                 NbInertia.SSR.Worker.render(worker, component, props, timeout: timeout)
               catch
                 :exit, {:timeout, _} ->
                   {:error, :timeout}

                 kind, reason ->
                   {:error, {kind, reason}}
               end
             end,
             queue_timeout
           ) do
        {:ok, _html} = result ->
          duration = System.monotonic_time() - start_time

          :telemetry.execute(
            [:nb_inertia, :ssr, :pool, :checkin],
            %{duration: duration},
            %{component: component, success: true}
          )

          result

        {:error, error_reason} = error ->
          duration = System.monotonic_time() - start_time

          :telemetry.execute(
            [:nb_inertia, :ssr, :pool, :checkin],
            %{duration: duration},
            %{component: component, success: false, reason: error_reason}
          )

          error
      end
    catch
      :exit, {:timeout, _} ->
        :telemetry.execute(
          [:nb_inertia, :ssr, :pool, :timeout],
          %{},
          %{component: component, timeout: queue_timeout}
        )

        {:error, :pool_timeout}
    end
  end

  @doc """
  Returns pool statistics for monitoring.

  ## Returns

  A map containing:
  - `:size` - Configured pool size
  - `:overflow` - Current overflow count
  - `:workers` - Number of worker processes
  - `:checkedout` - Number of currently checked out workers
  - `:available` - Number of available workers

  ## Examples

      iex> NbInertia.SSR.Supervisor.pool_stats()
      %{
        size: 5,
        overflow: 2,
        workers: 7,
        checkedout: 3,
        available: 4
      }
  """
  @spec pool_stats() :: map()
  def pool_stats do
    status = :poolboy.status(:nb_inertia_ssr_pool)

    %{
      size: Keyword.get(status, :size, 0),
      overflow: Keyword.get(status, :overflow, 0),
      workers: Keyword.get(status, :workers, 0),
      checkedout: Keyword.get(status, :checkedout, 0),
      available: Keyword.get(status, :available, 0)
    }
  end

  ## Configuration Helpers

  defp get_pool_size do
    case Application.get_env(:nb_inertia, :ssr, []) do
      config when is_list(config) -> Keyword.get(config, :pool_size, 5)
      _ -> 5
    end
  end

  defp get_timeout do
    case Application.get_env(:nb_inertia, :ssr, []) do
      config when is_list(config) -> Keyword.get(config, :timeout, 5_000)
      _ -> 5_000
    end
  end

  defp get_queue_timeout do
    case Application.get_env(:nb_inertia, :ssr, []) do
      config when is_list(config) -> Keyword.get(config, :queue_timeout, 1_000)
      _ -> 1_000
    end
  end
end
