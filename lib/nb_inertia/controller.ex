defmodule NbInertia.Controller do
  @moduledoc """
  Controller DSL for declaring Inertia pages with type-safe prop definitions.

  Provides macros for declaring Inertia pages with compile-time validation
  and support for both raw props and NbSerializer-based serialization.

  ## Usage

      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, :list
          prop :total_count, :integer
        end

        def index(conn, _params) do
          render_inertia(conn, :users_index,
            users: list_users(),
            total_count: count_users()
          )
        end
      end

  ## With NbSerializer

  If you have `nb_serializer` installed, you can use automatic serialization:

      inertia_page :users_index do
        prop :users, UserSerializer
        prop :total_count, :integer
      end

      def index(conn, _params) do
        render_inertia_serialized(conn, :users_index,
          users: {UserSerializer, list_users()},
          total_count: count_users()
        )
      end

  ## With NbTs (Optional)

  If you have `nb_ts` installed, this module automatically registers a compile hook
  that regenerates TypeScript types whenever your controllers are recompiled. This
  provides real-time type synchronization between your backend prop definitions and
  frontend TypeScript types during development, with no manual intervention required.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import NbInertia.Controller

      # Import NbInertia.CoreController functions except those we override
      import NbInertia.CoreController,
        except: [
          render_inertia: 2,
          render_inertia: 3,
          render_inertia: 4
        ]

      Module.register_attribute(__MODULE__, :inertia_pages, accumulate: false)
      Module.register_attribute(__MODULE__, :inertia_shared, accumulate: false)
      Module.register_attribute(__MODULE__, :inertia_shared_modules, accumulate: true)
      Module.register_attribute(__MODULE__, :current_page, accumulate: false)
      Module.register_attribute(__MODULE__, :current_props, accumulate: true)

      # Form inputs tracking for TypeScript generation
      Module.register_attribute(__MODULE__, :current_page_forms, accumulate: false)
      Module.register_attribute(__MODULE__, :current_form_name, accumulate: false)
      Module.register_attribute(__MODULE__, :current_form_fields, accumulate: true)

      Module.put_attribute(__MODULE__, :inertia_pages, %{})
      Module.put_attribute(__MODULE__, :inertia_shared, [])
      Module.put_attribute(__MODULE__, :current_page_forms, %{})

      # Optional: Register compile hook for NbTs type generation
      # This enables real-time TypeScript type regeneration when controllers are recompiled
      # Only activates if nb_ts is installed (it's an optional dependency)
      if Code.ensure_loaded?(NbTs.CompileHooks) do
        @after_compile {NbTs.CompileHooks, :__after_compile__}
      end

      @before_compile NbInertia.Controller
    end
  end

  @doc """
  Declares an Inertia page with its props.

  ## Examples

      inertia_page :users_index do
        prop :users, :list
        prop :total_count, :integer
      end

      inertia_page :user_profile, component: "UserProfile" do
        prop :user, :map
      end

      # Override TypeScript type name to avoid collisions
      inertia_page :preview, component: "Public/WidgetShow", type_name: "WidgetPreviewProps" do
        prop :widget, WidgetSerializer
      end
  """
  defmacro inertia_page(page_name, opts \\ [], do: block) do
    quote do
      Module.put_attribute(__MODULE__, :current_page, unquote(page_name))
      Module.delete_attribute(__MODULE__, :current_props)
      Module.put_attribute(__MODULE__, :current_page_forms, %{})

      unquote(block)

      props = Module.get_attribute(__MODULE__, :current_props) |> Enum.reverse()
      forms = Module.get_attribute(__MODULE__, :current_page_forms) || %{}
      pages = Module.get_attribute(__MODULE__, :inertia_pages)

      component =
        case unquote(opts)[:component] do
          nil -> NbInertia.ComponentNaming.infer(unquote(page_name))
          explicit -> explicit
        end

      # Build page config
      page_config = %{
        component: component,
        props: props
      }

      # Add forms if any were defined
      page_config =
        if forms == %{} do
          page_config
        else
          Map.put(page_config, :forms, forms)
        end

      # Add index_signature if provided in opts
      page_config =
        case unquote(opts)[:index_signature] do
          nil -> page_config
          value -> Map.put(page_config, :index_signature, value)
        end

      # Add type_name if provided in opts
      page_config =
        case unquote(opts)[:type_name] do
          nil -> page_config
          value -> Map.put(page_config, :type_name, value)
        end

      Module.put_attribute(
        __MODULE__,
        :inertia_pages,
        Map.put(pages, unquote(page_name), page_config)
      )

      Module.delete_attribute(__MODULE__, :current_page)
      Module.delete_attribute(__MODULE__, :current_props)
      Module.delete_attribute(__MODULE__, :current_page_forms)
    end
  end

  @doc """
  Declares a prop within an inertia_page block.

  ## Unified Syntax

  Props use a unified syntax matching NbSerializer's field syntax:

      # Primitives
      prop :id, :integer
      prop :name, :string
      prop :active, :boolean

      # Lists of primitives
      prop :tags, list: :string       # TypeScript: string[]
      prop :scores, list: :number     # TypeScript: number[]

      # Enums
      prop :status, enum: ["active", "inactive"]
      # TypeScript: "active" | "inactive"

      # List of enums
      prop :roles, list: [enum: ["admin", "user"]]
      # TypeScript: ("admin" | "user")[]

      # Serializers (with nb_serializer)
      prop :user, UserSerializer      # Single serializer
      prop :users, list: UserSerializer  # List of serializers

      # Modifiers
      prop :priority, enum: ["low", "high"], optional: true
      prop :notes, list: :string, optional: true
      prop :posts, :list, lazy: true
      prop :stats, :map, defer: true, optional: true
      prop :flash, from: :assigns
  """
  defmacro prop(name, type_or_serializer \\ nil, opts \\ [])

  # Handle prop with only name and options (no serializer/type)
  defmacro prop(name, opts, []) when is_list(opts) do
    quote bind_quoted: [name: name, opts: opts] do
      prop_config = %{name: name, opts: opts}

      # Handle the :from option for shared props
      prop_config =
        case Keyword.get(opts, :from) do
          nil -> prop_config
          from -> Map.put(prop_config, :from, from)
        end

      Module.put_attribute(__MODULE__, :current_props, prop_config)
    end
  end

  # Handle prop with name, type/serializer, and options
  defmacro prop(name, type_or_serializer, opts) do
    quote bind_quoted: [name: name, type_or_serializer: type_or_serializer, opts: opts] do
      prop_config =
        case type_or_serializer do
          type
          when is_atom(type) and type in [:string, :integer, :float, :boolean, :map, :list] ->
            %{name: name, type: type, opts: opts}

          serializer when is_atom(serializer) ->
            %{name: name, serializer: serializer, opts: opts}

          other ->
            %{name: name, serializer: other, opts: opts}
        end

      # Handle the :from option for shared props
      prop_config =
        case Keyword.get(opts, :from) do
          nil -> prop_config
          from -> Map.put(prop_config, :from, from)
        end

      Module.put_attribute(__MODULE__, :current_props, prop_config)
    end
  end

  @doc """
  Declares shared props available to all pages or registers a SharedProps module.

  ## Examples

  Inline DSL:

      inertia_shared do
        prop :current_user, :map, from: :assigns
        prop :flash, from: :assigns
      end

  Register SharedProps module:

      inertia_shared(MyAppWeb.InertiaShared.Auth)

  Conditional sharing (matches Phoenix plug pattern):

      # Only for specific actions
      inertia_shared(MyAppWeb.InertiaShared.Auth, only: [:index, :show])

      # Except for specific actions
      inertia_shared(MyAppWeb.InertiaShared.Public, except: [:admin])

      # Conditional based on guard function
      inertia_shared(MyAppWeb.InertiaShared.Admin, when: :admin?)

      # Multiple conditions
      inertia_shared(MyAppWeb.InertiaShared.Features, only: [:index], when: :feature_enabled?)

  ## Options

    * `:only` - List of action names where this shared prop module should be applied
    * `:except` - List of action names where this shared prop module should NOT be applied
    * `:when` - Atom referencing a guard function that returns true/false

  Guard functions receive the conn as the first argument:

      defp admin?(conn) do
        conn.assigns[:current_user]?.role == :admin
      end
  """
  defmacro inertia_shared(module_or_block, opts \\ [])

  defmacro inertia_shared(module, opts) when is_atom(module) or is_list(opts) do
    quote do
      config = %{
        module: unquote(module),
        only: unquote(opts)[:only],
        except: unquote(opts)[:except],
        when: unquote(opts)[:when]
      }

      Module.put_attribute(__MODULE__, :inertia_shared_modules, config)
    end
  end

  defmacro inertia_shared(opts, do: block) when is_list(opts) do
    quote do
      Module.put_attribute(__MODULE__, :current_page, :__shared__)
      Module.delete_attribute(__MODULE__, :current_props)

      unquote(block)

      shared_props = Module.get_attribute(__MODULE__, :current_props) |> Enum.reverse()
      Module.put_attribute(__MODULE__, :inertia_shared, shared_props)
      Module.delete_attribute(__MODULE__, :current_page)
      Module.delete_attribute(__MODULE__, :current_props)
    end
  end

  @doc """
  Defines form input fields for TypeScript type generation.

  This macro does NOT perform any validation - it is purely for type generation.
  All validation should be handled by changesets on the server.

  ## Examples

      inertia_page :users_new do
        prop :user, :map, default: %{}

        form_inputs :user do
          field :name, :string
          field :email, :string
          field :age, :integer, optional: true
        end
      end

  This generates:

      export interface UsersNewFormInputs {
        user: {
          name: string;
          email: string;
          age?: number;
        }
      }
  """
  defmacro form_inputs(name, do: block) when is_atom(name) do
    quote do
      # Set current form context
      Module.put_attribute(__MODULE__, :current_form_name, unquote(name))

      # Execute block (collects field definitions)
      unquote(block)

      # Store accumulated fields in current page forms
      fields = Module.get_attribute(__MODULE__, :current_form_fields) || []
      current_page_forms = Module.get_attribute(__MODULE__, :current_page_forms) || %{}

      Module.put_attribute(
        __MODULE__,
        :current_page_forms,
        Map.put(current_page_forms, unquote(name), Enum.reverse(fields))
      )

      # Reset context
      Module.delete_attribute(__MODULE__, :current_form_name)
      Module.delete_attribute(__MODULE__, :current_form_fields)
    end
  end

  @doc """
  Defines a form field with type information.

  ## Options

    * `:optional` - Field is optional (default: false)

  ## Examples

      field :name, :string
      field :email, :string
      field :age, :integer, optional: true
      field :bio, :string, optional: true

  ## Nested List Fields

      field :questions, :list do
        field :text, :string
        field :required, :boolean
      end
  """
  # Handle field/4 when block is passed with enum or typed list
  # This should error since enums and typed lists cannot have nested blocks
  defmacro field(name, type, _opts, do: _block) when is_atom(name) and is_tuple(type) do
    quote do
      # Check what kind of tuple type this is for better error messages
      type_description =
        case unquote(type) do
          {:enum, _values} -> "Enum types"
          {:list, _inner_type} -> "Typed lists"
          _ -> "Typed fields"
        end

      type_example =
        case unquote(type) do
          {:enum, _values} -> "field :status, {:enum, [\"active\", \"inactive\"]}"
          {:list, _inner_type} -> "field :tags, {:list, :string}"
          _ -> "field :field_name, #{inspect(unquote(type))}"
        end

      raise CompileError,
        file: __ENV__.file,
        line: __ENV__.line,
        description: """
        cannot use nested block with #{String.downcase(type_description)}.

        #{type_description} define specific types and cannot have nested blocks.

        You used: field #{inspect(unquote(name))}, #{inspect(unquote(type))} do

        Either:
        1. Use a regular :list with nested block:
           field :questions, :list do
             field :text, :string
           end

        2. Or use #{String.downcase(type_description)} without a block:
           #{type_example}
        """
    end
  end

  # Handle field/4 when block is passed with explicit opts: field(:name, :list, [optional: true], do: block)
  defmacro field(name, type, opts, do: block) when is_atom(name) and is_atom(type) do
    quote do
      # Validate we're inside a form_inputs block
      if !Module.get_attribute(__MODULE__, :current_form_name) do
        raise CompileError,
          file: __ENV__.file,
          line: __ENV__.line,
          description: """
          field/3 must be used inside a form_inputs block.

          Example:
            form_inputs :user do
              field :name, :string
            end
          """
      end

      # Validate that blocks are only used with :list type
      if unquote(type) != :list do
        raise CompileError,
          file: __ENV__.file,
          line: __ENV__.line,
          description: """
          field with nested block must have type :list.

          You tried to use a nested block with type #{inspect(unquote(type))}.

          Correct usage:
            field :questions, :list do
              field :text, :string
            end

          If you want a nested object (not a list), consider flattening your form structure.
          """
      end

      # Track current field count before executing block
      current_fields = Module.get_attribute(__MODULE__, :current_form_fields) || []
      parent_field_count = length(current_fields)

      # Execute block to collect nested fields
      unquote(block)

      # Get all fields (parent + nested)
      # Note: accumulate: true attributes are in reverse order (most recent first)
      # So all_fields = [nested_field3, nested_field2, nested_field1, parent_field2, parent_field1]
      all_fields = Module.get_attribute(__MODULE__, :current_form_fields) || []

      # Extract nested fields (from the beginning of the list)
      nested_fields = Enum.take(all_fields, length(all_fields) - parent_field_count)

      # Extract parent fields (from the end of the list)
      parent_fields = Enum.take(all_fields, -parent_field_count)

      # Reset to parent fields only
      Module.delete_attribute(__MODULE__, :current_form_fields)

      Enum.each(Enum.reverse(parent_fields), fn field ->
        Module.put_attribute(__MODULE__, :current_form_fields, field)
      end)

      # Store field with nested fields: {name, type, opts, nested_fields}
      Module.put_attribute(
        __MODULE__,
        :current_form_fields,
        {unquote(name), unquote(type), unquote(opts), Enum.reverse(nested_fields)}
      )
    end
  end

  # Handle field/2 when opts are provided directly (type inferred from options)
  # Examples: field(:tags, list: :string), field(:status, enum: ["active", "inactive"])
  defmacro field(name, opts) when is_atom(name) and is_list(opts) do
    quote bind_quoted: [name: name, opts: opts] do
      # Validate we're inside a form_inputs block
      if !Module.get_attribute(__MODULE__, :current_form_name) do
        raise CompileError,
          file: __ENV__.file,
          line: __ENV__.line,
          description: """
          field/2 must be used inside a form_inputs block.

          Example:
            form_inputs :user do
              field :name, :string
            end
          """
      end

      # Type is :any when using list/enum options
      type = :any

      # Store field definition as a tuple: {name, type, opts}
      Module.put_attribute(__MODULE__, :current_form_fields, {name, type, opts})
    end
  end

  # Declare field/3 with default opts
  defmacro field(name, type, opts \\ [])

  # Handle field/3 with tuple type (typed lists): field(:name, {:list, :string}, [optional: true])
  defmacro field(name, type, opts) when is_atom(name) and is_tuple(type) do
    # Check if block is in opts (error case)
    {block, clean_opts} =
      case Keyword.pop(opts, :do) do
        {nil, opts} -> {nil, opts}
        {block, opts} -> {block, opts}
      end

    if block do
      # Error: cannot use block with enum or typed list
      quote do
        # Check what kind of tuple type this is for better error messages
        type_description =
          case unquote(type) do
            {:enum, _values} -> "Enum types"
            {:list, _inner_type} -> "Typed lists"
            _ -> "Typed fields"
          end

        type_example =
          case unquote(type) do
            {:enum, _values} -> "field :status, {:enum, [\"active\", \"inactive\"]}"
            {:list, _inner_type} -> "field :tags, {:list, :string}"
            _ -> "field :field_name, #{inspect(unquote(type))}"
          end

        raise CompileError,
          file: __ENV__.file,
          line: __ENV__.line,
          description: """
          cannot use nested block with #{String.downcase(type_description)}.

          #{type_description} define specific types and cannot have nested blocks.

          You used: field #{inspect(unquote(name))}, #{inspect(unquote(type))} do

          Either:
          1. Use a regular :list with nested block:
             field :questions, :list do
               field :text, :string
             end

          2. Or use #{String.downcase(type_description)} without a block:
             #{type_example}
          """
      end
    else
      # Generate code for typed list field (no block)
      quote bind_quoted: [name: name, type: type, opts: clean_opts] do
        # Validate we're inside a form_inputs block
        if !Module.get_attribute(__MODULE__, :current_form_name) do
          raise CompileError,
            file: __ENV__.file,
            line: __ENV__.line,
            description: """
            field/3 must be used inside a form_inputs block.

            Example:
              form_inputs :user do
                field :name, :string
              end
            """
        end

        # Store typed list field definition as a tuple: {name, type, opts}
        Module.put_attribute(__MODULE__, :current_form_fields, {name, type, opts})
      end
    end
  end

  # Handle field/3 which may have :do in opts or be a regular field
  defmacro field(name, type, opts) when is_atom(name) and is_atom(type) do
    # Extract block at macro expansion time (before quote)
    {block, clean_opts} =
      case Keyword.pop(opts, :do) do
        {nil, opts} -> {nil, opts}
        {block, opts} -> {block, opts}
      end

    if block do
      # Generate code for field with nested block (from field :name, :list do syntax)
      quote do
        # Validate we're inside a form_inputs block
        if !Module.get_attribute(__MODULE__, :current_form_name) do
          raise CompileError,
            file: __ENV__.file,
            line: __ENV__.line,
            description: """
            field/3 must be used inside a form_inputs block.

            Example:
              form_inputs :user do
                field :name, :string
              end
            """
        end

        # Validate that blocks are only used with :list type
        if unquote(type) != :list do
          raise CompileError,
            file: __ENV__.file,
            line: __ENV__.line,
            description: """
            field with nested block must have type :list.

            You tried to use a nested block with type #{inspect(unquote(type))}.

            Correct usage:
              field :questions, :list do
                field :text, :string
              end

            If you want a nested object (not a list), consider flattening your form structure.
            """
        end

        # Track current field count before executing block
        current_fields = Module.get_attribute(__MODULE__, :current_form_fields) || []
        parent_field_count = length(current_fields)

        # Execute block to collect nested fields
        unquote(block)

        # Get all fields (parent + nested)
        # Note: accumulate: true attributes are in reverse order (most recent first)
        # So all_fields = [nested_field3, nested_field2, nested_field1, parent_field2, parent_field1]
        all_fields = Module.get_attribute(__MODULE__, :current_form_fields) || []

        # Extract nested fields (from the beginning of the list)
        nested_fields = Enum.take(all_fields, length(all_fields) - parent_field_count)

        # Extract parent fields (from the end of the list)
        parent_fields = Enum.take(all_fields, -parent_field_count)

        # Reset to parent fields only
        Module.delete_attribute(__MODULE__, :current_form_fields)

        Enum.each(Enum.reverse(parent_fields), fn field ->
          Module.put_attribute(__MODULE__, :current_form_fields, field)
        end)

        # Store field with nested fields: {name, type, opts, nested_fields}
        Module.put_attribute(
          __MODULE__,
          :current_form_fields,
          {unquote(name), unquote(type), unquote(clean_opts), Enum.reverse(nested_fields)}
        )
      end
    else
      # Generate code for regular field
      quote bind_quoted: [name: name, type: type, opts: clean_opts] do
        # Validate we're inside a form_inputs block
        if !Module.get_attribute(__MODULE__, :current_form_name) do
          raise CompileError,
            file: __ENV__.file,
            line: __ENV__.line,
            description: """
            field/3 must be used inside a form_inputs block.

            Example:
              form_inputs :user do
                field :name, :string
              end
            """
        end

        # Store regular field definition as a tuple: {name, type, opts}
        Module.put_attribute(__MODULE__, :current_form_fields, {name, type, opts})
      end
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    pages = Module.get_attribute(env.module, :inertia_pages)
    shared_props = Module.get_attribute(env.module, :inertia_shared)
    shared_modules = Module.get_attribute(env.module, :inertia_shared_modules) |> Enum.reverse()

    # Validate no prop name collisions between shared props and page props
    validate_prop_collisions!(env.module, pages, shared_props, shared_modules)

    # Generate page/1 function
    page_clauses =
      for {page_name, config} <- pages do
        quote do
          def page(unquote(page_name)), do: unquote(config.component)
        end
      end

    # Generate catch-all for undeclared pages
    available_pages = Map.keys(pages)

    page_error_clause =
      quote do
        def page(name) do
          available = unquote(available_pages) |> Enum.map_join(", ", &inspect/1)

          raise ArgumentError, """
          Inertia page not declared: #{inspect(name)}

          The page #{inspect(name)} has not been declared in #{inspect(__MODULE__)}.

          Available pages: #{available}

          To fix this, declare the page in your controller:

              defmodule #{inspect(__MODULE__)} do
                use NbInertia.Controller

                inertia_page #{inspect(name)} do
                  prop :my_prop, :string
                  # ... add your props
                end

                def my_action(conn, _params) do
                  render_inertia(conn, #{inspect(name)},
                    my_prop: "value"
                  )
                end
              end

          Or use a string component name instead:

              render_inertia(conn, "MyComponent")

          See: https://hexdocs.pm/nb_inertia/NbInertia.Controller.html#inertia_page/2
          """
        end
      end

    # Generate inertia_page_config/1 function
    config_clauses =
      for {page_name, config} <- pages do
        quote do
          def inertia_page_config(unquote(page_name)) do
            unquote(Macro.escape(config))
          end
        end
      end

    # Generate inertia_shared_props/0 function
    shared_props_clause =
      quote do
        def inertia_shared_props do
          unquote(Macro.escape(shared_props))
        end
      end

    # Generate __inertia_pages__/0 function for introspection
    inertia_pages_clause =
      quote do
        def __inertia_pages__ do
          unquote(Macro.escape(pages))
        end
      end

    # Generate __inertia_shared_modules__/0 function
    shared_modules_clause =
      quote do
        def __inertia_shared_modules__ do
          unquote(Macro.escape(shared_modules))
        end
      end

    # Generate __inertia_forms__/0 function for introspection
    # Extract forms from all pages since forms are now stored per-page
    pages = Module.get_attribute(env.module, :inertia_pages) || %{}

    all_forms =
      Enum.reduce(pages, %{}, fn {_page_name, page_config}, acc ->
        case Map.get(page_config, :forms) do
          nil -> acc
          forms when is_map(forms) -> Map.merge(acc, forms)
        end
      end)

    inertia_forms_clause =
      quote do
        def __inertia_forms__ do
          unquote(Macro.escape(all_forms))
        end
      end

    quote do
      unquote(page_clauses)
      unquote(page_error_clause)
      unquote(config_clauses)
      unquote(shared_props_clause)
      unquote(inertia_pages_clause)
      unquote(shared_modules_clause)
      unquote(inertia_forms_clause)
    end
  end

  @doc false
  defp validate_prop_collisions!(module, pages, inline_shared_props, _shared_modules) do
    # Get all shared prop names from inline shared props
    inline_shared_prop_names =
      inline_shared_props
      |> Enum.map(& &1.name)
      |> MapSet.new()

    # Get all shared prop names from shared modules
    # Note: At compile time, we can't easily introspect other modules
    # So we'll document this limitation and only check inline shared props
    # Users should ensure SharedProps modules don't collide manually

    shared_prop_names = inline_shared_prop_names

    # Check each page for collisions
    for {page_name, page_config} <- pages do
      page_prop_names = Enum.map(page_config.props, & &1.name) |> MapSet.new()
      collisions = MapSet.intersection(shared_prop_names, page_prop_names)

      if MapSet.size(collisions) > 0 do
        collision_list = MapSet.to_list(collisions) |> Enum.map_join(", ", &inspect/1)

        raise CompileError,
          description: """
          Prop name collision detected in #{inspect(module)}.#{page_name}

          The following props are defined both as shared props and page props:
          #{collision_list}

          Shared props and page props must have unique names to avoid conflicts.

          To fix this:
          1. Rename the shared props to be more specific:
             inertia_shared do
               prop :auth_user, :map  # instead of :user
               prop :global_flash, :map  # instead of :flash
             end

          2. Or rename the page props:
             inertia_page #{inspect(page_name)} do
               prop :page_user, UserSerializer  # instead of :user
             end

          3. Or use namespacing in your prop names:
             Shared: :auth, :global
             Page: :users, :posts, :comments

          Note: If using SharedProps modules, ensure those don't collide either.
          """,
          file: "#{inspect(module)}.ex"
      end
    end

    :ok
  end

  @doc """
  Renders an Inertia response with support for atom-based page references.

  This overrides NbInertia.CoreController.render_inertia to support:
  - Atom page references (e.g., `:users_index`) with automatic component name lookup
  - All-in-one pattern with props and validation (3-arity)
  - Pipe-friendly pattern (2-arity)
  - Automatic shared props injection
  - Deep merge support for nested props
  - Backward compatibility with string component names

  ## Options

    * `:deep_merge` - When `true`, recursively merges nested maps in shared props with page props.
      Overrides the global `deep_merge_shared_props` config setting.

  ## Examples

      # All-in-one pattern (with validation)
      render_inertia(conn, :users_index,
        users: users,
        total_count: 42
      )

      # With deep merge (per-action override)
      render_inertia(conn, :users_index,
        [settings: %{theme: "light"}],
        deep_merge: true
      )

      # Pipe-friendly pattern (flexible, no validation)
      conn
      |> assign_prop(:users, users)
      |> assign_prop(:total_count, 42)
      |> render_inertia(:users_index)

      # Backward compatible with strings
      conn
      |> assign_prop(:data, "test")
      |> render_inertia("CustomComponent")
  """
  defmacro render_inertia(conn, component_or_page, props \\ [], opts \\ [])

  # 4-arity: All-in-one with props and options
  defmacro render_inertia(conn, page_ref, props, opts) when is_atom(page_ref) and is_list(opts) do
    # Perform compile-time validation if in dev/test
    # This runs during macro expansion, not at runtime
    if Mix.env() in [:dev, :test] and is_list(props) and props != [] do
      # Get the page config directly from module attributes
      # (can't use inertia_page_config/1 because @before_compile hasn't run yet)
      pages = Module.get_attribute(__CALLER__.module, :inertia_pages) || %{}
      page_config = Map.get(pages, page_ref)

      if page_config do
        # Validate props at compile-time
        declared_props = page_config.props
        provided_prop_names = Keyword.keys(props) |> MapSet.new()
        declared_prop_names = Enum.map(declared_props, & &1.name) |> MapSet.new()

        # Find required props
        required_props =
          declared_props
          |> Enum.reject(fn prop ->
            Keyword.get(prop.opts, :optional, false) ||
              Keyword.get(prop.opts, :lazy, false) ||
              Keyword.get(prop.opts, :defer, false)
          end)
          |> MapSet.new(& &1.name)

        # Check for missing required props
        missing_props = MapSet.difference(required_props, provided_prop_names)

        if MapSet.size(missing_props) > 0 do
          missing_list = MapSet.to_list(missing_props) |> Enum.map_join(", ", &inspect/1)

          raise CompileError,
            description: """
            Missing required props for Inertia page :#{page_ref}

            Missing props: #{missing_list}

            Add the missing props to your render_inertia call or mark them as optional.
            """,
            file: __CALLER__.file,
            line: __CALLER__.line
        end

        # Check for undeclared props
        extra_props = MapSet.difference(provided_prop_names, declared_prop_names)

        if MapSet.size(extra_props) > 0 do
          extra_list = MapSet.to_list(extra_props) |> Enum.map_join(", ", &inspect/1)

          raise CompileError,
            description: """
            Undeclared props provided for Inertia page :#{page_ref}

            Undeclared props: #{extra_list}

            Remove these props or declare them in your inertia_page block.
            """,
            file: __CALLER__.file,
            line: __CALLER__.line
        end
      end
    end

    quote do
      import NbInertia.CoreController, only: [assign_prop: 3]

      conn_value = unquote(conn)
      page_ref = unquote(page_ref)
      props = unquote(props)

      # Look up the component name
      component = page(page_ref)

      # Get registered shared modules
      shared_modules = __inertia_shared_modules__()

      # Get current action name for conditional filtering
      action = Phoenix.Controller.action_name(conn_value)

      # Filter and build props from shared modules that match conditions
      shared_module_props =
        shared_modules
        |> Enum.filter(
          &NbInertia.Controller.should_apply_shared_module?(&1, conn_value, action, __MODULE__)
        )
        |> Enum.reduce(%{}, fn module_config, acc ->
          module = if is_atom(module_config), do: module_config, else: module_config.module
          module_props = module.build_props(conn_value, [])
          Map.merge(acc, module_props)
        end)

      # Get inline shared props and pull them from assigns
      shared_props = inertia_shared_props()

      shared_prop_assignments =
        Enum.map(shared_props, fn prop_config ->
          case prop_config do
            %{from: :assigns, name: name} ->
              data = Map.get(conn_value.assigns, name)
              {name, data}

            _ ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      # Determine if we should use deep merge
      deep_merge? =
        Keyword.get(unquote(opts), :deep_merge, NbInertia.Config.deep_merge_shared_props())

      # Combine shared props (module + inline) into a single map
      all_shared_props =
        if deep_merge? do
          NbInertia.DeepMerge.deep_merge(
            shared_module_props,
            Enum.into(shared_prop_assignments, %{})
          )
        else
          Map.merge(shared_module_props, Enum.into(shared_prop_assignments, %{}))
        end

      # Combine shared props with provided page props
      all_props_map =
        if deep_merge? do
          NbInertia.DeepMerge.deep_merge(all_shared_props, Enum.into(props, %{}))
        else
          Map.merge(all_shared_props, Enum.into(props, %{}))
        end

      # Convert back to keyword list and split into serialized/raw
      all_props = Map.to_list(all_props_map)

      {serialized_props, raw_props} =
        Enum.split_with(all_props, fn {_key, value} ->
          is_tuple(value) and tuple_size(value) >= 2 and is_atom(elem(value, 0))
        end)

      # Assign serialized props if any (and if nb_serializer is available)
      conn_value =
        if serialized_props != [] and Code.ensure_loaded?(NbSerializer) do
          NbInertia.Controller.assign_serialized_props(conn_value, serialized_props)
        else
          conn_value
        end

      # Assign raw props
      conn_value =
        Enum.reduce(raw_props, conn_value, fn {key, value}, acc ->
          assign_prop(acc, key, value)
        end)

      # Apply camelization if configured
      conn_value =
        if NbInertia.Config.camelize_props?() do
          NbInertia.CoreController.camelize_props(conn_value, true)
        else
          conn_value
        end

      # Don't delegate to Inertia.Controller for final render - handle SSR ourselves
      NbInertia.Controller.do_render_inertia(conn_value, component)
    end
  end

  # 2-arity, 3-arity with empty props, or non-atom page: Pipe-friendly pattern or string component
  defmacro render_inertia(conn, component_or_page, _props, _opts) do
    cond do
      # If it's a string literal, pass through directly
      is_binary(component_or_page) ->
        quote do
          conn_value = unquote(conn)

          conn_value =
            if NbInertia.Config.camelize_props?() do
              NbInertia.CoreController.camelize_props(conn_value, true)
            else
              conn_value
            end

          NbInertia.Controller.do_render_inertia(conn_value, unquote(component_or_page))
        end

      # If it's an atom literal
      is_atom(component_or_page) ->
        quote do
          conn_value = unquote(conn)
          page_ref = unquote(component_or_page)

          # Look up the component name
          component = __MODULE__.page(page_ref)

          # Get registered shared modules
          shared_modules = __MODULE__.__inertia_shared_modules__()

          # Get current action name for conditional filtering
          action = Phoenix.Controller.action_name(conn_value)

          # Filter and build props from shared modules that match conditions
          shared_module_props =
            shared_modules
            |> Enum.filter(
              &NbInertia.Controller.should_apply_shared_module?(
                &1,
                conn_value,
                action,
                __MODULE__
              )
            )
            |> Enum.reduce(%{}, fn module_config, acc ->
              module = if is_atom(module_config), do: module_config, else: module_config.module
              module_props = module.build_props(conn_value, [])
              Map.merge(acc, module_props)
            end)

          # Get inline shared props
          shared_props = __MODULE__.inertia_shared_props()

          # Add inline shared props to conn
          conn_value =
            Enum.reduce(shared_props, conn_value, fn prop_config, acc ->
              case prop_config do
                %{from: :assigns, name: name} ->
                  data = Map.get(acc.assigns, name)
                  NbInertia.CoreController.assign_prop(acc, name, data)

                _ ->
                  acc
              end
            end)

          # Add shared module props
          conn_value =
            Enum.reduce(shared_module_props, conn_value, fn {key, value}, acc ->
              NbInertia.CoreController.assign_prop(acc, key, value)
            end)

          # Apply camelization if configured
          conn_value =
            if NbInertia.Config.camelize_props?() do
              NbInertia.CoreController.camelize_props(conn_value, true)
            else
              conn_value
            end

          NbInertia.Controller.do_render_inertia(conn_value, component)
        end

      # Default: pass through
      true ->
        quote do
          conn_value = unquote(conn)

          conn_value =
            if NbInertia.Config.camelize_props?() do
              NbInertia.CoreController.camelize_props(conn_value, true)
            else
              conn_value
            end

          NbInertia.Controller.do_render_inertia(conn_value, unquote(component_or_page))
        end
    end
  end

  @doc """
  Validates that the provided props match the declared props for a page.

  Raises an ArgumentError if:
  - Required props are missing
  - Undeclared props are provided

  Optional props (with `optional: true`) are allowed to be omitted.
  """
  @spec validate_page_props!(module(), atom(), keyword()) :: :ok
  def validate_page_props!(module, page_name, provided_props) do
    page_config = module.inertia_page_config(page_name)
    declared_props = page_config.props

    # Get prop names
    provided_prop_names = Keyword.keys(provided_props) |> MapSet.new()
    declared_prop_names = Enum.map(declared_props, & &1.name) |> MapSet.new()

    # Find required props (not optional, lazy, or defer)
    required_props =
      declared_props
      |> Enum.reject(fn prop ->
        Keyword.get(prop.opts, :optional, false) ||
          Keyword.get(prop.opts, :lazy, false) ||
          Keyword.get(prop.opts, :defer, false)
      end)
      |> MapSet.new(& &1.name)

    # Check for missing required props
    missing_props = MapSet.difference(required_props, provided_prop_names)

    if MapSet.size(missing_props) > 0 do
      missing_list = MapSet.to_list(missing_props) |> Enum.map_join(", ", &inspect/1)

      raise ArgumentError, """
      Missing required props for Inertia page

      Page: #{inspect(page_name)} in #{inspect(module)}
      Missing props: #{missing_list}

      These props are required but were not provided in the render_inertia call.

      Expected props:
        #{format_props_for_error(declared_props)}

      Current call:
        render_inertia(conn, #{inspect(page_name)}, [
          #{format_provided_props(MapSet.to_list(provided_prop_names))}
        ])

      Add the missing props:
        render_inertia(conn, #{inspect(page_name)}, [
          #{format_provided_props(MapSet.to_list(provided_prop_names))}
          #{format_missing_props(MapSet.to_list(missing_props))}  # Add these
        ])

      Or mark them as optional in the page declaration:
        prop #{Enum.at(MapSet.to_list(missing_props), 0)}, :type, optional: true

      See: https://hexdocs.pm/nb_inertia/NbInertia.Controller.html#render_inertia/3
      """
    end

    # Check for undeclared props
    extra_props = MapSet.difference(provided_prop_names, declared_prop_names)

    if MapSet.size(extra_props) > 0 do
      extra_list = MapSet.to_list(extra_props) |> Enum.map_join(", ", &inspect/1)

      raise ArgumentError, """
      Undeclared props provided for Inertia page

      Page: #{inspect(page_name)} in #{inspect(module)}
      Undeclared props: #{extra_list}

      These props were provided but not declared in the inertia_page block.

      Expected props:
        #{format_props_for_error(declared_props)}

      Provided props:
        #{format_provided_props(MapSet.to_list(provided_prop_names))}

      To fix this, either:

      1. Remove the undeclared props from your render_inertia call:
         render_inertia(conn, #{inspect(page_name)}, [
           #{MapSet.difference(provided_prop_names, extra_props) |> MapSet.to_list() |> format_provided_props()}
         ])

      2. Or declare them in your inertia_page block:
         inertia_page #{inspect(page_name)} do
           #{format_props_declaration(declared_props)}
           #{format_missing_props_declaration(MapSet.to_list(extra_props))}  # Add these
         end

      See: https://hexdocs.pm/nb_inertia/NbInertia.Controller.html#inertia_page/2
      """
    end

    :ok
  end

  # Helper functions for formatting error messages
  defp format_props_for_error(props) do
    props
    |> Enum.map_join("\n        ", fn prop ->
      type_info =
        case prop do
          %{serializer: serializer} when not is_nil(serializer) ->
            "#{inspect(serializer)}"

          %{type: type} when not is_nil(type) ->
            inspect(type)

          _ ->
            "any"
        end

      opts_info =
        case prop do
          %{opts: opts} when is_list(opts) and opts != [] ->
            relevant_opts = Keyword.take(opts, [:optional, :lazy, :defer])

            if relevant_opts == [] do
              ""
            else
              " (#{Enum.map(relevant_opts, fn {k, v} -> "#{k}: #{inspect(v)}" end) |> Enum.join(", ")})"
            end

          _ ->
            ""
        end

      "#{inspect(prop.name)}: #{type_info}#{opts_info}"
    end)
  end

  defp format_provided_props([]), do: ""

  defp format_provided_props(prop_names) do
    prop_names
    |> Enum.map_join("\n          ", &"#{&1}: value,")
  end

  defp format_missing_props([]), do: ""

  defp format_missing_props(prop_names) do
    prop_names
    |> Enum.map_join("\n          ", &"#{&1}: value,")
  end

  defp format_props_declaration(props) do
    props
    |> Enum.map_join("\n           ", fn prop ->
      type_or_serializer =
        case prop do
          %{serializer: serializer} when not is_nil(serializer) ->
            inspect(serializer)

          %{type: type} when not is_nil(type) ->
            inspect(type)

          _ ->
            nil
        end

      if type_or_serializer do
        "prop #{inspect(prop.name)}, #{type_or_serializer}"
      else
        "prop #{inspect(prop.name)}"
      end
    end)
  end

  defp format_missing_props_declaration([]), do: ""

  defp format_missing_props_declaration(prop_names) do
    prop_names
    |> Enum.map_join("\n           ", &"prop #{inspect(&1)}, :type")
  end

  @doc """
  Determines if a shared module should be applied based on conditional options.

  Handles filtering by:
  - `:only` - Only apply for specific actions
  - `:except` - Apply for all actions except specified ones
  - `:when` - Apply when guard function returns true

  ## Examples

      should_apply_shared_module?(%{only: [:index]}, conn, :index, MyController)
      # => true

      should_apply_shared_module?(%{except: [:admin]}, conn, :admin, MyController)
      # => false

      should_apply_shared_module?(%{when: :admin?}, conn, :index, MyController)
      # => calls MyController.admin?(conn)
  """
  def should_apply_shared_module?(module_config, conn, action, controller_module)

  # Handle old-style atom modules (backward compatibility)
  def should_apply_shared_module?(module, _conn, _action, _controller_module)
      when is_atom(module) do
    true
  end

  # Handle module config with :only option
  def should_apply_shared_module?(%{only: only} = config, conn, action, controller_module)
      when not is_nil(only) do
    action_matches = action in List.wrap(only)

    # Also check :when condition if present
    if action_matches and not is_nil(config[:when]) do
      check_when_condition(config[:when], conn, controller_module)
    else
      action_matches
    end
  end

  # Handle module config with :except option
  def should_apply_shared_module?(%{except: except} = config, conn, action, controller_module)
      when not is_nil(except) do
    action_does_not_match = action not in List.wrap(except)

    # Also check :when condition if present
    if action_does_not_match and not is_nil(config[:when]) do
      check_when_condition(config[:when], conn, controller_module)
    else
      action_does_not_match
    end
  end

  # Handle module config with only :when option
  def should_apply_shared_module?(%{when: when_fn}, conn, _action, controller_module)
      when not is_nil(when_fn) do
    check_when_condition(when_fn, conn, controller_module)
  end

  # Handle module config with no conditions - always apply
  def should_apply_shared_module?(_config, _conn, _action, _controller_module) do
    true
  end

  # Helper to check :when condition
  defp check_when_condition(when_fn, conn, controller_module) do
    if function_exported?(controller_module, when_fn, 1) do
      apply(controller_module, when_fn, [conn])
    else
      raise ArgumentError, """
      Guard function #{inspect(when_fn)}/1 not found in #{inspect(controller_module)}

      When using `when:` option with inertia_shared, you must define the guard function:

          defp #{when_fn}(conn) do
            # Return true or false
          end
      """
    end
  end

  # NbSerializer integration functions (only available when nb_serializer is loaded)
  if Code.ensure_loaded?(NbSerializer) do
    @doc """
    Assigns serialized data as an Inertia prop using an NbSerializer serializer.

    This function is only available when `nb_serializer` is installed.

    ## Parameters

      - `conn` - The connection struct
      - `key` - The prop name (atom or string)
      - `serializer` - The NbSerializer serializer module
      - `data` - The data to serialize (or a 0-arity function that returns data)
      - `options` - Optional keyword list of options

    ## Options

      - `:lazy` - When `true`, only serializes on partial reloads (default: `false`)
      - `:optional` - When `true`, excludes on first visit (default: `false`)
      - `:defer` - When `true` or a string (group name), marks for deferred loading (default: `false`)
      - `:merge` - When `true`, marks for merging with existing client data (default: `false`)
      - `:merge` - When `:deep`, marks for deep merging
      - `:opts` - Serialization options to pass to `NbSerializer.serialize/3` (default: `[]`)

    ## Lazy Function Evaluation

    You can pass a 0-arity function as the `data` parameter. Functions are automatically
    treated as `optional: true` - they will only be executed when the prop is requested
    (e.g., on partial reloads). This is useful for expensive operations that should only
    run on demand.

    ## Examples

        # Eager evaluation - data computed immediately
        assign_serialized(conn, :user, UserSerializer, user)

        # Lazy function - automatically optional, only executes when requested
        assign_serialized(conn, :themes, ThemeSerializer, fn ->
          Themes.expensive_fetch()
        end)

        # Explicit optional: false to force immediate execution (not recommended)
        assign_serialized(conn, :posts, PostSerializer, fn ->
          Posts.list_all()
        end, optional: false)

        # Deferred loading with regular data
        assign_serialized(conn, :stats, StatsSerializer, stats, defer: true)
    """
    @spec assign_serialized(
            Plug.Conn.t(),
            atom() | String.t(),
            module(),
            any(),
            keyword()
          ) :: Plug.Conn.t()
    def assign_serialized(conn, key, serializer, data, options \\ []) do
      # If data is a function, automatically treat as optional (lazy evaluation)
      # Functions should only execute when prop is requested
      is_function_data? = is_function(data, 0)

      lazy? = Keyword.get(options, :lazy, false)
      optional? = Keyword.get(options, :optional, is_function_data?)
      defer = Keyword.get(options, :defer, false)
      merge = Keyword.get(options, :merge, false)
      # Disable NbSerializer camelization since NbInertia handles it
      # This prevents double-camelization and preserves {:preserve, key} tuples
      serialization_opts = Keyword.merge([camelize: false], Keyword.get(options, :opts, []))

      # Build the serialization function
      serialize_fn = fn ->
        # If data is a 0-arity function, execute it first (lazy evaluation)
        # This allows passing functions that are only executed when the prop is requested
        actual_data = if is_function(data, 0), do: data.(), else: data

        case NbSerializer.serialize(serializer, actual_data, serialization_opts) do
          {:ok, serialized} -> serialized
          {:error, error} -> raise error
        end
      end

      # Wrap based on options
      value =
        cond do
          optional? ->
            NbInertia.CoreController.inertia_optional(serialize_fn)

          is_binary(defer) ->
            NbInertia.CoreController.inertia_defer(serialize_fn, defer)

          defer == true ->
            NbInertia.CoreController.inertia_defer(serialize_fn)

          lazy? ->
            serialize_fn

          true ->
            serialize_fn.()
        end

      # Apply merge wrapper if needed
      value =
        case merge do
          :deep -> NbInertia.CoreController.inertia_deep_merge(value)
          true -> NbInertia.CoreController.inertia_merge(value)
          false -> value
        end

      # Assign the prop
      NbInertia.CoreController.assign_prop(conn, key, value)
    end

    @doc """
    Assigns serialized errors from an Ecto changeset or error map.

    This function is only available when `nb_serializer` is installed.

    ## Parameters

      - `conn` - The connection struct
      - `errors` - An `Ecto.Changeset` or error map

    ## Examples

        def create(conn, params) do
          case MyApp.Accounts.create_user(params) do
            {:ok, user} ->
              conn
              |> put_flash(:info, "User created")
              |> redirect(to: ~p"/users/\#{user.id}")

            {:error, changeset} ->
              conn
              |> assign_serialized_errors(changeset)
              |> redirect(to: ~p"/users/new")
          end
        end
    """
    @spec assign_serialized_errors(Plug.Conn.t(), Ecto.Changeset.t() | map()) :: Plug.Conn.t()
    def assign_serialized_errors(conn, errors) do
      NbInertia.CoreController.assign_errors(conn, errors)
    end

    @doc """
    Assigns multiple serialized props at once.

    This function is only available when `nb_serializer` is installed.

    ## Parameters

      - `conn` - The connection struct
      - `props` - A keyword list where values are tuples of `{serializer, data}` or `{serializer, data, options}`

    ## Examples

        conn
        |> assign_serialized_props(
          user: {UserSerializer, current_user},
          posts: {PostSerializer, posts, lazy: true},
          stats: {StatsSerializer, stats, defer: true}
        )
        |> render_inertia(:dashboard)
    """
    @spec assign_serialized_props(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
    def assign_serialized_props(conn, props) do
      Enum.reduce(props, conn, fn {key, value}, acc ->
        case value do
          {serializer, data} ->
            assign_serialized(acc, key, serializer, data)

          {serializer, data, options} when is_list(options) ->
            assign_serialized(acc, key, serializer, data, options)

          _ ->
            raise ArgumentError,
                  "Expected prop value to be {serializer, data} or {serializer, data, options}, got: #{inspect(value)}"
        end
      end)
    end
  else
    @doc false
    def assign_serialized(_conn, _key, _serializer, _data, _options \\ []) do
      raise """
      NbSerializer package not found

      The function assign_serialized/5 requires the `nb_serializer` package to be installed.

      Add it to your dependencies in mix.exs:

          defp deps do
            [
              {:nb_inertia, "~> 0.1"},
              {:nb_serializer, "~> 0.1"}  # Add this line
            ]
          end

      Then run:

          mix deps.get

      Without nb_serializer, use regular assign_prop instead:

          conn
          |> assign_prop(:users, users)
          |> render_inertia(:users_index)

      See: https://hexdocs.pm/nb_serializer
      """
    end

    @doc false
    def assign_serialized_errors(_conn, _errors) do
      raise """
      NbSerializer package not found

      The function assign_serialized_errors/2 requires the `nb_serializer` package to be installed.

      Add it to your dependencies in mix.exs:

          defp deps do
            [
              {:nb_inertia, "~> 0.1"},
              {:nb_serializer, "~> 0.1"}  # Add this line
            ]
          end

      Then run:

          mix deps.get

      Without nb_serializer, use assign_errors directly:

          conn
          |> assign_errors(changeset)
          |> render_inertia(:form_page)

      See: https://hexdocs.pm/nb_serializer
      """
    end

    @doc false
    def assign_serialized_props(_conn, _props) do
      raise """
      NbSerializer package not found

      The function assign_serialized_props/2 requires the `nb_serializer` package to be installed.

      Add it to your dependencies in mix.exs:

          defp deps do
            [
              {:nb_inertia, "~> 0.1"},
              {:nb_serializer, "~> 0.1"}  # Add this line
            ]
          end

      Then run:

          mix deps.get

      Without nb_serializer, assign props individually:

          conn
          |> assign_prop(:user, user)
          |> assign_prop(:posts, posts)
          |> render_inertia(:dashboard)

      See: https://hexdocs.pm/nb_serializer
      """
    end
  end

  @doc """
  Enables server-side rendering for the current request.

  ## Example

      conn
      |> enable_ssr()
      |> render_inertia("Dashboard")
  """
  def enable_ssr(conn) do
    Plug.Conn.put_private(conn, :nb_inertia_ssr_enabled, true)
  end

  @doc """
  Disables server-side rendering for the current request.

  ## Example

      conn
      |> disable_ssr()
      |> render_inertia("Dashboard")
  """
  def disable_ssr(conn) do
    Plug.Conn.put_private(conn, :nb_inertia_ssr_enabled, false)
  end

  @doc """
  Checks if SSR is enabled for the current request.
  """
  def ssr_enabled?(conn) do
    case conn.private[:nb_inertia_ssr_enabled] do
      nil -> NbInertia.SSR.ssr_enabled?()
      value -> value
    end
  end

  @doc """
  Renders an Inertia modal response.

  This macro renders a modal that overlays the current page without full navigation.
  It supports the same prop patterns as `render_inertia/3`, plus modal-specific options.

  ## Modal-Specific Options

    - `:base_url` - The URL of the page "behind" the modal (required). Can be a string
      or a RouteResult from nb_routes rich mode.
    - `:size` - Modal size (`:sm`, `:md`, `:lg`, `:xl`, `:full`, or custom string)
    - `:position` - Modal position (`:center`, `:top`, `:bottom`, `:left`, `:right`)
    - `:slideover` - Boolean, render as slideover instead of centered modal
    - `:close_button` - Boolean, show close button (default: true)
    - `:close_explicitly` - Boolean, require explicit close (disable backdrop/ESC)
    - `:max_width` - Custom max-width CSS value
    - `:padding_classes` - Custom padding CSS classes
    - `:panel_classes` - Custom panel CSS classes
    - `:backdrop_classes` - Custom backdrop CSS classes

  ## Examples

      # Basic modal with base URL
      render_inertia_modal(conn, :user_details,
        [user: user],
        base_url: "/users"
      )

      # Modal with nb_routes RouteResult
      render_inertia_modal(conn, :user_details,
        [user: user],
        base_url: users_path()
      )

      # Slideover with custom size
      render_inertia_modal(conn, :edit_user,
        [user: user, form: form],
        base_url: user_path(user.id),
        slideover: true,
        position: :right,
        size: :lg
      )

      # Modal with explicit close only
      render_inertia_modal(conn, :confirm_delete,
        [item: item],
        base_url: items_path(),
        close_explicitly: true,
        close_button: false
      )

      # Pipe-friendly pattern
      conn
      |> assign_prop(:user, user)
      |> assign_prop(:comments, comments)
      |> render_inertia_modal(:user_details, base_url: "/users")
  """
  # 4-arity: All-in-one with props and options
  defmacro render_inertia_modal(conn, page_ref, props, opts)
           when is_atom(page_ref) and is_list(props) and is_list(opts) do
    quote do
      import NbInertia.CoreController, only: [assign_prop: 3]

      conn_value = unquote(conn)
      page_ref = unquote(page_ref)
      props = unquote(props)
      opts = unquote(opts)

      # Look up the component name
      component = __MODULE__.page(page_ref)

      # Assign props using the same logic as render_inertia
      {serialized_props, raw_props} =
        Enum.split_with(props, fn {_key, value} ->
          is_tuple(value) and tuple_size(value) >= 2 and is_atom(elem(value, 0))
        end)

      # Assign serialized props if any
      conn_value =
        if serialized_props != [] and Code.ensure_loaded?(NbSerializer) do
          NbInertia.Controller.assign_serialized_props(conn_value, serialized_props)
        else
          conn_value
        end

      # Assign raw props
      conn_value =
        Enum.reduce(raw_props, conn_value, fn {key, value}, acc ->
          assign_prop(acc, key, value)
        end)

      # Build and render modal
      NbInertia.Controller.do_render_inertia_modal(conn_value, component, opts)
    end
  end

  # 3-arity: Either props-only or opts-only
  defmacro render_inertia_modal(conn, page_ref, props_or_opts) when is_atom(page_ref) do
    quote do
      conn_value = unquote(conn)
      page_ref = unquote(page_ref)
      props_or_opts = unquote(props_or_opts)

      # Determine if this is props or opts
      {props, opts} =
        if Keyword.keyword?(props_or_opts) and Keyword.has_key?(props_or_opts, :base_url) do
          # It's opts only
          {[], props_or_opts}
        else
          # It's props only
          {props_or_opts, []}
        end

      # Delegate to 4-arity version
      NbInertia.Controller.render_inertia_modal(conn_value, page_ref, props, opts)
    end
  end

  # String component version
  defmacro render_inertia_modal(conn, component, props_or_opts) when is_binary(component) do
    quote do
      conn_value = unquote(conn)
      component = unquote(component)
      props_or_opts = unquote(props_or_opts)

      # Determine if this is props or opts
      {_props, opts} =
        if Keyword.keyword?(props_or_opts) and Keyword.has_key?(props_or_opts, :base_url) do
          {[], props_or_opts}
        else
          {props_or_opts, []}
        end

      # For string components, props should already be assigned via assign_prop
      NbInertia.Controller.do_render_inertia_modal(conn_value, component, opts)
    end
  end

  @doc false
  def do_render_inertia_modal(conn, component, opts) do
    # Extract modal options
    base_url_opt = Keyword.get(opts, :base_url)

    if is_nil(base_url_opt) do
      raise ArgumentError, """
      render_inertia_modal requires a :base_url option

      Example:
          render_inertia_modal(conn, :user_details,
            [user: user],
            base_url: "/users"
          )

      Or with nb_routes:
          render_inertia_modal(conn, :user_details,
            [user: user],
            base_url: users_path()
          )
      """
    end

    # Extract base URL from RouteResult or string
    base_url =
      case base_url_opt do
        %{url: url} when is_binary(url) -> url
        url when is_binary(url) -> url
        _ -> raise ArgumentError, ":base_url must be a string or RouteResult struct"
      end

    # Build modal configuration
    modal =
      NbInertia.Modal.new(component, %{})
      |> NbInertia.Modal.base_url(base_url)
      |> apply_modal_config_options(opts)

    # First, assign modal props normally
    shared_props = conn.private[:inertia_shared] || %{}

    modal_with_props = %{modal | props: shared_props}

    # Use BaseRenderer to render the modal
    case NbInertia.Modal.BaseRenderer.render(conn, modal_with_props) do
      {:ok, conn} ->
        # Now render the actual Inertia response with the modal data
        # The BaseRenderer has already injected modal data into conn.assigns
        NbInertia.Controller.do_render_inertia(conn, component)

      {:error, reason} ->
        raise RuntimeError, "Failed to render modal: #{inspect(reason)}"
    end
  end

  defp apply_modal_config_options(modal, opts) do
    Enum.reduce(opts, modal, fn
      {:size, size}, acc -> NbInertia.Modal.size(acc, size)
      {:position, position}, acc -> NbInertia.Modal.position(acc, position)
      {:slideover, enabled}, acc -> NbInertia.Modal.slideover(acc, enabled)
      {:close_button, enabled}, acc -> NbInertia.Modal.close_button(acc, enabled)
      {:close_explicitly, enabled}, acc -> NbInertia.Modal.close_explicitly(acc, enabled)
      {:max_width, max_width}, acc -> NbInertia.Modal.max_width(acc, max_width)
      {:padding_classes, classes}, acc -> NbInertia.Modal.padding_classes(acc, classes)
      {:panel_classes, classes}, acc -> NbInertia.Modal.panel_classes(acc, classes)
      {:backdrop_classes, classes}, acc -> NbInertia.Modal.backdrop_classes(acc, classes)
      {:base_url, _}, acc -> acc
      # Ignore unknown options
      _, acc -> acc
    end)
  end

  @doc false
  def do_render_inertia(conn, component) do
    # Emit telemetry for render start
    action = Phoenix.Controller.action_name(conn)
    controller = Phoenix.Controller.controller_module(conn)

    metadata = %{
      component: component,
      action: action,
      controller: controller
    }

    start_time = System.monotonic_time()
    NbInertia.Telemetry.render_start(metadata)

    try do
      # Call NbInertia.CoreController.render_inertia but intercept SSR rendering
      # We do this by ensuring the conn doesn't have :inertia_ssr set,
      # then handling SSR ourselves based on :nb_inertia_ssr_enabled

      conn = Plug.Conn.put_private(conn, :inertia_ssr, false)

      result =
        if ssr_enabled?(conn) do
          # Handle SSR ourselves with NbInertia.SSR
          do_render_with_ssr(conn, component)
        else
          # Let Inertia.Controller handle CSR
          NbInertia.CoreController.render_inertia(conn, component)
        end

      # Emit telemetry for successful render
      duration = System.monotonic_time() - start_time
      NbInertia.Telemetry.render_stop(duration, metadata)

      result
    rescue
      e ->
        # Emit telemetry for render exception
        duration = System.monotonic_time() - start_time

        NbInertia.Telemetry.render_exception(
          duration,
          :error,
          e,
          __STACKTRACE__,
          metadata
        )

        reraise e, __STACKTRACE__
    catch
      kind, reason ->
        duration = System.monotonic_time() - start_time

        NbInertia.Telemetry.render_exception(
          duration,
          kind,
          reason,
          __STACKTRACE__,
          metadata
        )

        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  defp do_render_with_ssr(conn, component) do
    # Use CoreController.render_inertia with SSR enabled
    # It will handle prop resolution, deferred props, etc.
    NbInertia.CoreController.render_inertia(conn, component, ssr: true)
  end
end
