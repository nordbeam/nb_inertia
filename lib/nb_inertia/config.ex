defmodule NbInertia.Config do
  @moduledoc """
  Configuration for NbInertia.

  This module supports both function-based and bracket-based access:

      NbInertia.Config.get(:endpoint)
      NbInertia.Config[:endpoint]

  ## Configuration Options

  All configuration options are read from the `:nb_inertia` namespace:

  - `:endpoint` - Your Phoenix endpoint module (required for SSR and asset versioning)
  - `:camelize_props` - Whether to automatically camelize Inertia props (default: `true`)
  - `:snake_case_params` - Whether to convert incoming camelCase params to snake_case (default: `true`)
  - `:history` - History configuration for preserving scroll positions (default: `[]`)
  - `:static_paths` - List of static paths for asset versioning (default: `[]`)
  - `:default_version` - Default asset version (default: `"1"`)
  - `:deep_merge_shared_props` - Deep merge shared props with page props (default: `false`)
  - `:ssr` - Enable Server-Side Rendering (default: `false`)
  - `:raise_on_ssr_failure` - Raise on SSR failures (default: `true`)

  ### Modal Configuration

  - `:modal_default_size` - Default modal size (`:sm`, `:md`, `:lg`, `:xl`, `:full`, default: `:md`)
  - `:modal_default_position` - Default modal position (`:center`, `:top`, `:bottom`, `:left`, `:right`, default: `:center`)
  - `:modal_close_button` - Show close button by default (default: `true`)
  - `:modal_close_explicitly` - Require explicit close (disable backdrop/ESC) (default: `false`)
  - `:modal_backdrop_classes` - Custom CSS classes for modal backdrop (default: `nil`)
  - `:modal_panel_classes` - Custom CSS classes for modal panel (default: `nil`)
  - `:modal_padding_classes` - Custom CSS classes for modal padding (default: `nil`)

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
        raise_on_ssr_failure: true,
        # Modal defaults
        modal_default_size: :lg,
        modal_default_position: :center,
        modal_close_button: true
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
  Returns whether incoming params should be converted from camelCase to snake_case.

  When enabled, this automatically converts all camelCase parameter keys to snake_case
  before they reach your controller actions. This is useful when using `camelize_props: true`
  to ensure bi-directional compatibility between frontend (camelCase) and backend (snake_case).

  Defaults to `true` to match backend conventions and work seamlessly with Ecto changesets.

  ## Examples

      # With snake_case_params: true (default)
      # Frontend sends: { "primaryProductId": 123 }
      # Controller receives: %{"primary_product_id" => 123}

      # With snake_case_params: false
      # Frontend sends: { "primaryProductId": 123 }
      # Controller receives: %{"primaryProductId" => 123}
  """
  def snake_case_params do
    get(:snake_case_params, true)
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
  Returns whether shared props should be deep merged with page props.

  When `true`, nested maps in shared props and page props are recursively merged.
  When `false`, page props simply override shared props (shallow merge).

  Defaults to `false`.

  ## Examples

      # With deep_merge_shared_props: false (default - shallow merge)
      # Shared: %{user: %{name: "Alice", email: "alice@example.com"}}
      # Page:   %{user: %{name: "Bob"}}
      # Result: %{user: %{name: "Bob"}}

      # With deep_merge_shared_props: true (deep merge)
      # Shared: %{user: %{name: "Alice", email: "alice@example.com"}}
      # Page:   %{user: %{name: "Bob"}}
      # Result: %{user: %{name: "Bob", email: "alice@example.com"}}
  """
  def deep_merge_shared_props do
    get(:deep_merge_shared_props, false)
  end

  @doc """
  Returns the default modal size.

  Valid values: `:sm`, `:md`, `:lg`, `:xl`, `:full`, or a custom string.

  Defaults to `:md`.

  ## Examples

      config :nb_inertia,
        modal_default_size: :lg
  """
  def modal_default_size do
    get(:modal_default_size, :md)
  end

  @doc """
  Returns the default modal position.

  Valid values: `:center`, `:top`, `:bottom`, `:left`, `:right`

  Defaults to `:center`.

  ## Examples

      config :nb_inertia,
        modal_default_position: :center
  """
  def modal_default_position do
    get(:modal_default_position, :center)
  end

  @doc """
  Returns whether modals show a close button by default.

  Defaults to `true`.

  ## Examples

      config :nb_inertia,
        modal_close_button: false
  """
  def modal_close_button do
    get(:modal_close_button, true)
  end

  @doc """
  Returns whether modals require explicit closure by default.

  When `true`, clicking the backdrop or pressing ESC won't close the modal.

  Defaults to `false`.

  ## Examples

      config :nb_inertia,
        modal_close_explicitly: true
  """
  def modal_close_explicitly do
    get(:modal_close_explicitly, false)
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

  @doc """
  Validates the configuration at compile time.

  This function is called by `NbInertia.Application` during startup to ensure
  all required configuration is present and valid.

  ## Returns

    - `:ok` if configuration is valid
    - `{:error, message}` if configuration is invalid

  ## Validations

    - Endpoint module is configured and exists
    - SSR configuration is valid if enabled
    - Repo is configured if using lazy props
  """
  @spec validate!() :: :ok
  def validate! do
    with :ok <- validate_endpoint(),
         :ok <- validate_ssr_config() do
      :ok
    else
      {:error, message} ->
        raise """
        Invalid NbInertia configuration:

        #{message}

        See: https://hexdocs.pm/nb_inertia/configuration.html
        """
    end
  end

  defp validate_endpoint do
    case endpoint() do
      nil ->
        {:error,
         """
         Missing required :endpoint configuration.

         Add to your config/config.exs:

             config :nb_inertia,
               endpoint: MyAppWeb.Endpoint
         """}

      module when is_atom(module) ->
        if Code.ensure_loaded?(module) do
          :ok
        else
          {:error,
           """
           Endpoint module #{inspect(module)} not found.

           Make sure the module exists and is compiled before NbInertia starts.

           Current config:

               config :nb_inertia,
                 endpoint: #{inspect(module)}
           """}
        end

      other ->
        {:error,
         """
         Invalid :endpoint configuration. Expected module atom, got: #{inspect(other)}

         Example:

             config :nb_inertia,
               endpoint: MyAppWeb.Endpoint
         """}
    end
  end

  defp validate_ssr_config do
    case ssr() do
      false ->
        :ok

      [] ->
        :ok

      config when is_list(config) ->
        cond do
          !Keyword.get(config, :enabled, false) ->
            :ok

          !Code.ensure_loaded?(DenoRider) ->
            {:error,
             """
             SSR is enabled but DenoRider is not available.

             Make sure deno_rider is in your dependencies:

                 {:deno_rider, "~> 0.2"}

             Then run: mix deps.get
             """}

          true ->
            :ok
        end

      true ->
        # Old boolean config format
        if Code.ensure_loaded?(DenoRider) do
          :ok
        else
          {:error, "SSR is enabled but DenoRider is not available"}
        end

      other ->
        {:error,
         """
         Invalid :ssr configuration. Expected boolean or keyword list, got: #{inspect(other)}

         Examples:

             config :nb_inertia,
               ssr: false

             config :nb_inertia,
               ssr: [
                 enabled: true,
                 raise_on_failure: false
               ]
         """}
    end
  end

  # Access behaviour implementation
  @behaviour Access

  @doc """
  Implements the Access.fetch/2 callback for bracket-style access.

  ## Examples

      iex> NbInertia.Config[:endpoint]
      MyAppWeb.Endpoint

      iex> NbInertia.Config[:nonexistent]
      nil
  """
  @impl Access
  def fetch(_config \\ __MODULE__, key) do
    case get(key) do
      nil -> :error
      value -> {:ok, value}
    end
  end

  @doc """
  Implements the Access.get_and_update/3 callback.

  NbInertia.Config is read-only at runtime, so this always raises.
  """
  @impl Access
  def get_and_update(_config, _key, _function) do
    raise """
    NbInertia.Config is read-only at runtime.

    Configuration must be set at compile time in config files:

        # config/config.exs
        config :nb_inertia,
          endpoint: MyAppWeb.Endpoint
    """
  end

  @doc """
  Implements the Access.pop/2 callback.

  NbInertia.Config is read-only at runtime, so this always raises.
  """
  @impl Access
  def pop(_config, _key) do
    raise """
    NbInertia.Config is read-only at runtime.

    Configuration must be set at compile time in config files.
    """
  end
end
