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

      Module.put_attribute(__MODULE__, :inertia_pages, %{})
      Module.put_attribute(__MODULE__, :inertia_shared, [])

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
  """
  defmacro inertia_page(page_name, opts \\ [], do: block) do
    quote do
      Module.put_attribute(__MODULE__, :current_page, unquote(page_name))
      Module.delete_attribute(__MODULE__, :current_props)

      unquote(block)

      props = Module.get_attribute(__MODULE__, :current_props) |> Enum.reverse()
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

      # Add index_signature if provided in opts
      page_config =
        case unquote(opts)[:index_signature] do
          nil -> page_config
          value -> Map.put(page_config, :index_signature, value)
        end

      Module.put_attribute(
        __MODULE__,
        :inertia_pages,
        Map.put(pages, unquote(page_name), page_config)
      )

      Module.delete_attribute(__MODULE__, :current_page)
      Module.delete_attribute(__MODULE__, :current_props)
    end
  end

  @doc """
  Declares a prop within an inertia_page block.

  ## Examples

      prop :user, :map
      prop :total_count, :integer
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
  """
  defmacro inertia_shared(module_or_block)

  defmacro inertia_shared(do: block) do
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

  defmacro inertia_shared(module) do
    quote do
      Module.put_attribute(__MODULE__, :inertia_shared_modules, unquote(module))
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    pages = Module.get_attribute(env.module, :inertia_pages)
    shared_props = Module.get_attribute(env.module, :inertia_shared)
    shared_modules = Module.get_attribute(env.module, :inertia_shared_modules) |> Enum.reverse()

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
          available = unquote(available_pages) |> Enum.map(&inspect/1) |> Enum.join(", ")

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

    quote do
      unquote(page_clauses)
      unquote(page_error_clause)
      unquote(config_clauses)
      unquote(shared_props_clause)
      unquote(inertia_pages_clause)
      unquote(shared_modules_clause)
    end
  end

  @doc """
  Renders an Inertia response with support for atom-based page references.

  This overrides NbInertia.CoreController.render_inertia to support:
  - Atom page references (e.g., `:users_index`) with automatic component name lookup
  - All-in-one pattern with props and validation (3-arity)
  - Pipe-friendly pattern (2-arity)
  - Automatic shared props injection
  - Backward compatibility with string component names

  ## Examples

      # All-in-one pattern (with validation)
      render_inertia(conn, :users_index,
        users: users,
        total_count: 42
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
  defmacro render_inertia(conn, component_or_page, props \\ [])

  # 3-arity: All-in-one with props
  defmacro render_inertia(conn, page_ref, props)
           when is_atom(page_ref) and is_list(props) and props != [] do
    quote bind_quoted: [conn: conn, page_ref: page_ref, props: props] do
      import NbInertia.CoreController, only: [assign_prop: 3]

      # Look up the component name
      component = page(page_ref)

      # Get registered shared modules
      shared_modules = __inertia_shared_modules__()

      # Build props from all shared modules
      shared_module_props =
        Enum.reduce(shared_modules, %{}, fn module, acc ->
          module_props = module.build_props(conn, [])
          Map.merge(acc, module_props)
        end)

      # Validate props in dev mode
      if Application.get_env(:nb_inertia, :env, :prod) in [:dev, :test] do
        NbInertia.Controller.validate_page_props!(__MODULE__, page_ref, props)

        # Check for collisions between shared module props and page props
        provided_prop_names = Keyword.keys(props) |> MapSet.new()
        shared_module_prop_names = Map.keys(shared_module_props) |> MapSet.new()
        collisions = MapSet.intersection(provided_prop_names, shared_module_prop_names)

        if MapSet.size(collisions) > 0 do
          collision_list = MapSet.to_list(collisions) |> Enum.map(&inspect/1) |> Enum.join(", ")

          raise ArgumentError,
                "Prop name collision detected between shared module props and page props: #{collision_list}. " <>
                  "Shared modules and page props cannot define the same prop names."
        end
      end

      # Get inline shared props and pull them from assigns
      shared_props = inertia_shared_props()

      shared_prop_assignments =
        Enum.map(shared_props, fn prop_config ->
          case prop_config do
            %{from: :assigns, name: name} ->
              data = Map.get(conn.assigns, name)
              {name, data}

            _ ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      # Combine shared props with provided props
      all_props = shared_prop_assignments ++ props

      # Split props into serialized (tuples) and raw values
      {serialized_props, raw_props} =
        Enum.split_with(all_props, fn {_key, value} ->
          is_tuple(value) and tuple_size(value) >= 2 and is_atom(elem(value, 0))
        end)

      # Assign serialized props if any (and if nb_serializer is available)
      conn =
        if serialized_props != [] and Code.ensure_loaded?(NbSerializer) do
          NbInertia.Controller.assign_serialized_props(conn, serialized_props)
        else
          conn
        end

      # Assign raw props
      conn =
        Enum.reduce(raw_props, conn, fn {key, value}, acc ->
          assign_prop(acc, key, value)
        end)

      # Assign shared module props
      conn =
        Enum.reduce(shared_module_props, conn, fn {key, value}, acc ->
          assign_prop(acc, key, value)
        end)

      # Apply camelization if configured
      conn =
        if NbInertia.Config.camelize_props?() do
          NbInertia.CoreController.camelize_props(conn, true)
        else
          conn
        end

      # Don't delegate to Inertia.Controller for final render - handle SSR ourselves
      NbInertia.Controller.do_render_inertia(conn, component)
    end
  end

  # 2-arity or 3-arity with empty props: Pipe-friendly pattern or string component
  defmacro render_inertia(conn, component_or_page, _props) do
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

          # Build props from all shared modules
          shared_module_props =
            Enum.reduce(shared_modules, %{}, fn module, acc ->
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
      |> Enum.map(& &1.name)
      |> MapSet.new()

    # Check for missing required props
    missing_props = MapSet.difference(required_props, provided_prop_names)

    if MapSet.size(missing_props) > 0 do
      missing_list = MapSet.to_list(missing_props) |> Enum.map(&inspect/1) |> Enum.join(", ")

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
      extra_list = MapSet.to_list(extra_props) |> Enum.map(&inspect/1) |> Enum.join(", ")

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
           #{format_provided_props(MapSet.difference(provided_prop_names, extra_props) |> MapSet.to_list())}
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
    |> Enum.map(fn prop ->
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
    |> Enum.join("\n        ")
  end

  defp format_provided_props([]), do: ""

  defp format_provided_props(prop_names) do
    prop_names
    |> Enum.map(&"#{&1}: value,")
    |> Enum.join("\n          ")
  end

  defp format_missing_props([]), do: ""

  defp format_missing_props(prop_names) do
    prop_names
    |> Enum.map(&"#{&1}: value,")
    |> Enum.join("\n          ")
  end

  defp format_props_declaration(props) do
    props
    |> Enum.map(fn prop ->
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
    |> Enum.join("\n           ")
  end

  defp format_missing_props_declaration([]), do: ""

  defp format_missing_props_declaration(prop_names) do
    prop_names
    |> Enum.map(&"prop #{inspect(&1)}, :type")
    |> Enum.join("\n           ")
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
      - `data` - The data to serialize
      - `options` - Optional keyword list of options

    ## Options

      - `:lazy` - When `true`, only serializes on partial reloads (default: `false`)
      - `:optional` - When `true`, excludes on first visit (default: `false`)
      - `:defer` - When `true` or a string (group name), marks for deferred loading (default: `false`)
      - `:merge` - When `true`, marks for merging with existing client data (default: `false`)
      - `:merge` - When `:deep`, marks for deep merging
      - `:opts` - Serialization options to pass to `NbSerializer.serialize/3` (default: `[]`)

    ## Examples

        assign_serialized(conn, :user, UserSerializer, user)
        assign_serialized(conn, :posts, PostSerializer, posts, lazy: true)
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
      lazy? = Keyword.get(options, :lazy, false)
      optional? = Keyword.get(options, :optional, false)
      defer = Keyword.get(options, :defer, false)
      merge = Keyword.get(options, :merge, false)
      serialization_opts = Keyword.get(options, :opts, [])

      # Build the serialization function
      serialize_fn = fn ->
        case NbSerializer.serialize(serializer, data, serialization_opts) do
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

  @doc false
  def do_render_inertia(conn, component) do
    # Call NbInertia.CoreController.render_inertia but intercept SSR rendering
    # We do this by ensuring the conn doesn't have :inertia_ssr set,
    # then handling SSR ourselves based on :nb_inertia_ssr_enabled

    conn = Plug.Conn.put_private(conn, :inertia_ssr, false)

    if ssr_enabled?(conn) do
      # Handle SSR ourselves with NbInertia.SSR
      do_render_with_ssr(conn, component)
    else
      # Let Inertia.Controller handle CSR
      NbInertia.CoreController.render_inertia(conn, component)
    end
  end

  defp do_render_with_ssr(conn, component) do
    # Use CoreController.render_inertia with SSR enabled
    # It will handle prop resolution, deferred props, etc.
    NbInertia.CoreController.render_inertia(conn, component, ssr: true)
  end
end
