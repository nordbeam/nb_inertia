defprotocol NbInertia.PropSerializer do
  @moduledoc """
  Protocol for serializing Inertia prop values.

  This protocol provides an extensible mechanism for customizing how different
  data types are serialized for Inertia responses. It allows users to define
  custom serialization logic for their own types, while providing sensible
  defaults for common Elixir types.

  ## Benefits

  - **Extensible**: Users can implement the protocol for their own types
  - **Idiomatic**: Uses Elixir's protocol dispatch instead of conditional compilation
  - **Type-safe**: Dialyzer can verify protocol implementations
  - **Composable**: Can be combined with other serialization strategies

  ## Usage

  ### Default Behavior

  Most types use the default pass-through implementation:

      iex> NbInertia.PropSerializer.serialize("hello", [])
      {:ok, "hello"}

      iex> NbInertia.PropSerializer.serialize(42, [])
      {:ok, 42}

      iex> NbInertia.PropSerializer.serialize(%{name: "Alice"}, [])
      {:ok, %{name: "Alice"}}

  ### Custom Implementation

  You can implement the protocol for your own types:

      defmodule MyApp.CustomType do
        defstruct [:data, :metadata]
      end

      defimpl NbInertia.PropSerializer, for: MyApp.CustomType do
        def serialize(%MyApp.CustomType{data: data, metadata: metadata}, opts) do
          # Custom serialization logic
          include_metadata? = Keyword.get(opts, :include_metadata, false)

          result =
            if include_metadata? do
              %{data: data, metadata: metadata}
            else
              %{data: data}
            end

          {:ok, result}
        end
      end

  ### With NbSerializer

  When using tuples of `{serializer, data}`, the protocol automatically
  delegates to NbSerializer:

      # In your controller:
      render_inertia(conn, :users_index,
        users: {UserSerializer, users}  # Automatically uses NbSerializer
      )

  ## Options

  The `opts` parameter is a keyword list that can contain:

  - `:include_metadata` - Whether to include metadata (default: `false`)
  - `:depth` - Maximum nesting depth for recursive serialization (default: `nil`)
  - Any custom options your implementation needs

  ## Error Handling

  Implementations should return `{:ok, serialized}` on success or
  `{:error, reason}` on failure. This allows calling code to handle
  errors gracefully.

  ## Integration with NbInertia

  NbInertia automatically uses this protocol when serializing props,
  falling back to the default implementation for most types. You can
  opt into custom serialization by implementing the protocol for your types.
  """

  @doc """
  Serializes a value for Inertia prop transmission.

  ## Parameters

    - `value` - The value to serialize
    - `opts` - Serialization options (keyword list)

  ## Returns

    - `{:ok, serialized}` - Successful serialization
    - `{:error, reason}` - Serialization failed

  ## Examples

      iex> NbInertia.PropSerializer.serialize("hello", [])
      {:ok, "hello"}

      iex> NbInertia.PropSerializer.serialize(%User{name: "Alice"}, [])
      {:ok, %{name: "Alice", ...}}
  """
  @spec serialize(t, opts :: keyword()) :: {:ok, any()} | {:error, term()}
  def serialize(value, opts \\ [])
end

# Explicit implementations for primitive types
# Note: These are required because Elixir protocols don't automatically fall back
# to Any for built-in types like BitString, Atom, Integer, Float, etc.

defimpl NbInertia.PropSerializer, for: BitString do
  @moduledoc """
  Implementation for strings (binaries).
  Passes strings through unchanged.
  """

  def serialize(value, _opts) do
    {:ok, value}
  end
end

defimpl NbInertia.PropSerializer, for: Atom do
  @moduledoc """
  Implementation for atoms.
  Passes atoms through unchanged (will be encoded as strings by Jason).
  """

  def serialize(value, _opts) do
    {:ok, value}
  end
end

defimpl NbInertia.PropSerializer, for: Integer do
  @moduledoc """
  Implementation for integers.
  Passes integers through unchanged.
  """

  def serialize(value, _opts) do
    {:ok, value}
  end
end

defimpl NbInertia.PropSerializer, for: Float do
  @moduledoc """
  Implementation for floats.
  Passes floats through unchanged.
  """

  def serialize(value, _opts) do
    {:ok, value}
  end
end

defimpl NbInertia.PropSerializer, for: PID do
  @moduledoc """
  Implementation for PIDs.
  Converts PIDs to string representation since they can't be serialized to JSON directly.
  """

  def serialize(value, _opts) do
    {:ok, inspect(value)}
  end
end

defimpl NbInertia.PropSerializer, for: Port do
  @moduledoc """
  Implementation for Ports.
  Converts Ports to string representation since they can't be serialized to JSON directly.
  """

  def serialize(value, _opts) do
    {:ok, inspect(value)}
  end
end

