defmodule NbInertia.SSR do
  @moduledoc """
  Server-side rendering support for Inertia.js using DenoRider.

  This module provides a performant SSR implementation that uses the embedded
  Deno runtime via DenoRider instead of spawning external Node.js processes.

  ## Configuration

  Add SSR configuration to your config.exs:

      config :nb_inertia,
        ssr: [
          enabled: true,
          raise_on_failure: config_env() != :prod
        ]

  The `script_path` will automatically default to your application's priv directory
  (e.g., `priv/static/ssr.js`) which works correctly in both development and releases.

  You can optionally override the script path:

      config :nb_inertia,
        ssr: [
          enabled: true,
          script_path: "/custom/path/to/ssr.js",
          raise_on_failure: config_env() != :prod
        ]

  ## Requirements

  - **Vite 6+** is required for SSR. The SSR template uses Vite's Module Runner API
    which is only available in Vite 6 and later.

  ## SSR Modes

  NbInertia.SSR automatically uses different rendering strategies based on the environment:

  **Development**: Uses an external HTTP server with vite-node for on-demand transformation
    - Pros: Hot Module Replacement, source maps, no rebuild needed
    - Cons: Requires external process running (`npm run dev:ssr`)
    - Setup: Add watcher to config/dev.exs to start the dev SSR server automatically

  **Production**: Uses DenoRider with pre-bundled JavaScript
    - Pros: Embedded runtime, no external server, faster cold starts
    - Cons: Requires rebuild to see changes
    - Setup: Build SSR bundle with `npm run build:ssr`

  Note: SSR rendering is handled directly by the `NbInertia.SSR` GenServer,
  which delegates to either the dev HTTP server or DenoRider based on the
  environment. There is no worker pool — each render call goes through the
  GenServer sequentially.

  ## Setup

  1. Create an SSR script that exports a `render` function:

      ```javascript
      // assets/js/ssr.jsx
      import React from "react";
      import ReactDOMServer from "react-dom/server";
      import { createInertiaApp } from "@inertiajs/react";

      export async function render(page) {
        return await createInertiaApp({
          page,
          render: ReactDOMServer.renderToString,
          resolve: async (name) => {
            return await import(`./pages/${name}.jsx`);
          },
          setup: ({ App, props }) => <App {...props} />,
        });
      }
      ```

  2. Configure your bundler to compile the SSR script.

  3. Add DenoRider to your application's supervision tree:

      ```elixir
      # lib/my_app/application.ex
      def start(_type, _args) do
        children = [
          ...,
          DenoRider,
          NbInertia.SSR
        ]
      end
      ```

  ## Usage

  SSR will be automatically used when enabled. You can also control it per-request:

      conn
      |> enable_ssr()
      |> render_inertia("Dashboard")

      # Or disable it for a specific request
      conn
      |> disable_ssr()
      |> render_inertia("Dashboard")

  ## Release Configuration

  NbInertia.SSR is designed to work seamlessly in releases without additional configuration.
  The script_path automatically resolves to your application's priv directory using
  `:code.priv_dir/1`, which works correctly in both development and production releases.

  ### Building for Production

  1. Build your SSR bundle (typically done in your assets build step):

         cd assets && npm run build:ssr

  2. Ensure the SSR bundle is included in your release:

         # In mix.exs, ensure priv/static is included (this is the default)
         overlays: [
           {"/priv/static/ssr.js", "priv/static/ssr.js"}
         ]

  3. Build your release:

         MIX_ENV=prod mix release

  ### Troubleshooting Releases

  If SSR is not working in your release:

  1. Verify the SSR bundle exists:

         ls _build/prod/rel/my_app/lib/my_app-0.1.0/priv/static/ssr.js

  2. Check that NbInertia.SSR is in your supervision tree (added automatically by installer):

         # In lib/my_app/application.ex
         children = [
           ...,
           NbInertia.SSR
         ]

  3. Check logs for SSR initialization messages:

         # You should see:
         # [info] SSR: Using production bundle at /path/to/priv/static/ssr.js

  ### Important Notes

  - **Module Overriding**: nb_inertia provides `Inertia.SSR` as a compatibility shim that
    delegates to `NbInertia.SSR`. You may see a "redefining module" warning during compilation,
    which is expected and safe - it means we're successfully replacing the base library's NodeJS-based
    SSR with our DenoRider-based implementation.

  - **Automatic Path Resolution**: The script_path is automatically resolved at runtime using
    `:code.priv_dir/1`, which works correctly in releases where paths are different from
    development.

  - **Endpoint Configuration Required**: Make sure you have configured the `:endpoint` in your
    nb_inertia config, as it's used to infer your application name:

        config :nb_inertia,
          endpoint: MyAppWeb.Endpoint,
          ssr: [enabled: true]
  """

  use GenServer

  require Logger

  @doc """
  Starts the SSR GenServer.

  ## Options

    * `:enabled` - Whether SSR is enabled (default: `false`)
    * `:script_path` - Path to the compiled SSR JavaScript bundle
    * `:raise_on_failure` - Whether to raise on SSR failures (default: `true`)
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Compatibility function for Inertia.SSR.call/1 interface.

  This function matches the API of the original Inertia.SSR module,
  allowing NbInertia.SSR to be used as a drop-in replacement.

  ## Parameters

    * `page` - The Inertia page data (component name, props, etc.)

  ## Returns

    * `{:ok, %{"head" => head, "body" => body}}` - The rendered HTML
    * `{:error, reason}` - If rendering fails
  """
  def call(page) do
    render(page)
  end

  @doc """
  Renders a page using server-side rendering.

  ## Parameters

    * `page` - The Inertia page data (component name, props, etc.)

  ## Returns

    * `{:ok, %{"head" => head, "body" => body}}` - The rendered HTML
    * `{:error, reason}` - If rendering fails
  """
  def render(page) do
    if ssr_enabled?() do
      GenServer.call(__MODULE__, {:render, page}, 30_000)
    else
      {:error, "SSR is not enabled"}
    end
  end

  @doc """
  Checks if SSR is currently enabled.
  """
  def ssr_enabled? do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, :enabled?)
    else
      false
    end
  rescue
    _ -> false
  end

  ## GenServer Callbacks

  @impl true
  def init(opts) do
    config = Application.get_env(:nb_inertia, :ssr, [])

    # Handle both boolean and keyword list formats for :enabled
    config_enabled =
      case config do
        config when is_list(config) -> Keyword.get(config, :enabled, false)
        config when is_boolean(config) -> config
        _ -> false
      end

    enabled = Keyword.get(opts, :enabled, config_enabled)

    # Use configured script_path or fall back to default based on app's priv_dir
    script_path =
      Keyword.get(opts, :script_path) ||
        (is_list(config) && Keyword.get(config, :script_path)) ||
        default_script_path()

    dev_server_url =
      Keyword.get(opts, :dev_server_url, is_list(config) && Keyword.get(config, :dev_server_url))

    # Detect if we're in development mode
    dev_mode = dev_mode?()

    # Build default dev server URL from environment or fallback to localhost:5173
    default_dev_server_url =
      case System.get_env("VITE_DEV_SERVER_URL") do
        nil ->
          vite_port = System.get_env("VITE_PORT", "5173")
          # Use 127.0.0.1 instead of localhost to avoid IPv6 resolution issues
          # where Erlang's :httpc tries IPv4 first but Vite may listen on IPv6
          vite_host = System.get_env("VITE_HOST", "127.0.0.1")
          "http://#{vite_host}:#{vite_port}"

        url ->
          url
      end

    config_raise_on_failure =
      if is_list(config), do: Keyword.get(config, :raise_on_failure, true), else: true

    state = %{
      enabled: enabled,
      script_path: script_path,
      dev_server_url: dev_server_url || default_dev_server_url,
      dev_mode: dev_mode,
      raise_on_failure: Keyword.get(opts, :raise_on_failure, config_raise_on_failure),
      script_loaded: false,
      deno_pid: nil,
      deno_available: deno_rider_available?()
    }

    cond do
      # In dev mode, try to use the dev SSR server
      state.enabled and state.dev_mode ->
        case check_dev_server_health(state.dev_server_url) do
          :ok ->
            Logger.info("NbInertia.SSR: Using development server at #{state.dev_server_url}")
            {:ok, %{state | script_loaded: true}}

          :error ->
            Logger.info(
              "SSR: Development server not yet available at #{state.dev_server_url}. " <>
                "Will retry in background (this is normal during startup)."
            )

            # Schedule a retry check instead of disabling SSR permanently
            Process.send_after(self(), :check_dev_server, 2000)
            {:ok, state}
        end

      # In production mode, use DenoRider with bundled script
      state.enabled and state.deno_available and script_path ->
        case start_deno_with_module(script_path) do
          {:ok, pid} ->
            Logger.info("NbInertia.SSR: Using production bundle at #{script_path}")
            {:ok, %{state | script_loaded: true, deno_pid: pid}}

          {:error, reason} ->
            Logger.warning(
              "NbInertia.SSR: Failed to start DenoRider with SSR script: #{inspect(reason)}"
            )

            {:ok, %{state | enabled: false}}
        end

      # SSR enabled but DenoRider not available in production
      state.enabled and not state.deno_available and not state.dev_mode ->
        Logger.warning(
          "SSR enabled but DenoRider is not available. Please add {:deno_rider, \"~> 0.2\"} to your deps."
        )

        {:ok, state}

      # SSR not enabled
      true ->
        {:ok, state}
    end
  end

  @impl true
  def handle_call(:enabled?, _from, state) do
    {:reply, state.enabled and state.script_loaded, state}
  end

  @impl true
  def handle_call({:render, page}, _from, state) do
    if state.enabled and state.script_loaded do
      result =
        if state.dev_mode do
          do_render_dev(page, state)
        else
          do_render_prod(page, state)
        end

      {:reply, result, state}
    else
      {:reply, {:error, "SSR is not enabled or not ready"}, state}
    end
  end

  @impl true
  def handle_info(:check_dev_server, state) do
    if state.dev_mode and state.enabled and not state.script_loaded do
      case check_dev_server_health(state.dev_server_url) do
        :ok ->
          Logger.info("NbInertia.SSR: Development server is now ready at #{state.dev_server_url}")
          {:noreply, %{state | script_loaded: true}}

        :error ->
          # Retry again in 2 seconds (max 30 seconds total = 15 attempts)
          retry_count = state[:retry_count] || 0

          if retry_count < 15 do
            Process.send_after(self(), :check_dev_server, 2000)
            {:noreply, Map.put(state, :retry_count, retry_count + 1)}
          else
            Logger.warning(
              "SSR: Development server still not available after 30 seconds. " <>
                "SSR will be disabled. Make sure 'npm run dev' is running."
            )

            {:noreply, %{state | enabled: false}}
          end
      end
    else
      {:noreply, state}
    end
  end

  ## Private Functions

  defp dev_mode? do
    Application.get_env(:nb_inertia, :env, :prod) == :dev
  end

  defp default_script_path do
    case infer_app_name() do
      nil ->
        nil

      app ->
        case :code.priv_dir(app) do
          {:error, :bad_name} ->
            nil

          priv_dir ->
            Path.join([priv_dir, "static", "ssr.js"])
        end
    end
  end

  defp infer_app_name do
    # Try to infer the app name from the endpoint module
    case NbInertia.Config.endpoint() do
      nil ->
        nil

      endpoint_module when is_atom(endpoint_module) ->
        # Convert MyAppWeb.Endpoint to :my_app
        endpoint_module
        |> Module.split()
        |> List.first()
        |> then(fn module_name ->
          module_name
          |> String.replace(~r/Web$/, "")
          |> Macro.underscore()
          |> String.to_atom()
        end)

      _ ->
        nil
    end
  end

  defp check_dev_server_health(base_url) do
    health_url = "#{base_url}/ssr-health"

    case :httpc.request(:get, {String.to_charlist(health_url), []}, [], []) do
      {:ok, {{_, 200, _}, _, body}} ->
        case Jason.decode(body) do
          {:ok, %{"status" => "ok", "ready" => true}} -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  rescue
    _ -> :error
  end

  defp deno_rider_available? do
    Code.ensure_loaded?(DenoRider)
  end

  defp start_deno_with_module(script_path) do
    if File.exists?(script_path) do
      # Start DenoRider with the SSR script as the main module
      # This will execute the script and make globalThis.render available
      if Code.ensure_loaded?(DenoRider) do
        apply(DenoRider, :start, [[main_module_path: script_path]])
      else
        {:error, :deno_rider_not_available}
      end
    else
      {:error, :script_not_found}
    end
  end

  defp do_render_dev(page, state) do
    page_json = Jason.encode!(page)
    render_url = "#{state.dev_server_url}/ssr"

    case :httpc.request(
           :post,
           {
             String.to_charlist(render_url),
             [],
             ~c"application/json",
             page_json
           },
           [{:timeout, 30_000}],
           []
         ) do
      {:ok, {{_, 200, _}, _, body}} ->
        case Jason.decode(body) do
          {:ok, %{"success" => true, "result" => result}} ->
            {:ok, result}

          {:ok, %{"success" => false, "error" => error}} ->
            handle_render_error(error, page, state)

          {:error, reason} ->
            handle_render_error(
              %{"message" => "Failed to decode response: #{inspect(reason)}"},
              page,
              state
            )
        end

      {:ok, {{_, status, _}, _, body}} ->
        # Try to parse JSON body first
        error =
          case Jason.decode(body) do
            {:ok, %{"error" => error}} -> error
            _ -> %{"message" => "Dev server returned #{status}: #{body}"}
          end

        handle_render_error(error, page, state)

      {:error, reason} ->
        handle_render_error(
          %{"message" => "HTTP request failed: #{inspect(reason)}"},
          page,
          state
        )
    end
  rescue
    e ->
      if state.raise_on_failure do
        reraise e, __STACKTRACE__
      else
        Logger.error(
          "NbInertia.SSR: dev rendering error: #{Exception.format(:error, e, __STACKTRACE__)}"
        )

        {:error, :render_exception}
      end
  end

  defp do_render_prod(page, state) do
    page_json = Jason.encode!(page)

    # Call the globalThis.render function with try/catch wrapper for better error handling
    js_code = """
    (async function() {
      try {
        return await globalThis.render(#{page_json});
      } catch (error) {
        return {
          __error: true,
          message: error.message || String(error),
          stack: error.stack
        };
      }
    })();
    """

    result =
      if Code.ensure_loaded?(DenoRider) do
        case apply(DenoRider, :eval, [js_code, [pid: state.deno_pid]]) do
          # Check for error object first
          {:ok, %{"__error" => true, "message" => message, "stack" => stack}} ->
            handle_render_error(%{"message" => message, "stack" => stack}, page, state)

          {:ok, %{"__error" => true, "message" => message}} ->
            handle_render_error(%{"message" => message}, page, state)

          # Success cases
          {:ok, %{"head" => head, "body" => body}} ->
            {:ok, %{"head" => head, "body" => body}}

          {:ok, %{head: head, body: body}} ->
            {:ok, %{"head" => head, "body" => body}}

          {:ok, html} when is_binary(html) ->
            {:ok, %{"head" => [], "body" => html}}

          # DenoRider evaluation error
          {:error, reason} ->
            handle_render_error(%{"message" => inspect(reason)}, page, state)
        end
      else
        handle_render_error(%{"message" => "DenoRider not available"}, page, state)
      end

    result
  rescue
    e ->
      if state.raise_on_failure do
        reraise e, __STACKTRACE__
      else
        Logger.error(
          "NbInertia.SSR: rendering error: #{Exception.format(:error, e, __STACKTRACE__)}"
        )

        {:error, :render_exception}
      end
  end

  # Three-argument version with page context
  defp handle_render_error(error, page, state) do
    raw_message = Map.get(error, "message", "Unknown error")
    raw_stack = Map.get(error, "stack")
    component = page && Map.get(page, "component")

    # Parse and enhance the error message
    message = format_ssr_error(raw_message, component)

    # Include stack trace if available
    full_error =
      if raw_stack && String.trim(raw_stack) != "" do
        """
        #{message}

        JavaScript Stack Trace:
        #{raw_stack}
        """
      else
        message
      end

    if state.raise_on_failure do
      raise "SSR rendering failed: #{full_error}"
    else
      Logger.error("NbInertia.SSR: rendering failed: #{full_error}")
      {:error, full_error}
    end
  end

  defp format_ssr_error(message, component) do
    # Module not found error
    if String.contains?(message, "Cannot find module") do
      parse_module_not_found_error(message, component)
    else
      # Other errors - return as is
      message
    end
  end

  defp parse_module_not_found_error(message, component) do
    # Extract the missing module path
    case Regex.run(~r/Cannot find module '([^']+)'/, message) do
      [_, missing_path] ->
        """
        ❌ SSR Page Not Found

        Component: #{component || "Unknown"}
        Missing file: #{missing_path}

        The SSR server tried to load this page but the file doesn't exist.

        Common causes:
        • The page file hasn't been created yet
        • The file name doesn't match the component name
        • The component name in your controller doesn't match the file path

        Expected location: assets#{missing_path}

        To fix this:
        1. Create the missing page file at the expected location
        2. Or update your controller to use an existing component name
        """

      _ ->
        "Cannot find page component#{if component, do: " '#{component}'", else: ""}: #{message}"
    end
  end
end
