defmodule NbInertia.Application do
  @moduledoc """
  Application callback module for NbInertia.

  This module is responsible for forwarding configuration from the `:nb_inertia`
  namespace to the `:inertia` namespace on application startup. This allows users
  to configure NbInertia using the `:nb_inertia` namespace while the underlying
  Inertia library reads configuration from the `:inertia` namespace.

  ## Configuration Forwarding

  On startup, this module reads all configuration options from `:nb_inertia` and
  writes them to `:inertia`, ensuring the underlying Inertia library works correctly.

  ### Forwarded Options

  - `:endpoint` - Phoenix endpoint module
  - `:camelize_props` - Whether to camelize props
  - `:history` - History configuration
  - `:static_paths` - Static paths for versioning
  - `:default_version` - Default asset version
  - `:ssr` - SSR configuration
  - `:raise_on_ssr_failure` - SSR failure handling

  ## Example

      # In config/config.exs
      config :nb_inertia,
        endpoint: MyAppWeb.Endpoint,
        camelize_props: true

      # This gets automatically forwarded to:
      # config :inertia,
      #   endpoint: MyAppWeb.Endpoint,
      #   camelize_props: true
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Set the environment at startup if not already set
    # This ensures Mix.env is captured at compile time and available at runtime
    if !Application.get_env(:nb_inertia, :env) do
      # In production releases, Mix is not available, so we detect the environment
      # by checking if Mix module is loaded
      env =
        if Code.ensure_loaded?(Mix) and function_exported?(Mix, :env, 0) do
          Mix.env()
        else
          # In releases without Mix, default to :prod
          :prod
        end

      Application.put_env(:nb_inertia, :env, env)
    end

    # Validate configuration at startup
    NbInertia.Config.validate!()

    # Forward configuration from :nb_inertia to :inertia
    forward_config()

    # Only start DenoRider if SSR is enabled
    ssr_enabled =
      case Application.get_env(:nb_inertia, :ssr, false) do
        config when is_list(config) -> Keyword.get(config, :enabled, false)
        config when is_boolean(config) -> config
        _ -> false
      end

    children = if ssr_enabled, do: [DenoRider], else: []

    opts = [strategy: :one_for_one, name: NbInertia.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Forwards configuration from `:nb_inertia` to `:inertia`.

  This function reads all configuration options from the `:nb_inertia` namespace
  and writes them to the `:inertia` namespace, ensuring the underlying Inertia
  library can access them.

  ## Config Keys

  The following keys are forwarded if present:
  - `:endpoint`
  - `:camelize_props`
  - `:history`
  - `:static_paths`
  - `:default_version`
  - `:ssr`
  - `:raise_on_ssr_failure`
  """
  def forward_config do
    # Note: :ssr is handled specially below, so we exclude it here to avoid
    # forwarding the keyword list [enabled: false] which is truthy
    config_keys = [
      :endpoint,
      :camelize_props,
      :history,
      :static_paths,
      :default_version,
      :raise_on_ssr_failure
    ]

    Enum.each(config_keys, fn key ->
      case Application.get_env(:nb_inertia, key) do
        nil ->
          :ok

        value ->
          Application.put_env(:inertia, key, value)
      end
    end)

    # Forward SSR config to :inertia so Inertia.Controller knows SSR is enabled
    # The actual SSR rendering will be handled by our Inertia.SSR shim -> NbInertia.SSR
    case Application.get_env(:nb_inertia, :ssr) do
      nil ->
        :ok

      ssr_config when is_list(ssr_config) ->
        # Convert our SSR config to what original Inertia expects
        # Original Inertia checks if :ssr is truthy to enable SSR
        if Keyword.get(ssr_config, :enabled, false) do
          Application.put_env(:inertia, :ssr, true)
        end

      value ->
        Application.put_env(:inertia, :ssr, value)
    end
  end
end
