defmodule NbInertia do
  @moduledoc """
  Advanced Inertia.js integration for Phoenix applications.

  NbInertia provides a declarative DSL for defining Inertia pages with type-safe props,
  shared props, and optional NbSerializer integration for automatic JSON serialization.

  ## Features

  - **Declarative Page DSL**: Define pages and validate literal `render_inertia_page/4` calls in dev/test
  - **Component Name Inference**: Automatic conversion from `:users_index` to `"Users/Index"`
  - **Shared Props**: Define props shared across all pages inline or via `include_shared_props/2`
  - **Type Safety**: Default-backed and assign-backed props are materialized at runtime
  - **NbSerializer Integration**: Optional automatic serialization with NbSerializer
  - **Flexible Rendering**: Support for both all-in-one and pipe-friendly patterns

  ## Installation

  Add `nb_inertia` to your list of dependencies in `mix.exs`:

      def deps do
        [
          {:nb_inertia, github: "nordbeam/nb_inertia"},
          {:nb_serializer, github: "nordbeam/nb_serializer", optional: true},
          {:nb_ts, github: "nordbeam/nb_ts", optional: true}
        ]
      end

  ## Basic Usage

  In your controller, use `NbInertia.Controller`:

      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, list_of(:map)
          prop :total_count, :integer
        end

        def index(conn, _params) do
          users = MyApp.Accounts.list_users()

          render_inertia_page(conn, :users_index,
            users: users,
            total_count: length(users)
          )
        end
      end

  ## With NbSerializer

  If you have `nb_serializer` installed, you can use automatic serialization:

      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        use NbInertia.Controller

        inertia_page :users_index do
          prop :users, list_of(ref(MyApp.UserSerializer))
          prop :total_count, :integer
        end

        def index(conn, _params) do
          users = MyApp.Accounts.list_users()

          render_inertia_page(conn, :users_index,
            users: serialize(MyApp.UserSerializer, users),
            total_count: length(users)
          )
        end
      end

  ## Shared Props

  Define props shared across all pages:

      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        use NbInertia.Controller

        inertia_shared do
          prop :current_user, from: :assigns
          prop :flash, from: :assigns
        end

        inertia_page :dashboard do
          prop :stats, :map
        end
      end

  Register reusable shared prop modules with `include_shared_props/2`:

      defmodule MyAppWeb.UserController do
        use MyAppWeb, :controller
        use NbInertia.Controller

        include_shared_props(MyAppWeb.InertiaShared.Auth)

        inertia_page :dashboard do
          prop :stats, :map
        end
      end

  ## Compile-Time Validation

  Prefer `render_inertia_page/4` for explicit all-in-one page renders. In dev and
  test, literal props passed there are validated for declared pages, which catches
  missing required props, undeclared props, and shared/page prop name collisions early.

  `render_inertia/2-4` remains the overloaded compatibility entry point for pipe-friendly
  page renders and explicit component renders. Dynamic prop variables and undeclared
  page refs skip compile-time validation and fall back to runtime behavior.

  ## Testing

  NbInertia provides test helpers to make testing Inertia pages easy and intuitive.
  Import `NbInertia.TestHelpers` in your test support modules:

      # In test/support/conn_case.ex
      defmodule MyAppWeb.ConnCase do
        use ExUnit.CaseTemplate

        using do
          quote do
            import Plug.Conn
            import Phoenix.ConnTest
            import NbInertia.TestHelpers

            @endpoint MyAppWeb.Endpoint
          end
        end
      end

  Then use the helpers in your controller tests:

      test "renders posts index", %{conn: conn} do
        post = insert(:post, title: "Hello World")
        conn = inertia_get(conn, ~p"/posts")

        assert_inertia_page(conn, "Posts/Index")
        assert_inertia_props(conn, [:posts, :total_count])
        assert_inertia_prop(conn, :total_count, 1)
      end

  Available test helpers:

  - `inertia_get/2`, `inertia_post/3`, etc. - Make Inertia requests with proper headers
  - `assert_inertia_page/2` - Assert the rendered component name
  - `assert_inertia_props/2` - Assert specific props are present
  - `assert_inertia_prop/3` - Assert a prop has a specific value
  - `refute_inertia_prop/2` - Assert a prop is not present

  See `NbInertia.TestHelpers` for full documentation.

  ## Configuration

  Configure NbInertia using the `:nb_inertia` namespace. All configuration is
  automatically forwarded to the underlying `:inertia` library on application startup.

      # config/config.exs
      config :nb_inertia,
        endpoint: MyAppWeb.Endpoint,           # Required for SSR and versioning
        camelize_props: true,                  # Default: true
        snake_case_params: true,               # Default: true
        history: [],                           # Default: []
        static_paths: ["/css", "/js"],         # Default: []
        default_version: "1",                  # Default: "1"
        ssr: false,                            # Default: false
        raise_on_ssr_failure: true             # Default: true

  **Note:** You should configure `:nb_inertia`, not `:inertia` directly.
  NbInertia handles forwarding the configuration to the underlying Inertia library

  ## Automatic Param Conversion

  When `camelize_props: true` (default), NbInertia automatically camelizes props sent to the frontend.
  To handle the reverse direction (frontend → backend), enable `snake_case_params: true` (default) and
  add `NbInertia.ParamsConverter` to your router pipeline:

      pipeline :inertia_app do
        plug :accepts, ["html"]
        plug :fetch_session
        plug NbInertia.ParamsConverter  # Converts camelCase params to snake_case
        plug NbInertia.Plug
      end

  This ensures seamless bidirectional conversion:
  - Backend → Frontend: `primary_product_id` becomes `primaryProductId`
  - Frontend → Backend: `primaryProductId` becomes `primary_product_id`
  """

  # Delegate common controller operations to CoreController
  defdelegate assign_prop(conn, key, value), to: NbInertia.CoreController
  defdelegate inertia_optional(fun), to: NbInertia.CoreController
  defdelegate inertia_merge(value), to: NbInertia.CoreController
  defdelegate inertia_deep_merge(value), to: NbInertia.CoreController
  defdelegate inertia_prepend(value), to: NbInertia.CoreController
  defdelegate inertia_match_merge(value, id_field), to: NbInertia.CoreController
  defdelegate inertia_scroll(value), to: NbInertia.CoreController
  defdelegate inertia_scroll(value, opts), to: NbInertia.CoreController
  defdelegate inertia_defer(fun), to: NbInertia.CoreController
  defdelegate inertia_defer(fun, group), to: NbInertia.CoreController
  defdelegate inertia_always(value), to: NbInertia.CoreController
  defdelegate preserve_case(key), to: NbInertia.CoreController
  defdelegate encrypt_history(conn), to: NbInertia.CoreController
  defdelegate encrypt_history(conn, true_or_false), to: NbInertia.CoreController
  defdelegate clear_history(conn), to: NbInertia.CoreController
  defdelegate clear_history(conn, true_or_false), to: NbInertia.CoreController
  defdelegate preserve_fragment(conn), to: NbInertia.CoreController
  defdelegate preserve_fragment(conn, true_or_false), to: NbInertia.CoreController
  defdelegate mark_shared_prop_keys(conn, keys), to: NbInertia.CoreController

  @doc """
  Returns the version of NbInertia.
  """
  def version, do: unquote(Mix.Project.config()[:version])
end
