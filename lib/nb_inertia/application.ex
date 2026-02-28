defmodule NbInertia.Application do
  @moduledoc """
  Application callback module for NbInertia.

  Validates configuration at startup and optionally starts the DenoRider
  supervision tree for SSR.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Set the environment at startup if not already set
    if !Application.get_env(:nb_inertia, :env) do
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

    # Only start DenoRider if SSR is enabled and DenoRider is available
    ssr_enabled = NbInertia.Config.ssr_enabled?()
    deno_rider_available = Code.ensure_loaded?(DenoRider)

    children =
      if ssr_enabled and deno_rider_available do
        [DenoRider]
      else
        []
      end

    opts = [strategy: :one_for_one, name: NbInertia.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
