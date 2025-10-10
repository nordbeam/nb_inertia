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
          script_path: Path.join([Application.app_dir(:my_app), "priv", "ssr.js"]),
          raise_on_failure: config_env() != :prod
        ]

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
  Renders a page using server-side rendering.

  ## Parameters

    * `page` - The Inertia page data (component name, props, etc.)

  ## Returns

    * `{:ok, html}` - The rendered HTML string
    * `{:error, reason}` - If rendering fails
  """
  def render(page) do
    if ssr_enabled?() do
      GenServer.call(__MODULE__, {:render, page}, 30_000)
    else
      {:error, :ssr_not_enabled}
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
    enabled = Keyword.get(opts, :enabled, Keyword.get(config, :enabled, false))

    state = %{
      enabled: enabled,
      script_path: Keyword.get(opts, :script_path, Keyword.get(config, :script_path)),
      raise_on_failure:
        Keyword.get(opts, :raise_on_failure, Keyword.get(config, :raise_on_failure, true)),
      script_loaded: false,
      deno_available: deno_rider_available?()
    }

    if state.enabled and state.deno_available do
      case load_ssr_script(state) do
        {:ok, new_state} ->
          {:ok, new_state}

        {:error, reason} ->
          Logger.warning("Failed to load SSR script: #{inspect(reason)}")
          {:ok, %{state | enabled: false}}
      end
    else
      if state.enabled and not state.deno_available do
        Logger.warning(
          "SSR enabled but DenoRider is not available. Please add {:deno_rider, \"~> 0.2\"} to your deps."
        )
      end

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
      result = do_render(page, state)
      {:reply, result, state}
    else
      {:reply, {:error, :ssr_not_enabled}, state}
    end
  end

  ## Private Functions

  defp deno_rider_available? do
    Code.ensure_loaded?(DenoRider)
  end

  defp load_ssr_script(%{script_path: nil} = state) do
    {:error, :no_script_path}
  end

  defp load_ssr_script(%{script_path: script_path} = state) do
    if File.exists?(script_path) do
      case File.read(script_path) do
        {:ok, script_content} ->
          # Load the script into DenoRider
          case DenoRider.eval(script_content) do
            {:ok, _} ->
              {:ok, %{state | script_loaded: true}}

            {:error, reason} ->
              {:error, {:eval_failed, reason}}
          end

        {:error, reason} ->
          {:error, {:read_failed, reason}}
      end
    else
      {:error, :script_not_found}
    end
  end

  defp do_render(page, state) do
    page_json = Jason.encode!(page)

    # Call the render function from the loaded SSR script
    js_code = """
    (async () => {
      const page = #{page_json};
      if (typeof render === 'function') {
        const result = await render(page);
        return result;
      } else {
        throw new Error('render function not found in SSR script');
      }
    })()
    """

    case DenoRider.eval(js_code) do
      {:ok, %{"head" => head, "body" => body}} ->
        {:ok, %{head: head, body: body}}

      {:ok, html} when is_binary(html) ->
        {:ok, %{head: [], body: html}}

      {:error, reason} = error ->
        if state.raise_on_failure do
          raise "SSR rendering failed: #{inspect(reason)}"
        else
          Logger.error("SSR rendering failed: #{inspect(reason)}")
          error
        end
    end
  rescue
    e ->
      if state.raise_on_failure do
        reraise e, __STACKTRACE__
      else
        Logger.error("SSR rendering error: #{Exception.format(:error, e, __STACKTRACE__)}")
        {:error, :render_exception}
      end
  end
end
