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
    # Forward configuration from :nb_inertia to :inertia
    forward_config()

    # NbInertia doesn't have any supervised processes yet,
    # but we need to return a supervisor spec
    children = []

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
    config_keys = [
      :endpoint,
      :camelize_props,
      :history,
      :static_paths,
      :default_version,
      :ssr,
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
  end
end
