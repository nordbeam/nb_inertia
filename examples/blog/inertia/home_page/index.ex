# Example: Landing page — basic mount/2 + ~TSX sigil
#
# Features demonstrated:
#   - use NbInertia.Page (minimal, no options)
#   - prop with serializer list type
#   - Simple mount/2 returning a props map
#   - ~TSX sigil for colocated frontend component
#   - Convention naming: BlogWeb.HomePage.Index → "Home/Index"
#
# Route: inertia "/", HomePage.Index
# HTTP:  GET / → mount/2

defmodule BlogWeb.HomePage.Index do
  use NbInertia.Page

  prop :featured_posts, list: Blog.PostSerializer
  prop :stats, :map

  def mount(_conn, _params) do
    %{
      featured_posts: Blog.Posts.featured(limit: 5),
      stats: %{
        total_posts: Blog.Posts.count(),
        total_users: Blog.Accounts.count()
      }
    }
  end

  # The ~TSX sigil embeds the React component directly in this module.
  # At compile time, the extractor writes this to:
  #   .nb_inertia/pages/Home/Index.tsx
  #
  # The generated file includes a Props interface derived from the prop
  # declarations above, so you get full type safety without manual types.
  def render do
    ~TSX"""
    import { Link } from '@inertiajs/react'

    export default function HomeIndex({ featured_posts, stats }: Props) {
      return (
        <div className="home">
          <h1>Blog</h1>
          <p>{stats.total_posts} posts by {stats.total_users} authors</p>

          <section>
            <h2>Featured Posts</h2>
            {featured_posts.map(post => (
              <article key={post.id}>
                <Link href={`/posts/${post.id}`}>
                  <h3>{post.title}</h3>
                </Link>
                <span>by {post.author.name}</span>
              </article>
            ))}
          </section>

          <Link href="/posts">View All Posts</Link>
        </div>
      )
    }
    """
  end
end
