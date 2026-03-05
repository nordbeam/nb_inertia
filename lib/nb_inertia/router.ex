defmodule NbInertia.Router do
  @moduledoc """
  Router macros for dispatching to `NbInertia.Page` modules.

  Import this module in your Phoenix router to use `inertia/2`, `inertia/3`,
  `inertia_resource/2`, `inertia_resource/3`, and `inertia_shared/1` macros.

  ## Usage

      defmodule MyAppWeb.Router do
        use Phoenix.Router
        import NbInertia.Router

        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug NbInertia.Plug
        end

        scope "/", MyAppWeb do
          pipe_through :browser

          inertia "/", HomePage.Index
          inertia "/about", AboutPage.Index

          inertia_resource "/users", UsersPage
          inertia_resource "/posts", PostsPage, only: [:index, :show]
        end
      end

  ## How It Works

  The macros generate standard Phoenix routes that dispatch to
  `NbInertia.PageController`. The Page module is stored in
  `conn.private[:nb_inertia_page_module]` so the controller knows which
  module to call.

  GET requests invoke the Page module's `mount/2` callback.
  POST/PATCH/PUT/DELETE requests invoke `action/3` with a verb atom.
  """

  @doc """
  Defines a single Inertia page route.

  ## Examples

      # GET route (default)
      inertia "/", HomePage.Index

      # With custom HTTP method and action verb
      inertia "/users/:id/archive", UsersPage.Show, action: :archive, method: :post

      # GET route with a custom action (handled by action/3 instead of mount/2)
      inertia "/users/export", UsersPage.Index, action: :export, method: :get

  ## Options

    * `:method` - HTTP method (default: `:get`)
    * `:action` - verb atom passed to `action/3` for mutation routes
    * `:as` - route name override (default: derived from path)

  """
  defmacro inertia(path, page_module, opts \\ []) do
    page_module = expand_page_alias(page_module, __CALLER__)
    method = Keyword.get(opts, :method, :get)
    action_verb = Keyword.get(opts, :action)
    as_opt = Keyword.get(opts, :as)

    # Determine controller action and private metadata
    {controller_action, private} =
      if method == :get and is_nil(action_verb) do
        # Pure GET — dispatch to show (mount/2)
        {:show, %{nb_inertia_page_module: page_module}}
      else
        # Mutation or custom action — dispatch to action (action/3)
        verb = action_verb || method_to_default_verb(method)
        {:action, %{nb_inertia_page_module: page_module, nb_inertia_action_verb: verb}}
      end

    private = Macro.escape(private)

    route_opts =
      if as_opt do
        quote do: [private: unquote(private), alias: false, as: unquote(as_opt)]
      else
        quote do: [private: unquote(private), alias: false]
      end

    quote do
      unquote(method)(
        unquote(path),
        NbInertia.PageController,
        unquote(controller_action),
        unquote(route_opts)
      )
    end
  end

  @doc """
  Defines RESTful Inertia page routes for a resource.

  ## Examples

      # Full resource
      inertia_resource "/users", UsersPage

      # Filtered actions
      inertia_resource "/users", UsersPage, only: [:index, :show]
      inertia_resource "/posts", PostsPage, except: [:delete]

      # Singleton resource (no :id param, no :index)
      inertia_resource "/account", AccountPage, singleton: true

      # Custom param name
      inertia_resource "/users", UsersPage, param: "slug"

      # Nested resources
      inertia_resource "/users", UsersPage do
        inertia_resource "/posts", UsersPage.PostsPage
      end

  ## Expansion

  `inertia_resource "/users", UsersPage` expands to:

  | HTTP   | Path             | Module          | Controller Action | Verb    |
  |--------|------------------|-----------------|-------------------|---------|
  | GET    | /users           | UsersPage.Index | :show             | —       |
  | GET    | /users/new       | UsersPage.New   | :show             | —       |
  | POST   | /users           | UsersPage.New   | :action           | :create |
  | GET    | /users/:id       | UsersPage.Show  | :show             | —       |
  | GET    | /users/:id/edit  | UsersPage.Edit  | :show             | —       |
  | PATCH  | /users/:id       | UsersPage.Edit  | :action           | :update |
  | PUT    | /users/:id       | UsersPage.Edit  | :action           | :update |
  | DELETE | /users/:id       | UsersPage.Show  | :action           | :delete |

  ## Singleton Expansion

  `inertia_resource "/account", AccountPage, singleton: true` expands to:

  | HTTP   | Path           | Module           | Controller Action | Verb    |
  |--------|----------------|------------------|-------------------|---------|
  | GET    | /account       | AccountPage.Show | :show             | —       |
  | GET    | /account/new   | AccountPage.New  | :show             | —       |
  | POST   | /account       | AccountPage.New  | :action           | :create |
  | GET    | /account/edit  | AccountPage.Edit | :show             | —       |
  | PATCH  | /account       | AccountPage.Edit | :action           | :update |
  | PUT    | /account       | AccountPage.Edit | :action           | :update |
  | DELETE | /account       | AccountPage.Show | :action           | :delete |

  ## Options

    * `:only` - list of actions to include (e.g., `[:index, :show]`)
    * `:except` - list of actions to exclude (e.g., `[:delete]`)
    * `:singleton` - if `true`, generates singleton routes (no `:id`, no `:index`)
    * `:param` - custom param name (default: `"id"`)
    * `:as` - route name prefix override

  """
  defmacro inertia_resource(path, page_module, opts, do: nested_context) do
    do_inertia_resource(path, page_module, opts, nested_context, __CALLER__)
  end

  @doc false
  defmacro inertia_resource(path, page_module, do: nested_context) do
    do_inertia_resource(path, page_module, [], nested_context, __CALLER__)
  end

  @doc false
  defmacro inertia_resource(path, page_module, opts) do
    do_inertia_resource(path, page_module, opts, nil, __CALLER__)
  end

  @doc false
  defmacro inertia_resource(path, page_module) do
    do_inertia_resource(path, page_module, [], nil, __CALLER__)
  end

  @doc """
  Registers a shared props module for all Inertia routes in the current pipeline.

  The shared module must implement the `NbInertia.SharedProps.Behaviour` and will
  be called by `NbInertia.PageController` to merge shared props into every page
  rendered through this pipeline.

  ## Example

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug NbInertia.Plug
      end

      scope "/admin", MyAppWeb.Admin do
        pipe_through [:browser]

        # All routes in this scope get shared admin props
        inertia_shared MyAppWeb.InertiaShared.Admin
        inertia_resource "/users", UsersPage
        inertia_resource "/settings", SettingsPage
      end

  Multiple `inertia_shared` calls accumulate — all shared modules are applied
  in the order they are declared.

  ## Implementation

  Expands to a `plug` call that appends the shared module to
  `conn.private[:nb_inertia_shared_modules]`. `NbInertia.PageController` reads
  this list and calls each module's `build_props/2` before rendering.
  """
  defmacro inertia_shared(shared_module) do
    shared_module = Macro.expand(shared_module, __CALLER__)

    quote do
      plug(NbInertia.Plugs.SharedProps, module: unquote(shared_module))
    end
  end

  # ── Private helpers ──────────────────────────────────

  defp do_inertia_resource(path, page_module, opts, nested_context, caller_env) do
    page_module = expand_page_alias(page_module, caller_env)
    singleton = Keyword.get(opts, :singleton, false)
    param = Keyword.get(opts, :param, "id")
    as_prefix = Keyword.get(opts, :as)
    actions = extract_actions(opts, singleton)

    # Derive route name prefix from the last path segment
    derived_as =
      if as_prefix do
        as_prefix
      else
        path
        |> String.split("/", trim: true)
        |> List.last()
        |> to_string()
        |> String.replace("-", "_")
        |> String.to_atom()
      end

    routes = build_resource_routes(path, page_module, actions, singleton, param, derived_as)

    nested =
      if nested_context do
        # For nested resources, create a scope at the member path
        member_path =
          if singleton do
            path
          else
            name = derive_param_prefix(path)
            "#{path}/:#{name}_#{param}"
          end

        quote do
          scope unquote(member_path) do
            unquote(nested_context)
          end
        end
      end

    quote do
      unquote_splicing(routes)
      unquote(nested)
    end
  end

  # Expand the page module alias at compile time, respecting the caller's aliases.
  # This handles both fully-qualified modules and aliases defined in the caller scope.
  defp expand_page_alias({:__aliases__, _, _} = alias_ast, caller_env) do
    Macro.expand(alias_ast, %{caller_env | function: {:init, 1}})
  end

  defp expand_page_alias(module, _caller_env) when is_atom(module), do: module

  @all_actions [:index, :new, :create, :show, :edit, :update, :delete]
  @singleton_actions [:new, :create, :show, :edit, :update, :delete]

  defp extract_actions(opts, singleton) do
    default = if singleton, do: @singleton_actions, else: @all_actions
    only = Keyword.get(opts, :only)
    except = Keyword.get(opts, :except)

    cond do
      only ->
        validate_actions!(only, default)
        default -- (default -- only)

      except ->
        validate_actions!(except, default)
        default -- except

      true ->
        default
    end
  end

  defp validate_actions!(actions, supported) do
    invalid = actions -- supported

    unless invalid == [] do
      raise ArgumentError, """
      invalid action(s) passed to inertia_resource.

      Supported actions: #{inspect(supported)}
      Got: #{inspect(invalid)}
      """
    end
  end

  defp method_to_default_verb(:post), do: :create
  defp method_to_default_verb(:patch), do: :update
  defp method_to_default_verb(:put), do: :update
  defp method_to_default_verb(:delete), do: :delete
  defp method_to_default_verb(method), do: method

  # Build a list of quoted route expressions for a resource
  defp build_resource_routes(path, page_module, actions, singleton, param, as_prefix) do
    name = derive_param_prefix(path)

    Enum.flat_map(actions, fn action ->
      build_action_routes(action, path, page_module, singleton, param, name, as_prefix)
    end)
  end

  defp build_action_routes(:index, path, page_module, _singleton, _param, _name, as_prefix) do
    mod = Module.concat(page_module, Index)

    [
      quote do
        get(unquote(path), NbInertia.PageController, :show,
          alias: false,
          as: unquote(:"#{as_prefix}_index"),
          private: %{nb_inertia_page_module: unquote(mod)}
        )
      end
    ]
  end

  defp build_action_routes(:new, path, page_module, _singleton, _param, _name, as_prefix) do
    new_path = "#{path}/new"
    mod = Module.concat(page_module, New)

    [
      quote do
        get(unquote(new_path), NbInertia.PageController, :show,
          alias: false,
          as: unquote(:"#{as_prefix}_new"),
          private: %{nb_inertia_page_module: unquote(mod)}
        )
      end
    ]
  end

  defp build_action_routes(:create, path, page_module, _singleton, _param, _name, as_prefix) do
    mod = Module.concat(page_module, New)

    [
      quote do
        post(unquote(path), NbInertia.PageController, :action,
          alias: false,
          as: unquote(:"#{as_prefix}_create"),
          private: %{
            nb_inertia_page_module: unquote(mod),
            nb_inertia_action_verb: :create
          }
        )
      end
    ]
  end

  defp build_action_routes(:show, path, page_module, singleton, param, name, as_prefix) do
    show_path = if singleton, do: path, else: "#{path}/:#{name}_#{param}"
    mod = Module.concat(page_module, Show)

    [
      quote do
        get(unquote(show_path), NbInertia.PageController, :show,
          alias: false,
          as: unquote(:"#{as_prefix}_show"),
          private: %{nb_inertia_page_module: unquote(mod)}
        )
      end
    ]
  end

  defp build_action_routes(:edit, path, page_module, singleton, param, name, as_prefix) do
    edit_path = if singleton, do: "#{path}/edit", else: "#{path}/:#{name}_#{param}/edit"
    mod = Module.concat(page_module, Edit)

    [
      quote do
        get(unquote(edit_path), NbInertia.PageController, :show,
          alias: false,
          as: unquote(:"#{as_prefix}_edit"),
          private: %{nb_inertia_page_module: unquote(mod)}
        )
      end
    ]
  end

  defp build_action_routes(:update, path, page_module, singleton, param, name, as_prefix) do
    update_path = if singleton, do: path, else: "#{path}/:#{name}_#{param}"
    mod = Module.concat(page_module, Edit)

    [
      quote do
        patch(unquote(update_path), NbInertia.PageController, :action,
          alias: false,
          as: unquote(:"#{as_prefix}_update"),
          private: %{
            nb_inertia_page_module: unquote(mod),
            nb_inertia_action_verb: :update
          }
        )
      end,
      quote do
        put(unquote(update_path), NbInertia.PageController, :action,
          alias: false,
          as: nil,
          private: %{
            nb_inertia_page_module: unquote(mod),
            nb_inertia_action_verb: :update
          }
        )
      end
    ]
  end

  defp build_action_routes(:delete, path, page_module, singleton, param, name, as_prefix) do
    delete_path = if singleton, do: path, else: "#{path}/:#{name}_#{param}"
    mod = Module.concat(page_module, Show)

    [
      quote do
        delete(unquote(delete_path), NbInertia.PageController, :action,
          alias: false,
          as: unquote(:"#{as_prefix}_delete"),
          private: %{
            nb_inertia_page_module: unquote(mod),
            nb_inertia_action_verb: :delete
          }
        )
      end
    ]
  end

  # Derive the param prefix from the path (e.g., "/users" -> "user", "/blog_posts" -> "blog_post")
  defp derive_param_prefix(path) do
    path
    |> String.split("/", trim: true)
    |> List.last()
    |> to_string()
    |> Phoenix.Naming.unsuffix("s")
    |> String.replace("-", "_")
  end
end
