defmodule NbInertia.Validation do
  @moduledoc """
  Validation helpers for Inertia pages using idiomatic Elixir patterns.

  This module provides validation functions that use the `with` pattern for
  clear, composable error handling. All functions return `{:ok, value}` on
  success or `{:error, reason}` on failure.

  ## Benefits

  - **Clear Flow**: `with` makes the happy path obvious
  - **Composable**: Easy to chain validations
  - **Explicit Errors**: Each error case is clearly defined
  - **Pattern Matching**: Leverages Elixir's strengths

  ## Usage

      # In controller macro expansion
      case validate_render_props(page_ref, props, pages) do
        :ok -> # proceed with render
        {:error, reason} -> raise_validation_error(reason)
      end

  ## Error Types

  Validation errors are returned as tagged tuples:

  - `{:error, {:page_not_found, page_ref}}` - Page not declared
  - `{:error, {:missing_props, missing}}` - Required props missing
  - `{:error, {:extra_props, extra}}` - Undeclared props provided
  - `{:error, {:prop_collision, colliding}}` - Shared/page prop collision
  - `{:error, {:invalid_type, details}}` - Type mismatch
  """

  @doc """
  Validates that all required props for a page are provided.

  Uses `with` pattern for clear validation flow.

  ## Parameters

    - `page_ref` - The page name atom
    - `props` - The provided props keyword list
    - `pages` - The map of declared pages

  ## Returns

    - `:ok` - Validation passed
    - `{:error, reason}` - Validation failed

  ## Examples

      case validate_render_props(:users_index, [users: [], count: 10], pages) do
        :ok -> IO.puts("Valid!")
        {:error, {:missing_props, missing}} -> IO.puts("Missing: \#{inspect(missing)}")
        {:error, {:extra_props, extra}} -> IO.puts("Extra: \#{inspect(extra)}")
      end
  """
  @spec validate_render_props(atom(), keyword(), map()) :: :ok | {:error, term()}
  def validate_render_props(page_ref, props, pages) do
    with {:ok, config} <- fetch_page_config(pages, page_ref),
         :ok <- validate_required_props(config, props),
         :ok <- validate_declared_props(config, props) do
      :ok
    end
  end

  @doc """
  Fetches the page configuration.

  ## Returns

    - `{:ok, config}` - Page found
    - `{:error, {:page_not_found, page_ref}}` - Page not declared
  """
  @spec fetch_page_config(map(), atom()) :: {:ok, map()} | {:error, {:page_not_found, atom()}}
  def fetch_page_config(pages, page_ref) do
    case Map.get(pages, page_ref) do
      nil -> {:error, {:page_not_found, page_ref}}
      config -> {:ok, config}
    end
  end

  @doc """
  Validates that all required props are provided.

  ## Returns

    - `:ok` - All required props present
    - `{:error, {:missing_props, missing}}` - Some props missing
  """
  @spec validate_required_props(map(), keyword()) :: :ok | {:error, {:missing_props, MapSet.t()}}
  def validate_required_props(page_config, provided_props) do
    declared_props = page_config.props
    provided_prop_names = Keyword.keys(provided_props) |> MapSet.new()

    # Find required props (not optional, lazy, defer, or from: :assigns)
    required_props =
      declared_props
      |> Enum.reject(fn prop ->
        Keyword.get(prop.opts, :optional, false) ||
          Keyword.get(prop.opts, :lazy, false) ||
          Keyword.get(prop.opts, :defer, false) ||
          Keyword.get(prop.opts, :from, nil) == :assigns
      end)
      |> MapSet.new(& &1.name)

    # Check for missing required props
    missing_props = MapSet.difference(required_props, provided_prop_names)

    if MapSet.size(missing_props) > 0 do
      {:error, {:missing_props, missing_props}}
    else
      :ok
    end
  end

  @doc """
  Validates that no undeclared props are provided.

  ## Returns

    - `:ok` - Only declared props present
    - `{:error, {:extra_props, extra}}` - Undeclared props found
  """
  @spec validate_declared_props(map(), keyword()) :: :ok | {:error, {:extra_props, MapSet.t()}}
  def validate_declared_props(page_config, provided_props) do
    declared_props = page_config.props
    provided_prop_names = Keyword.keys(provided_props) |> MapSet.new()
    declared_prop_names = Enum.map(declared_props, & &1.name) |> MapSet.new()

    # Check for undeclared props
    extra_props = MapSet.difference(provided_prop_names, declared_prop_names)

    if MapSet.size(extra_props) > 0 do
      {:error, {:extra_props, extra_props}}
    else
      :ok
    end
  end

  @doc """
  Validates that there are no prop name collisions between shared and page props.

  ## Parameters

    - `pages` - Map of page configurations
    - `shared_props` - List of shared prop configurations
    - `shared_modules` - List of shared module configurations

  ## Returns

    - `:ok` - No collisions
    - `{:error, {:prop_collision, {page, collisions}}}` - Collisions detected
  """
  @spec validate_no_prop_collisions(map(), list(), list()) ::
          :ok | {:error, {:prop_collision, {atom(), MapSet.t()}}}
  def validate_no_prop_collisions(pages, shared_props, _shared_modules) do
    # Get shared prop names (only from inline shared props for now)
    shared_prop_names =
      shared_props
      |> Enum.map(& &1.name)
      |> MapSet.new()

    # Check each page for collisions
    collision_results =
      for {page_name, page_config} <- pages do
        page_prop_names = Enum.map(page_config.props, & &1.name) |> MapSet.new()
        collisions = MapSet.intersection(shared_prop_names, page_prop_names)

        if MapSet.size(collisions) > 0 do
          {:error, {page_name, collisions}}
        else
          :ok
        end
      end

    # Find first error or return :ok
    case Enum.find(collision_results, &match?({:error, _}, &1)) do
      nil -> :ok
      {:error, {page, collisions}} -> {:error, {:prop_collision, {page, collisions}}}
    end
  end

  @doc """
  Validates a SharedProps module's returned props match declarations.

  ## Parameters

    - `module` - The SharedProps module
    - `returned_props` - The props map returned by build_props/2
    - `declared_props` - The declared prop configurations

  ## Returns

    - `:ok` - Props valid
    - `{:error, {:missing_shared_props, missing}}` - Missing props
    - `{:error, {:extra_shared_props, extra}}` - Extra props
  """
  @spec validate_shared_props(module(), map(), list()) ::
          :ok | {:error, {:missing_shared_props | :extra_shared_props, MapSet.t()}}
  def validate_shared_props(_module, returned_props, declared_props) do
    provided_keys = Map.keys(returned_props) |> MapSet.new()
    declared_keys = Enum.map(declared_props, & &1.name) |> MapSet.new()

    with :ok <- check_missing_shared_props(provided_keys, declared_keys),
         :ok <- check_extra_shared_props(provided_keys, declared_keys) do
      :ok
    end
  end

  ## Private Helpers

  defp check_missing_shared_props(provided_keys, declared_keys) do
    missing_keys = MapSet.difference(declared_keys, provided_keys)

    if MapSet.size(missing_keys) > 0 do
      {:error, {:missing_shared_props, missing_keys}}
    else
      :ok
    end
  end

  defp check_extra_shared_props(provided_keys, declared_keys) do
    extra_keys = MapSet.difference(provided_keys, declared_keys)

    if MapSet.size(extra_keys) > 0 do
      {:error, {:extra_shared_props, extra_keys}}
    else
      :ok
    end
  end

  @doc """
  Formats a validation error into a human-readable message.

  ## Parameters

    - `error` - The error tuple from validation

  ## Returns

  A formatted string explaining the error.

  ## Examples

      iex> format_error({:page_not_found, :users_index})
      "Page :users_index has not been declared"

      iex> format_error({:missing_props, MapSet.new([:users, :count])})
      "Missing required props: :users, :count"
  """
  @spec format_error(term()) :: String.t()
  def format_error({:page_not_found, page_ref}) do
    """
    Page #{inspect(page_ref)} has not been declared.

    Declare it in your controller:

        inertia_page #{inspect(page_ref)} do
          prop :my_prop, :string
        end
    """
  end

  def format_error({:missing_props, missing}) do
    missing_list = missing |> MapSet.to_list() |> Enum.map_join(", ", &inspect/1)

    """
    Missing required props: #{missing_list}

    Add them to your render_inertia call or mark them as optional.
    """
  end

  def format_error({:extra_props, extra}) do
    extra_list = extra |> MapSet.to_list() |> Enum.map_join(", ", &inspect/1)

    """
    Undeclared props provided: #{extra_list}

    Remove them or declare them in your inertia_page block.
    """
  end

  def format_error({:prop_collision, {page, collisions}}) do
    collision_list = collisions |> MapSet.to_list() |> Enum.map_join(", ", &inspect/1)

    """
    Prop name collision in page #{inspect(page)}: #{collision_list}

    These props are defined both as shared props and page props.
    Rename one set to avoid conflicts.
    """
  end

  def format_error({:missing_shared_props, missing}) do
    missing_list = missing |> MapSet.to_list() |> Enum.map_join(", ", &inspect/1)

    """
    SharedProps module missing declared props: #{missing_list}

    Ensure build_props/2 returns all declared props.
    """
  end

  def format_error({:extra_shared_props, extra}) do
    extra_list = extra |> MapSet.to_list() |> Enum.map_join(", ", &inspect/1)

    """
    SharedProps module returned undeclared props: #{extra_list}

    Remove them or declare them in your inertia_shared block.
    """
  end

  def format_error(error) do
    "Validation error: #{inspect(error)}"
  end
end
