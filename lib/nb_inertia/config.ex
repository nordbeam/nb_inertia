defmodule NbInertia.Config do
  @moduledoc """
  Configuration for NbInertia.

  ## Configuration Options

  All configuration options are read from the `:nb_inertia` namespace:

  - `:endpoint` - Your Phoenix endpoint module (required for SSR and asset versioning)
  - `:camelize_props` - Whether to automatically camelize Inertia props (default: `true`)
  - `:history` - History configuration for preserving scroll positions (default: `[]`)
  - `:static_paths` - List of static paths for asset versioning (default: `[]`)
  - `:default_version` - Default asset version (default: `"1"`)
  - `:ssr` - Enable Server-Side Rendering (default: `false`)
  - `:raise_on_ssr_failure` - Raise on SSR failures (default: `true`)

  ## Example

      # config/config.exs
      config :nb_inertia,
        endpoint: MyAppWeb.Endpoint,
        camelize_props: true,
        history: [
          scroll_regions: ["#main-content"],
          remember: "scroll"
        ],
        static_paths: ["/css", "/js", "/images"],
        default_version: "1",
        ssr: false,
        raise_on_ssr_failure: true
  """

  @doc """
  Gets the configuration value for the given key.

  ## Examples

      iex> NbInertia.Config.get(:camelize_props)
      true

      iex> NbInertia.Config.get(:camelize_props, false)
      true
  """
  def get(key, default \\ nil) do
    Application.get_env(:nb_inertia, key, default)
  end

  @doc """
  Returns the Phoenix endpoint module.
  """
  def endpoint do
    get(:endpoint)
  end

  @doc """
  Returns whether props should be automatically camelized for Inertia.

  Defaults to `true` to match Inertia.js conventions.
  """
  def camelize_props do
    get(:camelize_props, true)
  end

  @doc """
  Returns the history configuration for preserving scroll positions.

  Defaults to `[]`.
  """
  def history do
    get(:history, [])
  end

  @doc """
  Returns the list of static paths for asset versioning.

  Defaults to `[]`.
  """
  def static_paths do
    get(:static_paths, [])
  end

  @doc """
  Returns the default asset version.

  Defaults to `"1"`.
  """
  def default_version do
    get(:default_version, "1")
  end

  @doc """
  Returns whether Server-Side Rendering is enabled.

  Defaults to `false`.
  """
  def ssr do
    get(:ssr, false)
  end

  @doc """
  Returns whether to raise on SSR failures.

  Defaults to `true`.
  """
  def raise_on_ssr_failure do
    get(:raise_on_ssr_failure, true)
  end

  @doc """
  Returns the SSR module to use for server-side rendering.

  Defaults to `NbInertia.SSR` (DenoRider-based).

  You can configure this to use a different SSR implementation:

      config :nb_inertia,
        ssr_module: Inertia.SSR  # Use base inertia's NodeJS-based SSR

  Or provide your own custom SSR module that implements `call/1`.
  """
  def ssr_module do
    get(:ssr_module, NbInertia.SSR)
  end

  @doc """
  Returns whether props should be automatically camelized for Inertia.

  Defaults to `true` to match Inertia.js conventions.

  ## Deprecated
  Use `camelize_props/0` instead.
  """
  def camelize_props? do
    camelize_props()
  end
end
