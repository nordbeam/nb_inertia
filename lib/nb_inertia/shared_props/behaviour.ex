defmodule NbInertia.SharedProps.Behaviour do
  @moduledoc """
  Behaviour for defining reusable shared prop modules for Inertia.js pages.

  This behaviour defines the contract that all SharedProps modules must implement.
  It provides clear documentation of required callbacks and enables compile-time
  verification and Dialyzer type checking.

  ## Callbacks

  - `build_props/2` - Required callback that builds the props map from connection and options
  - `serialize_props/2` - Optional callback for serialization (only when NbSerializer is available)

  ## Usage

      defmodule MyAppWeb.InertiaShared.Auth do
        use NbInertia.SharedProps

        # This automatically includes @behaviour NbInertia.SharedProps.Behaviour

        inertia_shared do
          prop :locale, :string
          prop :current_user, MyApp.UserSerializer
          prop :flash, :map
        end

        @impl NbInertia.SharedProps.Behaviour
        def build_props(conn, _opts) do
          %{
            locale: conn.assigns[:locale] || "en",
            current_user: conn.assigns[:current_user],
            flash: Phoenix.Controller.get_flash(conn)
          }
        end
      end

  ## Type Safety

  The behaviour ensures:
  - All required callbacks are implemented at compile time
  - Function signatures match the expected types
  - Dialyzer can verify type correctness across implementations
  """

  @doc """
  Builds the props map from the connection and options.

  This callback must return a map with keys matching the props declared
  in the `inertia_shared` block. All declared props must be present in
  the returned map.

  ## Parameters

    - `conn` - The `Plug.Conn.t()` struct containing request information
    - `opts` - A keyword list of options (currently unused, reserved for future use)

  ## Returns

  A map where keys are prop names (atoms) and values are the prop data.

  ## Examples

      @impl NbInertia.SharedProps.Behaviour
      def build_props(conn, _opts) do
        %{
          locale: conn.assigns[:locale] || "en",
          current_user: conn.assigns[:current_user],
          flash: Phoenix.Controller.get_flash(conn)
        }
      end

  ## Validation

  The returned map is automatically validated at runtime to ensure:
  - All declared props are present
  - No extra props are included

  Missing or extra props will raise an `ArgumentError` with a helpful message.
  """
  @callback build_props(conn :: Plug.Conn.t(), opts :: keyword()) :: map()

  @doc """
  Builds and serializes props using NbSerializer serializers.

  This callback is optional and only available when `nb_serializer` is installed.
  It automatically serializes props that have serializer types, while passing
  through primitive types unchanged.

  The default implementation provided by `use NbInertia.SharedProps` handles
  serialization automatically, so you typically don't need to implement this
  callback unless you need custom serialization logic.

  ## Parameters

    - `conn` - The `Plug.Conn.t()` struct containing request information
    - `opts` - A keyword list of options passed to serializers

  ## Returns

  A map where:
  - Props with serializers are automatically serialized
  - Primitive props are passed through unchanged

  ## Examples

      @impl NbInertia.SharedProps.Behaviour
      def serialize_props(conn, opts) do
        # Custom serialization logic here
        props = build_props(conn, opts)

        %{
          locale: props.locale,
          current_user: NbSerializer.serialize!(UserSerializer, props.current_user),
          flash: props.flash
        }
      end
  """
  @callback serialize_props(conn :: Plug.Conn.t(), opts :: keyword()) :: map()

  @optional_callbacks serialize_props: 2
end