defimpl NbInertia.PropSerializer, for: Reference do
  @moduledoc """
  Implementation for References.
  Converts References to string representation since they can't be serialized to JSON directly.
  """

  def serialize(value, _opts) do
    {:ok, inspect(value)}
  end
end

defimpl NbInertia.PropSerializer, for: Function do
  @moduledoc """
  Implementation for Functions.
  Converts Functions to string representation since they can't be serialized to JSON directly.
  """

  def serialize(value, _opts) do
    {:ok, inspect(value)}
  end
end

# Default implementation for other types - pass through unchanged
defimpl NbInertia.PropSerializer, for: Any do
  @moduledoc """
  Default implementation that passes values through unchanged.

  This implementation works for:
  - Structs (converted to maps via Jason encoding rules)
  - Other types not explicitly handled
  """

  def serialize(value, _opts) do
    {:ok, value}
  end
end

# Special implementation for tuples (NbSerializer integration)
defimpl NbInertia.PropSerializer, for: Tuple do
  @moduledoc """
  Implementation for tuple-based serialization.

  Recognizes the `{serializer, data}` and `{serializer, data, opts}` patterns
  used with NbSerializer and delegates to the serializer module.

  For other tuples, passes them through unchanged.
  """

  def serialize({serializer, data}, opts) when is_atom(serializer) do
    # Check if this looks like a serializer module
    if Code.ensure_loaded?(serializer) and function_exported?(serializer, :serialize, 2) do
      # Delegate to NbSerializer
      case serializer.serialize(data, opts) do
        {:ok, result} -> {:ok, result}
        {:error, error} -> {:error, error}
        # Some serializers return raw results
        result -> {:ok, result}
      end
    else
      # Not a serializer, pass through
      {:ok, {serializer, data}}
    end
  end

  def serialize({serializer, data, serializer_opts}, opts)
      when is_atom(serializer) and is_list(serializer_opts) do
    # Merge opts
    merged_opts = Keyword.merge(opts, serializer_opts)

    if Code.ensure_loaded?(serializer) and function_exported?(serializer, :serialize, 2) do
      case serializer.serialize(data, merged_opts) do
        {:ok, result} -> {:ok, result}
        {:error, error} -> {:error, error}
        result -> {:ok, result}
      end
    else
      {:ok, {serializer, data, serializer_opts}}
    end
  end

  def serialize(tuple, _opts) do
    # Other tuples pass through
    {:ok, tuple}
  end
end

# Implementation for lists - recursively serialize elements
defimpl NbInertia.PropSerializer, for: List do
  @moduledoc """
  Implementation for lists that recursively serializes each element.

  This allows heterogeneous lists where different elements may need
  different serialization strategies.
  """

  def serialize(list, opts) do
    max_depth = Keyword.get(opts, :depth)
    current_depth = Keyword.get(opts, :_current_depth, 0)

    cond do
      # Check depth limit
      max_depth != nil and current_depth >= max_depth ->
        {:error, :max_depth_exceeded}

      # Empty list
      list == [] ->
        {:ok, []}

      # Non-empty list - serialize each element
      true ->
        child_opts = Keyword.put(opts, :_current_depth, current_depth + 1)

        result =
          Enum.reduce_while(list, {:ok, []}, fn item, {:ok, acc} ->
            case NbInertia.PropSerializer.serialize(item, child_opts) do
              {:ok, serialized} -> {:cont, {:ok, [serialized | acc]}}
              {:error, reason} -> {:halt, {:error, reason}}
            end
          end)

        case result do
          {:ok, reversed_list} -> {:ok, Enum.reverse(reversed_list)}
          error -> error
        end
    end
  end
end

# Implementation for maps - recursively serialize values
defimpl NbInertia.PropSerializer, for: Map do
  @moduledoc """
  Implementation for maps that recursively serializes each value.

  Keys are preserved unchanged, but values are serialized according
  to their types.
  """

  def serialize(map, opts) when is_struct(map) do
    # For structs, convert to map first (removing __struct__ key)
    map
    |> Map.from_struct()
    |> serialize(opts)
  end

  def serialize(map, opts) do
    max_depth = Keyword.get(opts, :depth)
    current_depth = Keyword.get(opts, :_current_depth, 0)

    cond do
      # Check depth limit
      max_depth != nil and current_depth >= max_depth ->
        {:error, :max_depth_exceeded}

      # Empty map
      map == %{} ->
        {:ok, %{}}

      # Non-empty map - serialize each value
      true ->
        child_opts = Keyword.put(opts, :_current_depth, current_depth + 1)

        result =
          Enum.reduce_while(map, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
            case NbInertia.PropSerializer.serialize(value, child_opts) do
              {:ok, serialized} -> {:cont, {:ok, Map.put(acc, key, serialized)}}
              {:error, reason} -> {:halt, {:error, reason}}
            end
          end)

        result
    end
  end
end
