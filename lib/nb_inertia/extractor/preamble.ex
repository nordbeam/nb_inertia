defmodule NbInertia.Extractor.Preamble do
  @moduledoc """
  Generates TypeScript type preambles from Page module prop declarations.

  The preamble includes auto-generated header comments, import statements
  for serializer types, and a `Props` interface derived from the module's
  prop declarations.

  ## Type Mapping

  | Prop Declaration | Generated Type | Generated Import |
  |---|---|---|
  | `prop :name, :string` | `name: string` | -- |
  | `prop :count, :integer` | `count: number` | -- |
  | `prop :count, :number` | `count: number` | -- |
  | `prop :count, :float` | `count: number` | -- |
  | `prop :active, :boolean` | `active: boolean` | -- |
  | `prop :tags, :list` | `tags: any[]` | -- |
  | `prop :meta, :map` | `meta: Record<string, any>` | -- |
  | `prop :users, list_of(:string)` | `users: string[]` | -- |
  | `prop :users, list_of(ref(UserSerializer))` | `users: User[]` | `import type { User } from '@/types'` |
  | `prop :user, ref(UserSerializer)` | `user: User` | `import type { User } from '@/types'` |
  | `prop :status, enum([:a, :b])` | `status: 'a' \\| 'b'` | -- |
  | `prop :x, :map, nullable: true` | `x: Record<string, any> \\| null` | -- |
  | `prop :x, :string, default: ""` | `x: string` | -- |
  | `prop :x, :string, from: :assigns` | `x: string \\| null` | -- |
  | `prop :x, :string, partial: true` | `x?: string` | -- |
  | `prop :x, :string, defer: true` | `x?: string` | -- |
  | `prop :x, :string, lazy: true` | `x: string` | -- |

  TypeScript optionality follows initial-page presence:
  `default:`, `from:`, and `lazy: true` stay required, while `partial: true`
  and `defer: true` become optional. When `form_inputs/2` matches a compatible
  prop, the generated `Props` field is inlined to that nested form shape.
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

  @doc """
  Generates a complete TypeScript preamble string from a list of prop configs.

  ## Options

    * `:module` - The source Elixir module (for the header comment)
    * `:source_path` - The source file path (for the header comment)
    * `:types_import_path` - The import path for types (default: `"@/types"`)
    * `:forms` - Form input definitions from `form_inputs/2` (optional)
    * `:channel` - Channel config map from `__inertia_channel__/0` (optional)
    * `:camelize_props` - Whether to camelize prop names in channel config (default: `false`)

  ## Returns

  A string containing:
  1. Auto-generated header comment
  2. Import statements for serializer types (if any)
  3. Channel imports and config (if channel is configured)
  4. Props interface declaration
  """
  @spec generate(list(map()), keyword()) :: String.t()
  def generate(props, opts \\ []) do
    module = Keyword.get(opts, :module)
    source_path = Keyword.get(opts, :source_path)
    types_import_path = Keyword.get(opts, :types_import_path, "@/types")
    forms = Keyword.get(opts, :forms, %{})
    channel_config = Keyword.get(opts, :channel)
    camelize? = Keyword.get(opts, :camelize_props, false)

    header = build_header(module, source_path)
    imports = build_imports(props, types_import_path)
    channel_section = build_channel_section(channel_config, camelize?)
    interface = build_interface(props, forms)

    parts =
      [header, imports, channel_section, interface]
      |> Enum.reject(&(&1 == ""))

    Enum.join(parts, "\n\n") <> "\n"
  end

  @doc """
  Converts a single prop config to its TypeScript type string.

  Returns the TypeScript type representation (e.g., `"string"`, `"User[]"`, `"'a' | 'b'"`).
  """
  @spec prop_to_ts_type(map()) :: String.t()
  def prop_to_ts_type(prop) do
    declared_type =
      cond do
        Map.has_key?(prop, :serializer) -> prop.serializer
        true -> prop_declared_type(prop) || :any
      end

    base_type = resolve_type_reference(declared_type, 2)
    opts = prop[:opts] || []
    nullable? = Keyword.get(opts, :nullable, false) || not is_nil(Keyword.get(opts, :from))

    if nullable? and not nullable_descriptor?(declared_type) do
      "#{base_type} | null"
    else
      base_type
    end
  end

  @doc """
  Extracts required type imports from a list of prop configs.

  Returns a list of `{type_name, module}` tuples for serializer types
  that need to be imported.
  """
  @spec extract_imports(list(map())) :: list({String.t(), module()})
  def extract_imports(props) do
    props
    |> Enum.flat_map(&extract_prop_imports/1)
    |> Enum.uniq_by(fn {name, _mod} -> name end)
    |> Enum.sort_by(fn {name, _mod} -> name end)
  end

  @doc """
  Generates a standalone channel config TypeScript file for modules without `render/0`.

  This is used when a Page module declares a channel but uses a standalone
  `.tsx` file instead of a colocated `~TSX` sigil.

  ## Options

    * `:module` - The source Elixir module (for the header comment)
    * `:camelize_props` - Whether to camelize prop names (default: `false`)

  ## Returns

  A complete TypeScript file string with channel config and topic exports.
  """
  @spec generate_channel_config(map(), keyword()) :: String.t()
  def generate_channel_config(channel_config, opts \\ []) do
    module = Keyword.get(opts, :module)
    camelize? = Keyword.get(opts, :camelize_props, false)

    header =
      if module do
        "// AUTO-GENERATED channel config for #{inspect(module)}"
      else
        "// AUTO-GENERATED channel config — do not edit directly"
      end

    events_array = build_channel_events_array(channel_config.events, camelize?)
    topic_export = "export const channelTopic = '#{channel_config.topic}'"

    "#{header}\n\nexport const channelConfig = #{events_array}\n\n#{topic_export}\n"
  end

  # ── Private Functions ──────────────────────────────────

  defp build_header(nil, _source_path),
    do: "// AUTO-GENERATED by NbInertia — do not edit directly"

  defp build_header(module, nil) do
    "// AUTO-GENERATED from #{inspect(module)} — do not edit directly"
  end

  defp build_header(module, source_path) do
    "// AUTO-GENERATED from #{inspect(module)} — do not edit directly\n// Source: #{source_path}"
  end

  defp build_imports(props, types_import_path) do
    imports = extract_imports(props)

    case imports do
      [] ->
        ""

      imports ->
        type_names = Enum.map_join(imports, ", ", fn {name, _mod} -> name end)
        "import type { #{type_names} } from '#{types_import_path}'"
    end
  end

  defp build_channel_section(nil, _camelize?), do: ""

  defp build_channel_section(channel_config, camelize?) do
    imports =
      "// AUTO-GENERATED channel configuration\n" <>
        "import { useChannelProps } from '@nordbeam/nb-inertia/react/realtime/useChannelProps'\n" <>
        "import { socket } from '@/lib/socket'"

    events_array = build_channel_events_array(channel_config.events, camelize?)
    config = "const __channelConfig = #{events_array}"

    "#{imports}\n\n#{config}"
  end

  defp build_channel_events_array(events, camelize?) do
    entries =
      events
      |> Enum.map(fn event -> build_channel_event_entry(event, camelize?) end)
      |> Enum.join(",\n")

    "[\n#{entries},\n] as const"
  end

  defp build_channel_event_entry(event, camelize?) do
    prop_name =
      if camelize? do
        camelize_key(event.prop)
      else
        to_string(event.prop)
      end

    parts = [
      "event: '#{event.event}'",
      "prop: '#{prop_name}'",
      "strategy: '#{event.strategy}'"
    ]

    parts =
      if event.key do
        parts ++ ["key: '#{event.key}'"]
      else
        parts
      end

    "  { #{Enum.join(parts, ", ")} }"
  end

  defp camelize_key(key) when is_atom(key), do: camelize_key(to_string(key))

  defp camelize_key(key) when is_binary(key) do
    key
    |> String.split("_")
    |> Enum.with_index()
    |> Enum.map(fn
      {word, 0} -> String.downcase(word)
      {word, _} -> String.capitalize(word)
    end)
    |> Enum.join()
  end

  defp build_interface(props, forms) do
    fields =
      props
      |> Enum.map(&format_interface_field(&1, forms))
      |> Enum.join("\n")

    "interface Props {\n#{fields}\n}"
  end

  defp format_interface_field(prop, forms) do
    name = to_string(prop[:name] || prop.name)
    ts_type = interface_field_type(prop, forms)
    optional? = ts_optional_field?(prop[:opts] || [])

    if optional? do
      "  #{name}?: #{ts_type}"
    else
      "  #{name}: #{ts_type}"
    end
  end

  defp ts_optional_field?(opts) do
    partial? = Keyword.get(opts, :partial, Keyword.get(opts, :optional, false))
    defer? = Keyword.get(opts, :defer, false)

    partial? || defer?
  end

  defp interface_field_type(prop, forms) do
    form_name = prop[:name] || prop.name

    case Map.get(forms || %{}, form_name) do
      fields when is_list(fields) and fields != [] ->
        if form_inputs_compatible_prop?(prop) do
          inline_form_type(fields, 2)
        else
          prop_to_ts_type(prop)
        end

      _ ->
        prop_to_ts_type(prop)
    end
  end

  defp form_inputs_compatible_prop?(prop_config) do
    opts = Map.get(prop_config, :opts, [])
    declared_type = prop_declared_type(prop_config)

    cond do
      Map.has_key?(prop_config, :serializer) ->
        false

      Keyword.has_key?(opts, :list) or Keyword.has_key?(opts, :enum) ->
        false

      declared_type in [:map, :any] ->
        true

      true ->
        is_nil(declared_type)
    end
  end

  defp prop_declared_type(prop_config) do
    opts = Map.get(prop_config, :opts, [])

    cond do
      Map.has_key?(prop_config, :type) ->
        Map.get(prop_config, :type)

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

  defp inline_form_type(fields, indent_size) do
    camelize? = Application.get_env(:nb_inertia, :snake_case_params, true)
    field_defs = generate_form_field_definitions(fields, camelize?, indent_size + 2)
    "{\n#{field_defs}\n#{spaces(indent_size)}}"
  end

  defp spaces(count) when is_integer(count) and count >= 0 do
    String.duplicate(" ", count)
  end

  defp generate_form_field_definitions(fields, camelize?, indent_size) when is_list(fields) do
    fields
    |> Enum.map_join("\n", fn field ->
      case field do
        {name, :list, opts, nested_fields} when is_list(nested_fields) ->
          field_name = form_field_name(name, camelize?)
          optional_marker = if Keyword.get(opts, :optional, false), do: "?", else: ""

          nested_definitions =
            generate_form_field_definitions(nested_fields, camelize?, indent_size + 2)

          "#{spaces(indent_size)}#{field_name}#{optional_marker}: Array<{\n#{nested_definitions}\n#{spaces(indent_size)}}>;"

        {name, type, opts} ->
          field_name = form_field_name(name, camelize?)
          optional_marker = if Keyword.get(opts, :optional, false), do: "?", else: ""
          ts_type = form_field_ts_type(type, opts)

          "#{spaces(indent_size)}#{field_name}#{optional_marker}: #{ts_type};"
      end
    end)
  end

  defp form_field_name(name, true), do: camelize_key(name)
  defp form_field_name(name, false) when is_atom(name), do: Atom.to_string(name)
  defp form_field_name(name, false), do: to_string(name)

  defp form_field_ts_type({:enum, values}, _opts) when is_list(values) do
    resolve_enum_type(values)
  end

  defp form_field_ts_type({:list, inner_type}, _opts) do
    resolve_list_type(inner_type)
  end

  defp form_field_ts_type(type, opts) when is_list(opts) do
    type
    |> field_declared_type(opts)
    |> resolve_type_reference(2)
  end

  defp form_field_ts_type(type, _opts), do: resolve_type_reference(type, 2)

  # ── Type Resolution ──────────────────────────────────

  defp resolve_simple_type(:string), do: "string"
  defp resolve_simple_type(:integer), do: "number"
  defp resolve_simple_type(:float), do: "number"
  defp resolve_simple_type(:number), do: "number"
  defp resolve_simple_type(:boolean), do: "boolean"
  defp resolve_simple_type(:list), do: "any[]"
  defp resolve_simple_type(:map), do: "Record<string, any>"
  defp resolve_simple_type(:any), do: "any"
  defp resolve_simple_type(:date), do: "string"
  defp resolve_simple_type(:datetime), do: "string"
  defp resolve_simple_type(_), do: "any"

  defp resolve_type_reference({:typescript_validated, ts_string}, _indent_size)
       when is_binary(ts_string),
       do: ts_string

  defp resolve_type_reference(type, _indent_size) when is_binary(type), do: type

  defp resolve_type_reference({:ref, module}, _indent_size) when is_atom(module) do
    serializer_type_name(module)
  end

  defp resolve_type_reference({:list, inner}, indent_size) do
    inner_type = resolve_type_reference(inner, indent_size)
    format_array_type(inner_type)
  end

  defp resolve_type_reference({:enum, values}, _indent_size) when is_list(values) do
    Enum.map_join(values, " | ", &literal_to_typescript/1)
  end

  defp resolve_type_reference({:literal, value}, _indent_size) do
    literal_to_typescript(value)
  end

  defp resolve_type_reference({:union, types}, indent_size) when is_list(types) do
    types
    |> Enum.map_join(" | ", &resolve_type_reference(&1, indent_size))
  end

  defp resolve_type_reference({:nullable, inner}, indent_size) do
    "#{resolve_type_reference(inner, indent_size)} | null"
  end

  defp resolve_type_reference({:optional, inner}, indent_size) do
    resolve_type_reference(inner, indent_size)
  end

  defp resolve_type_reference({:shape, fields}, indent_size)
       when is_list(fields) do
    unless Keyword.keyword?(fields) do
      raise ArgumentError, "shape/1 expects a keyword list, got: #{inspect(fields)}"
    end

    field_defs =
      fields
      |> Enum.map_join("\n", fn {field_name, field_type} ->
        {optional_field?, normalized_type} = unwrap_optional_type(field_type)
        optional_marker = if optional_field?, do: "?", else: ""

        "#{spaces(indent_size + 2)}#{field_name}#{optional_marker}: #{resolve_type_reference(normalized_type, indent_size + 2)};"
      end)

    "{\n#{field_defs}\n#{spaces(indent_size)}}"
  end

  defp resolve_type_reference(type, _indent_size) when type in @primitive_types do
    resolve_simple_type(type)
  end

  defp resolve_type_reference(type, _indent_size) when is_atom(type) do
    if module_atom?(type) do
      serializer_type_name(type)
    else
      "any"
    end
  end

  defp resolve_type_reference(_type, _indent_size), do: "any"

  # ── List Type Resolution ──────────────────────────────

  defp resolve_list_type(inner) when inner in @primitive_types do
    "#{resolve_simple_type(inner)}[]"
  end

  defp resolve_list_type(inner) when is_atom(inner) do
    # Serializer module
    "#{serializer_type_name(inner)}[]"
  end

  defp resolve_list_type(inner) when is_list(inner) do
    # Nested opts like [enum: ["admin", "user"]]
    cond do
      Keyword.has_key?(inner, :enum) ->
        "(#{resolve_enum_type(Keyword.get(inner, :enum))})[]"

      true ->
        "any[]"
    end
  end

  defp resolve_list_type(_), do: "any[]"

  # ── Enum Type Resolution ──────────────────────────────

  defp resolve_enum_type(values) when is_list(values) do
    values
    |> Enum.map_join(" | ", fn v -> "'#{v}'" end)
  end

  defp resolve_enum_type(_), do: "any"

  defp nullable_descriptor?({:nullable, _inner}), do: true
  defp nullable_descriptor?(_type), do: false

  defp unwrap_optional_type({:optional, inner}), do: {true, inner}
  defp unwrap_optional_type(type), do: {false, type}

  defp field_declared_type(type, opts) when is_list(opts) do
    cond do
      not is_nil(type) and type != :any ->
        type

      Keyword.has_key?(opts, :type) ->
        Keyword.get(opts, :type)

      Keyword.has_key?(opts, :list) ->
        {:list, normalize_list_inner_type(Keyword.get(opts, :list))}

      Keyword.has_key?(opts, :enum) ->
        {:enum, Keyword.get(opts, :enum)}

      true ->
        type
    end
  end

  defp format_array_type(inner_type) do
    cond do
      String.starts_with?(inner_type, "{\n") ->
        "Array<#{inner_type}>"

      String.contains?(inner_type, "\n") ->
        "Array<#{inner_type}>"

      String.contains?(inner_type, " | ") ->
        "(#{inner_type})[]"

      Regex.match?(~r/^[A-Za-z0-9_$.]+$/, inner_type) ->
        "#{inner_type}[]"

      true ->
        "Array<#{inner_type}>"
    end
  end

  defp literal_to_typescript(value) when is_binary(value),
    do: "'" <> escape_single_quoted_string(value) <> "'"

  defp literal_to_typescript(value) when is_integer(value) or is_float(value),
    do: to_string(value)

  defp literal_to_typescript(true), do: "true"
  defp literal_to_typescript(false), do: "false"
  defp literal_to_typescript(nil), do: "null"

  defp literal_to_typescript(value) when is_atom(value),
    do: "'" <> escape_single_quoted_string(Atom.to_string(value)) <> "'"

  # ── Serializer Type Name ──────────────────────────────

  @doc """
  Derives a TypeScript type name from a serializer module name.

  Strips the "Serializer" suffix and takes the last module segment.

  ## Examples

      iex> NbInertia.Extractor.Preamble.serializer_type_name(UserSerializer)
      "User"

      iex> NbInertia.Extractor.Preamble.serializer_type_name(MyApp.PostSerializer)
      "Post"

      iex> NbInertia.Extractor.Preamble.serializer_type_name(MyApp.API.CommentSerializer)
      "Comment"

      iex> NbInertia.Extractor.Preamble.serializer_type_name(MyApp.Item)
      "Item"
  """
  @spec serializer_type_name(module()) :: String.t()
  def serializer_type_name(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
    |> String.replace_suffix("Serializer", "")
    |> case do
      "" -> Module.split(module) |> List.last()
      name -> name
    end
  end

  # ── Import Extraction ──────────────────────────────────

  defp extract_prop_imports(%{serializer: serializer}) when is_atom(serializer) do
    if module_atom?(serializer), do: [{serializer_type_name(serializer), serializer}], else: []
  end

  defp extract_prop_imports(%{type: type}) do
    extract_type_imports(type)
  end

  defp extract_prop_imports(%{opts: opts}) when is_list(opts) do
    opts
    |> Keyword.take([:type, :list, :enum])
    |> Enum.flat_map(fn
      {:type, type} -> extract_type_imports(type)
      {:list, inner} -> extract_type_imports({:list, normalize_list_inner_type(inner)})
      {:enum, values} -> extract_type_imports({:enum, values})
    end)
  end

  defp extract_prop_imports(_), do: []

  defp extract_type_imports({:list, inner}), do: extract_type_imports(inner)
  defp extract_type_imports({:ref, module}) when is_atom(module), do: extract_type_imports(module)

  defp extract_type_imports({:union, types}) when is_list(types),
    do: Enum.flat_map(types, &extract_type_imports/1)

  defp extract_type_imports({:nullable, inner}), do: extract_type_imports(inner)
  defp extract_type_imports({:optional, inner}), do: extract_type_imports(inner)

  defp extract_type_imports({:shape, fields}) when is_list(fields) do
    Enum.flat_map(fields, fn {_field_name, field_type} -> extract_type_imports(field_type) end)
  end

  defp extract_type_imports(type) when type in @primitive_types, do: []
  defp extract_type_imports({:enum, _values}), do: []
  defp extract_type_imports({:literal, _value}), do: []
  defp extract_type_imports({:typescript_validated, _ts_string}), do: []
  defp extract_type_imports(type) when is_binary(type), do: []

  defp extract_type_imports(type) when is_atom(type) do
    if module_atom?(type), do: [{serializer_type_name(type), type}], else: []
  end

  defp extract_type_imports(_type), do: []

  defp normalize_list_inner_type(inner) when is_list(inner) do
    if Keyword.keyword?(inner) and Keyword.has_key?(inner, :enum) do
      {:enum, Keyword.get(inner, :enum)}
    else
      inner
    end
  end

  defp normalize_list_inner_type(inner), do: inner

  defp module_atom?(type) when is_atom(type) do
    type
    |> Atom.to_string()
    |> String.starts_with?("Elixir.")
  end

  defp escape_single_quoted_string(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("'", "\\'")
  end
end
