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
          render_inertia: 2,
          render_inertia: 3,
          render_inertia: 4
        ]

      # Import flash helpers
      import NbInertia.Flash, only: [inertia_flash: 2, inertia_flash: 3]

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

      # Import the props/2 helper from this module
      import NbInertia.Page, only: [props: 2]

      # Register module attributes for DSL accumulation
      # These match what Controller uses so the shared macros work
      Module.register_attribute(__MODULE__, :current_props, accumulate: true)
      Module.register_attribute(__MODULE__, :current_page, accumulate: false)
      Module.register_attribute(__MODULE__, :current_page_forms, accumulate: false)
      Module.register_attribute(__MODULE__, :current_form_name, accumulate: false)
      Module.register_attribute(__MODULE__, :current_form_fields, accumulate: true)

      # Page-specific attributes
      Module.register_attribute(__MODULE__, :nb_page_opts, accumulate: false)

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

  @doc false
  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :nb_page_opts) || []
    props = Module.get_attribute(env.module, :current_props) |> Enum.reverse()
    forms = Module.get_attribute(env.module, :current_page_forms) || %{}

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
    end
  end
end
