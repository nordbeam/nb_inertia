# Example: Post detail — real-time channels + delete action
#
# Features demonstrated:
#   - channel macro with topic interpolation from prop values
#   - Multiple on/2 event handlers with different strategies:
#     :append (add to list), :remove (remove by key), :replace (overwrite)
#   - prop with nullable: true
#   - action/3 with :delete verb
#   - ~TSX with useChannelProps usage
#
# Route: inertia_resource "/posts", PostsPage
# HTTP:  GET /posts/:post_id → mount/2
#        DELETE /posts/:post_id → action/3 with :delete

defmodule BlogWeb.PostsPage.Show do
  use NbInertia.Page

  prop :post, Blog.PostSerializer
  prop :comments, list: Blog.CommentSerializer
  prop :typing_user, :map, nullable: true

  # Declarative channel bindings for real-time updates.
  # The topic "post:{post.id}" interpolates the :post prop's id at runtime.
  # This is validated at compile time — if :post isn't declared as a prop, you
  # get a compile error.
  channel "post:{post.id}" do
    # When "comment_created" is broadcast, append the payload to the :comments list
    on "comment_created", prop: :comments, strategy: :append

    # When "comment_deleted" is broadcast, remove the matching item by :id
    on "comment_deleted", prop: :comments, strategy: :remove, key: :id

    # When "typing" is broadcast, replace the entire :typing_user value
    on "typing", prop: :typing_user, strategy: :replace
  end

  def mount(_conn, %{"post_id" => id}) do
    post = Blog.Posts.get!(id)

    %{
      post: post,
      comments: Blog.Comments.for_post(post),
      typing_user: nil
    }
  end

  # DELETE /posts/:post_id → :delete verb
  def action(conn, %{"post_id" => id}, :delete) do
    Blog.Posts.delete!(id)

    conn
    |> put_flash(:info, "Post deleted")
    |> redirect(to: "/posts")
  end

  def render do
    ~TSX"""
    import { Link } from '@inertiajs/react'

    export default function PostShow({ post, comments, typing_user }: Props) {
      // When channel macro is used, the extraction preamble auto-generates:
      //   - import { useChannelProps } from '@/lib/socket'
      //   - const __channelConfig = { ... }
      //
      // useChannelProps connects to the Phoenix channel and applies the
      // declared strategies automatically when events are received.

      return (
        <article>
          <header>
            <h1>{post.title}</h1>
            <p>by {post.author.name} · {post.status}</p>
          </header>

          <div dangerouslySetInnerHTML={{ __html: post.body }} />

          <section>
            <h2>Comments ({comments.length})</h2>

            {typing_user && (
              <p className="typing-indicator">{typing_user.name} is typing...</p>
            )}

            {comments.map(comment => (
              <div key={comment.id} className="comment">
                <strong>{comment.author.name}</strong>
                <time>{comment.inserted_at}</time>
                <p>{comment.body}</p>
              </div>
            ))}
          </section>

          <nav>
            <Link href={`/posts/${post.id}/edit`}>Edit</Link>
            <Link href="/posts">Back to Posts</Link>
          </nav>
        </article>
      )
    }
    """
  end
end
