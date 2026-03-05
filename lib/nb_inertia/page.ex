defmodule NbInertia.Page do
  @moduledoc """
  LiveView-style Page modules for Inertia.js.

  Provides a declarative, single-module-per-page pattern inspired by Phoenix LiveView.
  Each page defines its props, mount/2 callback, and optional action/3 callback in a
  single module.

  ## Usage

      defmodule MyAppWeb.UsersPage.Index do
        use NbInertia.Page

        prop :users, :list
        prop :total_count, :integer

        def mount(_conn, _params) do
          %{users: Accounts.list_users(), total_count: Accounts.count_users()}
        end
      end

  The component name is derived by convention from the module name:
  `MyAppWeb.UsersPage.Index` → `"Users/Index"`.

  ## Options

  Options can be passed to `use NbInertia.Page`:

      use NbInertia.Page,
        component: "Custom/Path",    # Override component name
        ssr: true,                    # Enable SSR
        camelize_props: true,         # Camelize prop keys
        encrypt_history: true,        # Encrypt history state
        clear_history: true,          # Clear history on visit
        preserve_fragment: true,      # Preserve URL fragment
        layout: :admin                # Layout selection (future)

  ## Callbacks

  - `mount/2` — `(conn, params) -> props_map | conn` — Required. Initialize props on GET.
  - `action/3` — `(conn, params, verb) -> redirect | {:error, term}` — Optional. Handle mutations.
  - `render/0` — `() -> ~TSX | ~JSX` — Optional. Colocated frontend component.

  ## Props

  Props use the same DSL as `NbInertia.Controller`:

      prop :name, :string
      prop :user, UserSerializer
      prop :tags, list: :string
      prop :status, enum: ["active", "inactive"]
      prop :stats, :map, defer: true
      prop :draft, :map, nullable: true, default: %{}

  ## Form Inputs

      form_inputs :user_form do
        field :name, :string
        field :email, :string
        field :role, :string, optional: true
      end

  ## Shared Props

  Register shared props modules or inline shared props:

      # Module-based
      shared MyAppWeb.SharedProps

      # Inline
      shared do
        prop :locale, :string
      end

  Page-level shared props are additive to router-level shared props and take
  precedence when keys overlap.

  ## Modal Support

  Configure the page to be renderable as a modal:

      modal base_url: "/users",
            size: :lg,
            position: :center

  Dynamic base URL via mount/2:

      def mount(conn, %{"id" => id}) do
        conn
        |> modal_config(base_url: ~p"/users/\#{id}")
        |> props(%{user: Accounts.get_user!(id)})
      end

  ## Precognition

  Use `precognition` macro in action/3 for real-time form validation:

      def action(conn, %{"user" => params}, :create) do
        changeset = Accounts.change_user(%User{}, params)
        precognition conn, changeset do
          case Accounts.create_user(params) do
            {:ok, user} -> redirect(conn, ~p"/users/\#{user}")
            {:error, changeset} -> {:error, changeset}
          end
        end
      end

  ## mount/2 Return Values

      # Props map (most common)
      def mount(_conn, _params), do: %{users: list_users()}

      # Conn pipeline + props helper
      def mount(conn, _params) do
        conn
        |> encrypt_history()
        |> props(%{users: list_users()})
      end

      # Early redirect
      def mount(conn, %{"id" => id}) do
        case get_user(id) do
          nil -> redirect(conn, to: "/users")
          user -> %{user: user}
        end
      end

  ## action/3 Return Values

      # Redirect (success)
      def action(conn, params, :create) do
        {:ok, user} = create_user(params)
        redirect(conn, to: "/users/\#{user.id}")
      end

      # Error (re-renders with errors)
      def action(_conn, params, :update) do
        case update_user(params) do
          {:ok, _} -> redirect(conn, to: "/users")
          {:error, changeset} -> {:error, changeset}
        end
      end
  """

  @doc false
  defmacro __using__(opts) do
    quote do
      # Import ~TSX and ~JSX sigils for colocated frontend components
      import NbInertia.Sigil, only: [sigil_TSX: 2, sigil_JSX: 2]

      # Import the prop/form DSL macros from Controller
      import NbInertia.Controller,
        only: [
          prop: 2,
          prop: 3,
          form_inputs: 2,
          field: 2,
          field: 3,
          field: 4
        ]

      # Import runtime helpers from CoreController
      import NbInertia.CoreController,
        only: [
          inertia_optional: 1,
          inertia_always: 1,
          inertia_merge: 1,
          inertia_deep_merge: 1,
          inertia_prepend: 1,
          inertia_match_merge: 2,
          inertia_scroll: 1,
          inertia_scroll: 2,
          inertia_defer: 1,
          inertia_defer: 2,
          inertia_once: 1,
          inertia_once: 2,
          once_fresh: 1,
          once_fresh: 2,
          once_until: 2,
          once_as: 2,
          defer_once: 1,
          preserve_case: 1,
          assign_prop: 3,
          assign_errors: 2,
          assign_errors: 3,
          encrypt_history: 1,
          encrypt_history: 2,
          clear_history: 1,
          clear_history: 2,
          preserve_fragment: 1,
          preserve_fragment: 2,
          camelize_props: 1,
          camelize_props: 2,
          mark_shared_prop_keys: 2,
          force_inertia_redirect: 1,
          render_inertia: 2,
          render_inertia: 3,
          render_inertia: 4
        ]

      # Import flash helpers
      import NbInertia.Flash, only: [inertia_flash: 2, inertia_flash: 3]

      # Import precognition macros and helpers
      import NbInertia.Plugs.Precognition,
        only: [
          precognition: 3,
          precognition: 4,
          precognition_request?: 1,
          precognition_fields: 1,
          validate_precognition: 2,
          validate_precognition: 3,
          send_precognition_response: 2
        ]

      # Import modal helpers from Redirector
      import NbInertia.Modal.Redirector,
        only: [
          close_modal: 1,
          redirect_modal: 2,
          redirect_modal_success: 3,
          redirect_modal_error: 3
        ]

      # Import Phoenix.Controller for redirect, put_flash, etc.
      import Phoenix.Controller,
        only: [
          redirect: 2,
          put_flash: 3
        ]

      # Import Plug.Conn for put_private, put_status, etc.
      import Plug.Conn,
        only: [
          put_private: 3,
          put_status: 2
        ]

      # Import the props/2 and modal_config/2 helpers from this module
      import NbInertia.Page, only: [props: 2, modal_config: 2, modal: 1, shared: 1]

      # Register module attributes for DSL accumulation
      # These match what Controller uses so the shared macros work
      Module.register_attribute(__MODULE__, :current_props, accumulate: true)
      Module.register_attribute(__MODULE__, :current_page, accumulate: false)
      Module.register_attribute(__MODULE__, :current_page_forms, accumulate: false)
      Module.register_attribute(__MODULE__, :current_form_name, accumulate: false)
      Module.register_attribute(__MODULE__, :current_form_fields, accumulate: true)

      # Page-specific attributes
      Module.register_attribute(__MODULE__, :nb_page_opts, accumulate: false)

      # Modal configuration
      Module.register_attribute(__MODULE__, :nb_page_modal, accumulate: false)
      Module.register_attribute(__MODULE__, :nb_page_modal_base_url, accumulate: false)

      # Shared props modules and inline shared props
      Module.register_attribute(__MODULE__, :nb_page_shared_modules, accumulate: true)
      Module.register_attribute(__MODULE__, :nb_page_shared_inline, accumulate: false)

      # Store the use options
      Module.put_attribute(__MODULE__, :nb_page_opts, unquote(Macro.escape(opts)))

      # Set current_page so the prop macro knows we're in a page context
      # Use a special value that isn't nil so prop accumulation works
      Module.put_attribute(__MODULE__, :current_page, :__page_module__)
      Module.put_attribute(__MODULE__, :current_page_forms, %{})

      # Register before_compile to generate introspection functions
      @before_compile NbInertia.Page
    end
  end

  @doc """
  Declares modal configuration for this page.

  When a page has modal config, it can be rendered as a modal overlay
  via `ModalLink` on the frontend or direct URL access. The modal config
  is used by the PageController to build the `NbInertia.Modal` struct.

  ## Options

    * `:base_url` - The URL of the page "behind" the modal (required for modal rendering).
      Can be a string, a sigil `~p`, or a function that receives `conn.params`.
    * `:size` - Modal size (`:sm`, `:md`, `:lg`, `:xl`, `:full`, or custom string)
    * `:position` - Modal position (`:center`, `:top`, `:bottom`, `:left`, `:right`)
    * `:slideover` - Boolean, render as slideover instead of centered modal
    * `:close_button` - Boolean, show close button (default: true)
    * `:close_explicitly` - Boolean, require explicit close (disable backdrop/ESC)

  ## Examples

      modal base_url: "/users",
            size: :lg,
            position: :center

      # Slideover
      modal slideover: true,
            position: :right,
            size: :lg,
            base_url: "/users"

      # Dynamic base URL via function
      modal base_url: &"/users/\#{&1["id"]}",
            size: :md
  """
  defmacro modal(opts) when is_list(opts) do
    # Separate the base_url from other options since it might be a function
    # capture that needs special handling at compile time.
    {base_url_ast, rest_opts} = Keyword.pop(opts, :base_url)

    # Store the base_url AST as escaped data so it can be re-injected
    # in __before_compile__ without evaluation issues with anonymous functions.
    escaped_base_url_ast =
      if base_url_ast do
        Macro.escape(base_url_ast)
      else
        nil
      end

    quote do
      Module.put_attribute(
        __MODULE__,
        :nb_page_modal,
        unquote(Macro.escape(rest_opts))
      )

      Module.put_attribute(
        __MODULE__,
        :nb_page_modal_base_url,
        unquote(escaped_base_url_ast)
      )
    end
  end

  @doc """
  Registers a shared props module or inline shared props for this page.

  Shared props declared at the page level are additive to router-level shared
  props (from `inertia_shared` in the router). Page-level shared props take
  precedence when keys overlap.

  ## Module-based shared props

      shared MyAppWeb.SharedProps

  The module must implement the `NbInertia.SharedProps.Behaviour`.

  ## Inline shared props

      shared do
        prop :locale, :string
        prop :feature_flags, :map
      end

  Multiple `shared` calls accumulate — all shared modules are applied
  in the order they are declared.
  """
  defmacro shared(module_or_block)

  # Handle shared module: shared MyModule
  defmacro shared(module)
           when is_atom(module) or (is_tuple(module) and elem(module, 0) == :__aliases__) do
    quote do
      Module.put_attribute(__MODULE__, :nb_page_shared_modules, unquote(module))
    end
  end

  # Handle inline shared props: shared do ... end
  defmacro shared(do: block) do
    quote do
      # Save current context
      saved_page = Module.get_attribute(__MODULE__, :current_page)
      Module.put_attribute(__MODULE__, :current_page, :__shared__)
      Module.delete_attribute(__MODULE__, :current_props)

      unquote(block)

      shared_props = Module.get_attribute(__MODULE__, :current_props) |> Enum.reverse()
      Module.put_attribute(__MODULE__, :nb_page_shared_inline, shared_props)

      # Restore context
      Module.delete_attribute(__MODULE__, :current_props)
      Module.put_attribute(__MODULE__, :current_page, saved_page)
    end
  end

  @doc """
  Stores props on the conn for the PageController to pick up.

  Used in `mount/2` when you need to modify the conn (e.g., set headers,
  encrypt history) in addition to providing props.

  ## Examples

      def mount(conn, _params) do
        conn
        |> encrypt_history()
        |> props(%{users: list_users()})
      end
  """
  @spec props(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def props(%Plug.Conn{} = conn, %{} = props_map) do
    Plug.Conn.put_private(conn, :nb_inertia_page_props, props_map)
  end

  @doc """
  Overrides module-level modal configuration per-request.

  Use this in `mount/2` when the modal config depends on runtime values
  (e.g., dynamic base_url from params).

  ## Examples

      def mount(conn, %{"id" => id}) do
        conn
        |> modal_config(base_url: ~p"/users/\#{id}", size: :xl)
        |> props(%{user: Accounts.get_user!(id)})
      end
  """
  @spec modal_config(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def modal_config(%Plug.Conn{} = conn, overrides) when is_list(overrides) do
    Plug.Conn.put_private(conn, :nb_inertia_page_modal_overrides, overrides)
  end

  @doc false
  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :nb_page_opts) || []
    props = Module.get_attribute(env.module, :current_props) |> Enum.reverse()
    forms = Module.get_attribute(env.module, :current_page_forms) || %{}
    modal_opts = Module.get_attribute(env.module, :nb_page_modal)
    modal_base_url = Module.get_attribute(env.module, :nb_page_modal_base_url)
    shared_modules = Module.get_attribute(env.module, :nb_page_shared_modules) |> Enum.reverse()
    shared_inline = Module.get_attribute(env.module, :nb_page_shared_inline)

    # Derive component name
    component =
      case Keyword.get(opts, :component) do
        nil -> NbInertia.Page.Naming.derive_component(env.module)
        explicit -> explicit
      end

    # Check if mount/2 is defined
    has_mount = Module.defines?(env.module, {:mount, 2})

    unless has_mount do
      raise CompileError,
        description: "#{inspect(env.module)} must define mount/2",
        file: env.file,
        line: 0
    end

    # Check if action/3 is defined
    has_action = Module.defines?(env.module, {:action, 3})

    # Check if render/0 is defined
    has_render = Module.defines?(env.module, {:render, 0})

    # Build options map
    options_map = %{
      component: component,
      ssr: Keyword.get(opts, :ssr),
      camelize_props: Keyword.get(opts, :camelize_props),
      encrypt_history: Keyword.get(opts, :encrypt_history, false),
      clear_history: Keyword.get(opts, :clear_history, false),
      preserve_fragment: Keyword.get(opts, :preserve_fragment, false),
      layout: Keyword.get(opts, :layout)
    }

    quote do
      @doc false
      def __inertia_page__, do: true

      @doc false
      def __inertia_props__ do
        unquote(Macro.escape(props))
      end

      @doc false
      def __inertia_forms__ do
        unquote(Macro.escape(forms))
      end

      @doc false
      def __inertia_component__ do
        unquote(component)
      end

      @doc false
      def __inertia_has_render__ do
        unquote(has_render)
      end

      @doc false
      def __inertia_has_action__ do
        unquote(has_action)
      end

      @doc false
      def __inertia_options__ do
        unquote(Macro.escape(options_map))
      end

      @doc false
      def __inertia_modal__ do
        unquote(
          if modal_opts do
            # modal_base_url holds the AST for the base_url value.
            # We inject it directly into the generated function code so that
            # function captures like &"/users/#{&1["id"]}" are properly compiled.
            static_opts = Macro.escape(modal_opts)

            if modal_base_url do
              # modal_base_url IS the AST — inject it directly
              quote do
                [{:base_url, unquote(modal_base_url)} | unquote(static_opts)]
              end
            else
              static_opts
            end
          else
            nil
          end
        )
      end

      @doc false
      def __inertia_shared_modules__ do
        unquote(Macro.escape(shared_modules))
      end

      @doc false
      def __inertia_shared_inline__ do
        unquote(Macro.escape(shared_inline))
      end
    end
  end
end
