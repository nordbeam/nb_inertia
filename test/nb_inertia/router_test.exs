defmodule NbInertia.RouterTest do
  use ExUnit.Case, async: true

  # ── Stub Modules ──────────────────────────────────────

  # These stubs exist so the test routers compile.
  # They don't need to be real Page modules for route generation tests.

  # ── Test Router Modules ──────────────────────────────

  defmodule BasicRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/" do
      inertia("/", NbInertia.RouterTest.Pages.HomePage.Index)
      inertia("/about", NbInertia.RouterTest.Pages.AboutPage.Index)
    end
  end

  defmodule ResourceRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/" do
      inertia_resource("/users", NbInertia.RouterTest.Pages.UsersPage)
    end
  end

  defmodule FilteredResourceRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/" do
      inertia_resource("/users", NbInertia.RouterTest.Pages.UsersPage, only: [:index, :show])
      inertia_resource("/posts", NbInertia.RouterTest.Pages.PostsPage, except: [:delete])
    end
  end

  defmodule SingletonRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/" do
      inertia_resource("/account", NbInertia.RouterTest.Pages.AccountPage, singleton: true)
    end
  end

  defmodule CustomParamRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/" do
      inertia_resource("/users", NbInertia.RouterTest.Pages.UsersPage, param: "slug")
    end
  end

  defmodule CustomMethodRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/" do
      inertia("/users/:id/archive", NbInertia.RouterTest.Pages.UsersPage.Show,
        action: :archive,
        method: :post
      )

      inertia("/users/export", NbInertia.RouterTest.Pages.UsersPage.Index, action: :export)
    end
  end

  defmodule NestedRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/" do
      inertia_resource "/users", NbInertia.RouterTest.Pages.UsersPage do
        inertia_resource("/posts", NbInertia.RouterTest.Pages.UsersPage.PostsPage,
          only: [:index, :new, :create]
        )
      end
    end
  end

  defmodule ScopedRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/admin" do
      inertia("/dashboard", NbInertia.RouterTest.Pages.DashboardPage.Index)
      inertia_resource("/users", NbInertia.RouterTest.Pages.UsersPage, only: [:index, :show])
    end
  end

  defmodule CustomAsRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/" do
      inertia_resource("/users", NbInertia.RouterTest.Pages.UsersPage, as: :people)
      inertia("/home", NbInertia.RouterTest.Pages.HomePage.Index, as: :landing)
    end
  end

  defmodule SingletonFilteredRouter do
    use Phoenix.Router
    import NbInertia.Router

    scope "/" do
      inertia_resource("/account", NbInertia.RouterTest.Pages.AccountPage,
        singleton: true,
        only: [:show, :edit, :update]
      )
    end
  end

  # ── Helper Functions ──────────────────────────────────

  defp find_route(routes, verb, path) do
    Enum.find(routes, fn route ->
      route.verb == verb and route.path == path
    end)
  end

  # Match route and return the private metadata set on the conn
  # This is a more robust approach: we look at the compiled match function
  defp match_private(router, method, path) do
    split_path = for segment <- String.split(path, "/"), segment != "", do: segment

    case router.__match_route__(split_path, String.upcase(to_string(method)), "") do
      {metadata, prepare, _pipeline, _dispatch} ->
        # The prepare function merges private data into conn
        # Build a minimal conn and run through prepare
        conn =
          Plug.Test.conn(method, path)
          |> Plug.Conn.put_private(:phoenix_router, router)
          |> Map.put(:secret_key_base, String.duplicate("a", 64))

        prepared_conn = prepare.(conn, metadata)
        prepared_conn.private

      :error ->
        nil
    end
  end

  # ── Tests: inertia/2 and inertia/3 ──────────────────

  describe "inertia/2 (single route)" do
    test "generates GET route to PageController :show" do
      routes = BasicRouter.__routes__()
      route = find_route(routes, :get, "/")

      assert route != nil
      assert route.plug == NbInertia.PageController
      assert route.plug_opts == :show
    end

    test "sets nb_inertia_page_module in private" do
      private = match_private(BasicRouter, :get, "/")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.HomePage.Index
    end

    test "generates multiple GET routes" do
      routes = BasicRouter.__routes__()

      about_route = find_route(routes, :get, "/about")
      assert about_route != nil
      assert about_route.plug == NbInertia.PageController
      assert about_route.plug_opts == :show

      private = match_private(BasicRouter, :get, "/about")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.AboutPage.Index
    end
  end

  describe "inertia/3 (with options)" do
    test "generates POST route with custom action verb" do
      routes = CustomMethodRouter.__routes__()
      route = find_route(routes, :post, "/users/:id/archive")

      assert route != nil
      assert route.plug == NbInertia.PageController
      assert route.plug_opts == :action

      private = match_private(CustomMethodRouter, :post, "/users/42/archive")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.Show
      assert private[:nb_inertia_action_verb] == :archive
    end

    test "generates GET route with action verb (dispatches to action/3)" do
      routes = CustomMethodRouter.__routes__()
      route = find_route(routes, :get, "/users/export")

      assert route != nil
      assert route.plug == NbInertia.PageController
      assert route.plug_opts == :action

      private = match_private(CustomMethodRouter, :get, "/users/export")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.Index
      assert private[:nb_inertia_action_verb] == :export
    end

    test "custom :as option sets route name" do
      routes = CustomAsRouter.__routes__()
      route = find_route(routes, :get, "/home")

      assert route != nil
      assert route.helper == "landing"
    end
  end

  # ── Tests: inertia_resource/2 and /3 ──────────────────

  describe "inertia_resource/2 (full resource)" do
    setup do
      %{routes: ResourceRouter.__routes__()}
    end

    test "generates GET /users (index)", %{routes: routes} do
      route = find_route(routes, :get, "/users")
      assert route != nil
      assert route.plug == NbInertia.PageController
      assert route.plug_opts == :show

      private = match_private(ResourceRouter, :get, "/users")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.Index
    end

    test "generates GET /users/new", %{routes: routes} do
      route = find_route(routes, :get, "/users/new")
      assert route != nil
      assert route.plug_opts == :show

      private = match_private(ResourceRouter, :get, "/users/new")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.New
    end

    test "generates POST /users (create)", %{routes: routes} do
      route = find_route(routes, :post, "/users")
      assert route != nil
      assert route.plug_opts == :action

      private = match_private(ResourceRouter, :post, "/users")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.New
      assert private[:nb_inertia_action_verb] == :create
    end

    test "generates GET /users/:user_id (show)", %{routes: routes} do
      route = find_route(routes, :get, "/users/:user_id")
      assert route != nil
      assert route.plug_opts == :show

      private = match_private(ResourceRouter, :get, "/users/42")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.Show
    end

    test "generates GET /users/:user_id/edit", %{routes: routes} do
      route = find_route(routes, :get, "/users/:user_id/edit")
      assert route != nil
      assert route.plug_opts == :show

      private = match_private(ResourceRouter, :get, "/users/42/edit")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.Edit
    end

    test "generates PATCH /users/:user_id (update)", %{routes: routes} do
      route = find_route(routes, :patch, "/users/:user_id")
      assert route != nil
      assert route.plug_opts == :action

      private = match_private(ResourceRouter, :patch, "/users/42")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.Edit
      assert private[:nb_inertia_action_verb] == :update
    end

    test "generates PUT /users/:user_id (update duplicate)", %{routes: routes} do
      route = find_route(routes, :put, "/users/:user_id")
      assert route != nil
      assert route.plug_opts == :action

      private = match_private(ResourceRouter, :put, "/users/42")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.Edit
      assert private[:nb_inertia_action_verb] == :update
    end

    test "generates DELETE /users/:user_id", %{routes: routes} do
      route = find_route(routes, :delete, "/users/:user_id")
      assert route != nil
      assert route.plug_opts == :action

      private = match_private(ResourceRouter, :delete, "/users/42")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.UsersPage.Show
      assert private[:nb_inertia_action_verb] == :delete
    end

    test "generates correct number of routes (8 total)", %{routes: routes} do
      # index, new, show, edit = 4 GETs
      # create = 1 POST
      # update = 1 PATCH + 1 PUT
      # delete = 1 DELETE
      assert length(routes) == 8
    end
  end

  describe "inertia_resource with :only" do
    test "generates only specified actions" do
      routes = FilteredResourceRouter.__routes__()
      user_routes = Enum.filter(routes, &String.starts_with?(&1.path, "/users"))

      # :only [:index, :show] -> GET /users, GET /users/:user_id
      assert length(user_routes) == 2

      assert find_route(user_routes, :get, "/users") != nil
      assert find_route(user_routes, :get, "/users/:user_id") != nil
      assert find_route(user_routes, :post, "/users") == nil
      assert find_route(user_routes, :delete, "/users/:user_id") == nil
    end
  end

  describe "inertia_resource with :except" do
    test "excludes specified actions" do
      routes = FilteredResourceRouter.__routes__()
      post_routes = Enum.filter(routes, &String.starts_with?(&1.path, "/posts"))

      # All actions except :delete
      # index, new, create, show, edit, update(patch), update(put) = 7
      assert length(post_routes) == 7
      assert find_route(post_routes, :delete, "/posts/:post_id") == nil
    end
  end

  describe "inertia_resource with singleton: true" do
    setup do
      %{routes: SingletonRouter.__routes__()}
    end

    test "does not generate index route", %{routes: routes} do
      # Singletons have no :index. There should be one GET /account (the :show).
      get_account = Enum.filter(routes, &(&1.path == "/account" and &1.verb == :get))
      assert length(get_account) == 1
      route = hd(get_account)
      assert route.plug_opts == :show

      private = match_private(SingletonRouter, :get, "/account")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.AccountPage.Show
    end

    test "generates routes without :id param", %{routes: routes} do
      Enum.each(routes, fn route ->
        refute String.contains?(route.path, ":account_id"),
               "Route #{route.path} should not contain :account_id"

        refute String.contains?(route.path, ":id"),
               "Route #{route.path} should not contain :id"
      end)
    end

    test "generates GET /account (show)", %{routes: routes} do
      route = find_route(routes, :get, "/account")
      assert route != nil

      private = match_private(SingletonRouter, :get, "/account")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.AccountPage.Show
    end

    test "generates GET /account/new", %{routes: routes} do
      route = find_route(routes, :get, "/account/new")
      assert route != nil

      private = match_private(SingletonRouter, :get, "/account/new")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.AccountPage.New
    end

    test "generates GET /account/edit", %{routes: routes} do
      route = find_route(routes, :get, "/account/edit")
      assert route != nil

      private = match_private(SingletonRouter, :get, "/account/edit")
      assert private[:nb_inertia_page_module] == NbInertia.RouterTest.Pages.AccountPage.Edit
    end

    test "generates POST /account (create)", %{routes: routes} do
      route = find_route(routes, :post, "/account")
      assert route != nil

      private = match_private(SingletonRouter, :post, "/account")
      assert private[:nb_inertia_action_verb] == :create
    end

    test "generates PATCH /account (update)", %{routes: routes} do
      route = find_route(routes, :patch, "/account")
      assert route != nil

      private = match_private(SingletonRouter, :patch, "/account")
      assert private[:nb_inertia_action_verb] == :update
    end

    test "generates DELETE /account", %{routes: routes} do
      route = find_route(routes, :delete, "/account")
      assert route != nil

      private = match_private(SingletonRouter, :delete, "/account")
      assert private[:nb_inertia_action_verb] == :delete
    end

    test "total routes: 7 (show, new, create, edit, update_patch, update_put, delete)", %{
      routes: routes
    } do
      assert length(routes) == 7
    end
  end

  describe "inertia_resource with singleton: true and only:" do
    test "filters singleton actions correctly" do
      routes = SingletonFilteredRouter.__routes__()

      # only: [:show, :edit, :update] ->
      # GET /account (show), GET /account/edit, PATCH /account, PUT /account
      assert length(routes) == 4

      assert find_route(routes, :get, "/account") != nil
      assert find_route(routes, :get, "/account/edit") != nil
      assert find_route(routes, :patch, "/account") != nil
      assert find_route(routes, :put, "/account") != nil

      # These should NOT exist
      assert find_route(routes, :get, "/account/new") == nil
      assert find_route(routes, :post, "/account") == nil
      assert find_route(routes, :delete, "/account") == nil
    end
  end

  describe "inertia_resource with param:" do
    test "uses custom param name in paths" do
      routes = CustomParamRouter.__routes__()

      assert find_route(routes, :get, "/users/:user_slug") != nil
      assert find_route(routes, :get, "/users/:user_slug/edit") != nil
      assert find_route(routes, :patch, "/users/:user_slug") != nil
      assert find_route(routes, :delete, "/users/:user_slug") != nil

      # Should NOT have default :user_id
      refute Enum.any?(routes, &String.contains?(&1.path, ":user_id"))
    end
  end

  describe "nested resources" do
    setup do
      %{routes: NestedRouter.__routes__()}
    end

    test "generates parent resource routes", %{routes: routes} do
      assert find_route(routes, :get, "/users") != nil
      assert find_route(routes, :get, "/users/:user_id") != nil
    end

    test "generates nested resource routes under parent member path", %{routes: routes} do
      # Nested: only [:index, :new, :create]
      assert find_route(routes, :get, "/users/:user_id/posts") != nil
      assert find_route(routes, :get, "/users/:user_id/posts/new") != nil
      assert find_route(routes, :post, "/users/:user_id/posts") != nil
    end

    test "nested routes dispatch to correct modules", %{routes: _routes} do
      # Check via private metadata
      private = match_private(NestedRouter, :get, "/users/1/posts")

      assert private[:nb_inertia_page_module] ==
               NbInertia.RouterTest.Pages.UsersPage.PostsPage.Index

      private = match_private(NestedRouter, :get, "/users/1/posts/new")

      assert private[:nb_inertia_page_module] ==
               NbInertia.RouterTest.Pages.UsersPage.PostsPage.New
    end

    test "nested routes excluded by :only are not generated", %{routes: routes} do
      # :show should not exist for nested
      assert find_route(routes, :get, "/users/:user_id/posts/:post_id") == nil
      assert find_route(routes, :delete, "/users/:user_id/posts/:post_id") == nil
    end
  end

  describe "scoped routes" do
    test "scope path prefix is applied" do
      routes = ScopedRouter.__routes__()

      dashboard = find_route(routes, :get, "/admin/dashboard")
      assert dashboard != nil

      private = match_private(ScopedRouter, :get, "/admin/dashboard")

      assert private[:nb_inertia_page_module] ==
               NbInertia.RouterTest.Pages.DashboardPage.Index

      users_index = find_route(routes, :get, "/admin/users")
      assert users_index != nil

      private = match_private(ScopedRouter, :get, "/admin/users")

      assert private[:nb_inertia_page_module] ==
               NbInertia.RouterTest.Pages.UsersPage.Index
    end
  end

  describe "route naming" do
    test "resource routes have expected helper names" do
      routes = ResourceRouter.__routes__()

      index_route = find_route(routes, :get, "/users")
      assert index_route.helper == "users_index"

      new_route = find_route(routes, :get, "/users/new")
      assert new_route.helper == "users_new"

      create_route = find_route(routes, :post, "/users")
      assert create_route.helper == "users_create"

      show_route = find_route(routes, :get, "/users/:user_id")
      assert show_route.helper == "users_show"

      edit_route = find_route(routes, :get, "/users/:user_id/edit")
      assert edit_route.helper == "users_edit"

      update_route = find_route(routes, :patch, "/users/:user_id")
      assert update_route.helper == "users_update"

      # PUT has as: nil (no helper name)
      put_route = find_route(routes, :put, "/users/:user_id")
      assert put_route.helper == nil

      delete_route = find_route(routes, :delete, "/users/:user_id")
      assert delete_route.helper == "users_delete"
    end

    test "custom :as option overrides route names" do
      routes = CustomAsRouter.__routes__()

      people_routes =
        Enum.filter(routes, fn r ->
          r.helper != nil and String.starts_with?(r.helper, "people")
        end)

      helpers = Enum.map(people_routes, & &1.helper)
      assert "people_index" in helpers
      assert "people_show" in helpers
    end
  end

  describe "private metadata" do
    test "all routes set nb_inertia_page_module" do
      routes = ResourceRouter.__routes__()

      Enum.each(routes, fn route ->
        # Construct a real path for parameterized routes
        test_path = route.path |> String.replace(":user_id", "42")
        method = route.verb

        private = match_private(ResourceRouter, method, test_path)

        assert private[:nb_inertia_page_module] != nil,
               "Route #{route.verb} #{route.path} missing :nb_inertia_page_module"
      end)
    end

    test "mutation routes set nb_inertia_action_verb" do
      routes = ResourceRouter.__routes__()

      mutation_routes =
        Enum.filter(routes, fn route ->
          route.verb in [:post, :patch, :put, :delete]
        end)

      Enum.each(mutation_routes, fn route ->
        test_path = route.path |> String.replace(":user_id", "42")
        private = match_private(ResourceRouter, route.verb, test_path)

        assert private[:nb_inertia_action_verb] != nil,
               "Route #{route.verb} #{route.path} missing :nb_inertia_action_verb"
      end)
    end

    test "GET routes do NOT set nb_inertia_action_verb (for standard resources)" do
      routes = ResourceRouter.__routes__()
      get_routes = Enum.filter(routes, &(&1.verb == :get))

      Enum.each(get_routes, fn route ->
        test_path = route.path |> String.replace(":user_id", "42")
        private = match_private(ResourceRouter, :get, test_path)

        refute Map.has_key?(private, :nb_inertia_action_verb),
               "GET route #{route.path} should not have :nb_inertia_action_verb"
      end)
    end

    test "all routes dispatch to NbInertia.PageController" do
      routes = ResourceRouter.__routes__()

      Enum.each(routes, fn route ->
        assert route.plug == NbInertia.PageController,
               "Route #{route.verb} #{route.path} should use NbInertia.PageController"
      end)
    end
  end

  describe "extract_actions validation" do
    test "raises on invalid :only actions" do
      assert_raise ArgumentError, ~r/invalid action/, fn ->
        defmodule InvalidOnlyRouter do
          use Phoenix.Router
          import NbInertia.Router

          scope "/" do
            inertia_resource("/users", NbInertia.RouterTest.Pages.UsersPage, only: [:invalid])
          end
        end
      end
    end

    test "raises on invalid :except actions" do
      assert_raise ArgumentError, ~r/invalid action/, fn ->
        defmodule InvalidExceptRouter do
          use Phoenix.Router
          import NbInertia.Router

          scope "/" do
            inertia_resource("/users", NbInertia.RouterTest.Pages.UsersPage, except: [:invalid])
          end
        end
      end
    end

    test "raises on :index for singleton" do
      assert_raise ArgumentError, ~r/invalid action/, fn ->
        defmodule InvalidSingletonRouter do
          use Phoenix.Router
          import NbInertia.Router

          scope "/" do
            inertia_resource("/account", NbInertia.RouterTest.Pages.AccountPage,
              singleton: true,
              only: [:index]
            )
          end
        end
      end
    end
  end

  describe "coexistence with standard Phoenix routes" do
    defmodule MixedRouter do
      use Phoenix.Router
      import NbInertia.Router

      scope "/" do
        # Standard Phoenix routes
        get("/legacy", NbInertia.RouterTest.LegacyController, :index)

        # Inertia page routes
        inertia("/", NbInertia.RouterTest.Pages.HomePage.Index)
        inertia_resource("/users", NbInertia.RouterTest.Pages.UsersPage, only: [:index, :show])
      end
    end

    test "both standard and inertia routes are generated" do
      routes = MixedRouter.__routes__()

      # Standard route
      legacy = find_route(routes, :get, "/legacy")
      assert legacy != nil
      assert legacy.plug == NbInertia.RouterTest.LegacyController
      assert legacy.plug_opts == :index

      # Inertia routes
      home = find_route(routes, :get, "/")
      assert home != nil
      assert home.plug == NbInertia.PageController

      users = find_route(routes, :get, "/users")
      assert users != nil
      assert users.plug == NbInertia.PageController
    end
  end
