defmodule NbInertia.Type do
  @moduledoc """
  Elixir-native type helpers for `NbInertia` props and `form_inputs`.

  These helpers are imported automatically by `use NbInertia.Controller` and
  `use NbInertia.Page`. They compile down to plain Elixir tuples so the DSL
  stays inspectable at macro expansion time.

  Prefer these helpers for common shapes and keep `~TS` as an escape hatch for
  TypeScript-only constructs.

  ## Examples

      inertia_page :dashboard do
        prop :status, enum([:draft, :published])
        prop :tags, list_of(:string)
        prop :filters, shape(search: optional(:string), page: :integer)
        prop :user, ref(UserSerializer)
        prop :subject, union([ref(UserSerializer), ref(TeamSerializer)])
        prop :settings, nullable(shape(theme: literal("dark"), compact: :boolean))
      end

      form_inputs :profile do
        field :roles, list_of(enum([:admin, :editor]))
        field :preferences, shape(
          timezone: :string,
          locale: optional(:string)
        )
      end
  """

  @primitive_types [
    :string,
    :integer,
    :float,
    :number,
    :boolean,
    :map,
    :list,
    :any,
    :date,
    :datetime
  ]

  @native_type_tags [:ref, :list, :enum, :literal, :union, :nullable, :optional, :shape]

  defmacro ref(module) do
    expanded_module = Macro.expand(module, __CALLER__)

    quote do
      {:ref, unquote(expanded_module)}
    end
  end

  defmacro list_of(inner) do
    quote do
      {:list, unquote(inner)}
    end
  end

  defmacro enum(values) do
    quote do
      {:enum, unquote(values)}
    end
  end

  defmacro literal(value) do
    quote do
      {:literal, unquote(value)}
    end
  end

  defmacro union(types) do
    quote do
      {:union, unquote(types)}
    end
  end

  defmacro nullable(inner) do
    quote do
      {:nullable, unquote(inner)}
    end
  end

  defmacro optional(inner) do
    quote do
      {:optional, unquote(inner)}
    end
  end

  defmacro shape(fields) do
    quote do
      {:shape, unquote(fields)}
    end
  end

  @doc false
  def primitive_types, do: @primitive_types

  @doc false
  def primitive_type?(type), do: type in @primitive_types

  @doc false
  def native_type_descriptor?({tag, _value}) when tag in @native_type_tags, do: true
  def native_type_descriptor?(_value), do: false

  @doc false
  def validated_typescript_type?({:typescript_validated, ts_string}) when is_binary(ts_string),
    do: true

  def validated_typescript_type?(_value), do: false

  @doc false
  def typescript_type?(value) when is_binary(value), do: true
  def typescript_type?(value), do: validated_typescript_type?(value)

  @doc false
  def top_level_prop_type?(value) do
    primitive_type?(value) or native_type_descriptor?(value) or typescript_type?(value) or
      is_binary(value)
  end

  @doc false
  def normalize_prop_opts!(opts) when is_list(opts) do
    validate_type_option_conflicts!(opts, :prop)

    Enum.each(Keyword.take(opts, [:type, :list, :enum]), fn
      {:type, type} ->
        validate_type_descriptor!(type, top_level: true, context: :prop)

      {:list, inner} ->
        normalized_inner = normalize_list_inner_type(inner)
        validate_type_descriptor!({:list, normalized_inner}, top_level: true, context: :prop)

      {:enum, values} ->
        validate_type_descriptor!({:enum, values}, top_level: true, context: :prop)
    end)

    opts
  end

  @doc false
  def normalize_field_opts!(opts) when is_list(opts) do
    validate_type_option_conflicts!(opts, :field)

    Enum.each(Keyword.take(opts, [:type, :list, :enum]), fn
      {:type, type} ->
        validate_type_descriptor!(type, top_level: true, context: :field)

      {:list, inner} ->
        normalized_inner = normalize_list_inner_type(inner)
        validate_type_descriptor!({:list, normalized_inner}, top_level: true, context: :field)

      {:enum, values} ->
        validate_type_descriptor!({:enum, values}, top_level: true, context: :field)
    end)

    opts
  end

  @doc false
  def classify_prop_input!(type_or_serializer) do
    cond do
      is_nil(type_or_serializer) ->
        :none

      primitive_type?(type_or_serializer) ->
        {:type, type_or_serializer}

      explicit_ref_descriptor?(type_or_serializer) ->
        validate_type_descriptor!(type_or_serializer, top_level: true, context: :prop)
        {:serializer, extract_ref_module(type_or_serializer)}

      native_type_descriptor?(type_or_serializer) ->
        validate_type_descriptor!(type_or_serializer, top_level: true, context: :prop)
        {:type, type_or_serializer}

      validated_typescript_type?(type_or_serializer) ->
        {:type, type_or_serializer}

      is_binary(type_or_serializer) ->
        {:type, type_or_serializer}

      serializer_module_atom?(type_or_serializer) ->
        {:serializer, type_or_serializer}

      true ->
        raise ArgumentError,
              "unsupported prop type declaration: #{inspect(type_or_serializer)}. " <>
                "Use a primitive atom, ref(SerializerModule), serializer module shorthand, native type helper, or ~TS string."
    end
  end

  @doc false
  def normalize_prop_declared_type(opts) when is_list(opts) do
    cond do
      Keyword.has_key?(opts, :type) ->
        Keyword.get(opts, :type)

      Keyword.has_key?(opts, :list) ->
        {:list, normalize_list_inner_type(Keyword.get(opts, :list))}

      Keyword.has_key?(opts, :enum) ->
        {:enum, Keyword.get(opts, :enum)}

      true ->
        nil
    end
  end

  @doc false
  def normalize_field_declared_type(type, opts) when is_list(opts) do
    cond do
      not is_nil(type) and type != :any ->
        type

      Keyword.has_key?(opts, :type) ->
        Keyword.get(opts, :type)

      true ->
        type
    end
  end

  @doc false
  def nullable_descriptor?({:nullable, _inner}), do: true
  def nullable_descriptor?(_other), do: false

  @doc false
  def validate_type_descriptor!(type, opts \\ []) do
    top_level? = Keyword.get(opts, :top_level, false)
    context = Keyword.get(opts, :context, :prop)

    do_validate_type_descriptor!(type, top_level?, context)
  end

  defp validate_type_option_conflicts!(opts, context) do
    type_keys =
      opts
      |> Keyword.keys()
      |> Enum.filter(&(&1 in [:type, :list, :enum]))
      |> Enum.uniq()

    if length(type_keys) > 1 do
      raise ArgumentError,
            "#{context} declarations may use only one of :type, :list, or :enum, got: #{inspect(type_keys)}"
    end
  end

  defp do_validate_type_descriptor!(type, _top_level?, _context) when is_binary(type), do: :ok

  defp do_validate_type_descriptor!({:typescript_validated, ts_string}, _top_level?, _context)
       when is_binary(ts_string),
       do: :ok

  defp do_validate_type_descriptor!(type, _top_level?, _context) when is_atom(type), do: :ok

  defp do_validate_type_descriptor!({:ref, module}, _top_level?, _context)
       when is_atom(module) do
    unless serializer_module_atom?(module) do
      raise ArgumentError,
            "ref/1 expects a serializer or named type module, got: #{inspect(module)}"
    end
  end

  defp do_validate_type_descriptor!({:ref, module}, _top_level?, _context) do
    raise ArgumentError, "ref/1 expects a module atom, got: #{inspect(module)}"
  end

  defp do_validate_type_descriptor!({:list, inner}, _top_level?, context) do
    do_validate_type_descriptor!(normalize_list_inner_type(inner), false, context)
  end

  defp do_validate_type_descriptor!({:enum, values}, _top_level?, _context)
       when is_list(values) do
    if values == [] do
      raise ArgumentError, "enum/1 requires at least one literal value"
    end

    Enum.each(values, &validate_literal_value!/1)
  end

  defp do_validate_type_descriptor!({:enum, values}, _top_level?, _context) do
    raise ArgumentError, "enum/1 expects a literal list, got: #{inspect(values)}"
  end

  defp do_validate_type_descriptor!({:literal, value}, _top_level?, _context) do
    validate_literal_value!(value)
  end

  defp do_validate_type_descriptor!({:union, types}, _top_level?, context) when is_list(types) do
    if types == [] do
      raise ArgumentError, "union/1 requires at least one type"
    end

    Enum.each(types, &do_validate_type_descriptor!(&1, false, context))
  end

  defp do_validate_type_descriptor!({:union, types}, _top_level?, _context) do
    raise ArgumentError, "union/1 expects a list of types, got: #{inspect(types)}"
  end

  defp do_validate_type_descriptor!({:nullable, inner}, _top_level?, context) do
    do_validate_type_descriptor!(inner, false, context)
  end

  defp do_validate_type_descriptor!({:optional, _inner}, true, _context) do
    raise ArgumentError,
          "optional/1 is only valid inside shape/1 field definitions, not as a top-level prop or field type"
  end

  defp do_validate_type_descriptor!({:optional, inner}, false, :shape_field) do
    do_validate_type_descriptor!(inner, false, :shape_field)
  end

  defp do_validate_type_descriptor!({:optional, _inner}, false, _context) do
    raise ArgumentError, "optional/1 is only valid inside shape/1 field definitions"
  end

  defp do_validate_type_descriptor!({:shape, fields}, _top_level?, _context)
       when is_list(fields) do
    unless Keyword.keyword?(fields) do
      raise ArgumentError, "shape/1 expects a keyword list, got: #{inspect(fields)}"
    end

    Enum.each(fields, fn
      {key, value} when is_atom(key) or is_binary(key) ->
        do_validate_type_descriptor!(value, false, :shape_field)

      invalid ->
        raise ArgumentError,
              "shape/1 expects atom or string keys, got: #{inspect(invalid)}"
    end)
  end

  defp do_validate_type_descriptor!(other, _top_level?, _context) do
    raise ArgumentError, "unsupported native type descriptor: #{inspect(other)}"
  end

  defp validate_literal_value!(value)
       when is_binary(value) or is_integer(value) or is_float(value) or is_boolean(value) or
              is_nil(value),
       do: :ok

  defp validate_literal_value!(value) when is_atom(value), do: :ok

  defp validate_literal_value!(value) do
    raise ArgumentError,
          "literal values must be strings, atoms, numbers, booleans, or nil, got: #{inspect(value)}"
  end

  defp normalize_list_inner_type(inner) when is_list(inner) do
    if Keyword.keyword?(inner) and Keyword.has_key?(inner, :enum) do
      {:enum, Keyword.get(inner, :enum)}
    else
      inner
    end
  end

  defp normalize_list_inner_type(inner), do: inner

  defp explicit_ref_descriptor?({:ref, module}) when is_atom(module),
    do: serializer_module_atom?(module)

  defp explicit_ref_descriptor?(_value), do: false

  defp extract_ref_module({:ref, module}), do: module

  defp serializer_module_atom?(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.starts_with?("Elixir.")
  end

  defp serializer_module_atom?(_module), do: false
end
