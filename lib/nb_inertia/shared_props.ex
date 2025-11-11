defmodule NbInertia.SharedProps do
  @moduledoc """
  Provides a DSL for defining reusable shared prop modules for Inertia.js pages.

  Shared prop modules allow you to define props that are common across multiple
  pages and can be automatically included in controller renders.

  ## Usage

      defmodule MyAppWeb.InertiaShared.Auth do
        use NbInertia.SharedProps

        inertia_shared do
          prop :locale, :string
          prop :current_user, :map
          prop :flash, :map
        end

        def build_props(conn, _opts) do
          %{
            locale: conn.assigns[:locale] || "en",
            current_user: conn.assigns[:current_user],
            flash: Phoenix.Controller.get_flash(conn)
          }
        end
      end

  ## With NbSerializer

  If you have `nb_serializer` installed, you can use serializers:

      defmodule MyAppWeb.InertiaShared.Auth do
        use NbInertia.SharedProps

        inertia_shared do
          prop :locale, :string
          prop :current_user, MyApp.UserSerializer
          prop :flash, :map
        end

        def build_props(conn, _opts) do
          %{
            locale: conn.assigns[:locale] || "en",
            current_user: conn.assigns[:current_user],
            flash: Phoenix.Controller.get_flash(conn)
          }
        end
      end

  When using serializers, implement `serialize_props/2` instead to handle
  automatic serialization, or let the default implementation handle it for you.

  ## Features

  - Define props with primitive types or serializers
  - Compile-time validation of returned map keys
  - Optional runtime serialization with NbSerializer
  - Introspection via `__inertia_shared_props__/0`
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour NbInertia.SharedProps.Behaviour

      import NbInertia.SharedProps
      import NbInertia.Controller, only: [prop: 2, prop: 3]

      Module.register_attribute(__MODULE__, :inertia_shared_props, accumulate: true)
      Module.register_attribute(__MODULE__, :current_props, accumulate: true)

      @before_compile NbInertia.SharedProps
    end
  end

  @doc """
  Declares shared props with the DSL.

  ## Examples

      inertia_shared do
        prop :locale, :string
        prop :current_user, :map
        prop :api_key, :string
      end
  """
  defmacro inertia_shared(do: block) do
    quote do
      Module.delete_attribute(__MODULE__, :current_props)

      unquote(block)

      props = Module.get_attribute(__MODULE__, :current_props) |> Enum.reverse()

      # Store each prop individually
      Enum.each(props, fn prop ->
        Module.put_attribute(__MODULE__, :inertia_shared_props, prop)
      end)

      Module.delete_attribute(__MODULE__, :current_props)
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    props = Module.get_attribute(env.module, :inertia_shared_props) |> Enum.reverse()

    # Check if NbSerializer is available
    nb_serializer_available? = Code.ensure_loaded?(NbSerializer)

    serialize_props_impl =
      if nb_serializer_available? do
        quote do
          @doc """
          Builds props and serializes them using NbSerializer serializers.

          Props with serializers (not primitive types) are automatically
          serialized. Primitive props are passed through as-is.

          This function is only available when `nb_serializer` is installed.
          """
          def serialize_props(conn, opts \\ []) do
            props = build_and_validate_props(conn, opts)
            declared_props = __inertia_shared_props__()

            Enum.reduce(declared_props, %{}, fn prop_config, acc ->
              key = prop_config.name
              value = Map.get(props, key)

              serialized_value =
                cond do
                  # If it has a serializer, use it
                  Map.has_key?(prop_config, :serializer) ->
                    serialize_with_serializer(value, prop_config.serializer)

                  # Otherwise, pass through (primitive type)
                  true ->
                    value
                end

              Map.put(acc, key, serialized_value)
            end)
          end

          # Private helper to serialize with a serializer module
          defp serialize_with_serializer(nil, _serializer), do: nil
          defp serialize_with_serializer([], _serializer), do: []

          defp serialize_with_serializer(data, serializer) when is_list(data) do
            Enum.map(data, &serialize_with_serializer(&1, serializer))
          end

          defp serialize_with_serializer(data, serializer) do
            NbSerializer.serialize!(serializer, data)
          end
        end
      else
        quote do
          # When NbSerializer is not available, serialize_props is not defined
        end
      end

    quote do
      @doc """
      Returns the declared shared props for introspection.
      """
      def __inertia_shared_props__ do
        unquote(Macro.escape(props))
      end

      @doc """
      Builds and validates props from the connection.

      Calls `build_props/2` and validates that the returned map contains
      exactly the declared props (no extra, no missing keys).

      Raises `ArgumentError` if validation fails.
      """
      def build_and_validate_props(conn, opts \\ []) do
        props = build_props(conn, opts)
        declared_props = __inertia_shared_props__()

        validate_props!(props, declared_props)

        props
      end

      unquote(serialize_props_impl)

      # Private helper to validate props
      defp validate_props!(props, declared_props) do
        provided_keys = Map.keys(props) |> MapSet.new()
        declared_keys = Enum.map(declared_props, & &1.name) |> MapSet.new()

        # Check for extra keys
        extra_keys = MapSet.difference(provided_keys, declared_keys)

        if MapSet.size(extra_keys) > 0 do
          extra_list = MapSet.to_list(extra_keys) |> Enum.map(&inspect/1) |> Enum.join(", ")

          raise ArgumentError,
                "Undeclared props returned from build_props/2: #{extra_list}. " <>
                  "Declared props: #{Enum.map(declared_props, & &1.name) |> Enum.map(&inspect/1) |> Enum.join(", ")}. " <>
                  "Make sure build_props/2 returns only the declared props."
        end

        # Check for missing keys
        missing_keys = MapSet.difference(declared_keys, provided_keys)

        if MapSet.size(missing_keys) > 0 do
          missing_list = MapSet.to_list(missing_keys) |> Enum.map(&inspect/1) |> Enum.join(", ")

          raise ArgumentError,
                "Missing required props from build_props/2: #{missing_list}. " <>
                  "Declared props: #{Enum.map(declared_props, & &1.name) |> Enum.map(&inspect/1) |> Enum.join(", ")}. " <>
                  "Make sure build_props/2 returns all declared props."
        end

        :ok
      end
    end
  end
end