end

# ── Stub Modules (defined outside the test module) ──────

defmodule NbInertia.RouterTest.Pages.HomePage.Index do
end

defmodule NbInertia.RouterTest.Pages.AboutPage.Index do
end

defmodule NbInertia.RouterTest.Pages.DashboardPage.Index do
end

defmodule NbInertia.RouterTest.Pages.UsersPage do
end

defmodule NbInertia.RouterTest.Pages.UsersPage.Index do
end

defmodule NbInertia.RouterTest.Pages.UsersPage.New do
end

defmodule NbInertia.RouterTest.Pages.UsersPage.Show do
end

defmodule NbInertia.RouterTest.Pages.UsersPage.Edit do
end

defmodule NbInertia.RouterTest.Pages.UsersPage.PostsPage do
end

defmodule NbInertia.RouterTest.Pages.UsersPage.PostsPage.Index do
end

defmodule NbInertia.RouterTest.Pages.UsersPage.PostsPage.New do
end

defmodule NbInertia.RouterTest.Pages.PostsPage do
end

defmodule NbInertia.RouterTest.Pages.PostsPage.Index do
end

defmodule NbInertia.RouterTest.Pages.PostsPage.New do
end

defmodule NbInertia.RouterTest.Pages.PostsPage.Show do
end

defmodule NbInertia.RouterTest.Pages.PostsPage.Edit do
end

defmodule NbInertia.RouterTest.Pages.AccountPage do
end

defmodule NbInertia.RouterTest.Pages.AccountPage.Show do
end

defmodule NbInertia.RouterTest.Pages.AccountPage.New do
end

defmodule NbInertia.RouterTest.Pages.AccountPage.Edit do
end

defmodule NbInertia.RouterTest.LegacyController do
  use Phoenix.Controller, formats: [:html]

  def index(conn, _params) do
    Phoenix.Controller.text(conn, "legacy")
  end
end
