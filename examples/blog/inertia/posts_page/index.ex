# Example: Post listing — deferred props, defaults, standalone file
#
# Features demonstrated:
#   - prop with defer: true (loaded after initial render for heavy data)
#   - prop with default: value (fallback when not provided)
#   - NO render/0 — uses a standalone .tsx file instead of ~TSX sigil
#   - Convention naming: BlogWeb.PostsPage.Index → "Posts/Index"
#
# When render/0 is omitted, the frontend component lives at:
#   assets/pages/Posts/Index.tsx (your standalone file)
#
# Route: inertia_resource "/posts", PostsPage
# HTTP:  GET /posts → mount/2

defmodule BlogWeb.PostsPage.Index do
  use NbInertia.Page

  prop :posts, list: Blog.PostSerializer
  prop :total_count, :integer

  # defer: true — this prop is NOT included in the initial HTML response.
  # Instead, Inertia makes a follow-up request to load it after the page renders.
  # Use for expensive data that isn't needed for the initial paint.
  prop :filter_options, :map, defer: true

  # default: "all" — if mount/2 doesn't return this key, the default is used.
  prop :current_filter, :string, default: "all"

  def mount(_conn, params) do
    filter = Map.get(params, "filter", "all")
    posts = Blog.Posts.list(filter: filter)

    %{
      posts: posts,
      total_count: Blog.Posts.count(filter: filter),
      filter_options: %{
        statuses: ["all", "published", "draft", "archived"],
        categories: Blog.Posts.categories()
      }
      # current_filter not returned here — uses default: "all"
    }
  end

  # No render/0 — the frontend component is a standalone .tsx file.
  # Place it at assets/pages/Posts/Index.tsx
end
