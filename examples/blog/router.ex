# Example: Blog router with NbInertia.Page router macros
#
# Features demonstrated:
#   - import NbInertia.Router
#   - inertia/2 (single page route)
#   - inertia_resource/2,3 (full CRUD resource)
#   - inertia_shared/1 (scope-level shared props)
#   - Scoped shared props (admin-only)
#   - only: option for filtering resource routes
#
# Copy this into your router and adjust module names.

defmodule BlogWeb.Router do
  use BlogWeb, :router
  import NbInertia.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NbInertia.Plug
    plug NbInertia.Plugs.Precognition
  end

  pipeline :require_admin do
    plug BlogWeb.Plugs.RequireAdmin
  end

  scope "/", BlogWeb do
    pipe_through :browser

    # Shared props: every page in this scope gets current_user + flash.
    # These are resolved at request time via the module's build_props/2 callback.
    inertia_shared BlogWeb.InertiaShared.Auth

    # Single page route: GET / → HomePage.Index.mount/2
    inertia "/", HomePage.Index

    # Full CRUD resource for posts. Expands to:
    #   GET    /posts           → PostsPage.Index.mount/2
    #   GET    /posts/new       → PostsPage.New.mount/2
    #   POST   /posts           → PostsPage.New.action/3 (:create)
    #   GET    /posts/:post_id  → PostsPage.Show.mount/2
    #   GET    /posts/:post_id/edit → PostsPage.Edit.mount/2
    #   PATCH  /posts/:post_id  → PostsPage.Edit.action/3 (:update)
    #   PUT    /posts/:post_id  → PostsPage.Edit.action/3 (:update)
    #   DELETE /posts/:post_id  → PostsPage.Show.action/3 (:delete)
    inertia_resource "/posts", PostsPage

    # Custom route for comment creation (modal).
    # POST /posts/:post_id/comments → CommentsPage.Create.action/3 (:create)
    inertia "/posts/:post_id/comments", CommentsPage.Create
  end

  scope "/admin", BlogWeb do
    pipe_through [:browser, :require_admin]

    # Admin-specific shared props layered on top of auth shared props.
    inertia_shared BlogWeb.InertiaShared.Admin

    # Admin dashboard — index only, no CRUD
    inertia_resource "/dashboard", Admin.DashboardPage, only: [:index]
  end
end
