# Example: Edit post — conn pipeline mount + inertia_flash
#
# Features demonstrated:
#   - mount/2 returning conn (not a map) via props/2 helper
#   - props/2 helper to set props on the conn pipeline
#   - action/3 with :update verb
#   - inertia_flash/3 for one-time flash data
#   - {:error, changeset} for validation failures
#   - form_inputs with field declarations
#   - ~TSX with useForm
#
# Route: inertia_resource "/posts", PostsPage
# HTTP:  GET /posts/:post_id/edit → mount/2
#        PATCH /posts/:post_id → action/3 with :update

defmodule BlogWeb.PostsPage.Edit do
  use NbInertia.Page

  prop :post, Blog.PostSerializer
  prop :categories, :list

  form_inputs :post_form do
    field :title, :string
    field :body, :string
    field :status, :string
    field :category, :string, optional: true
  end

  # Returning conn from mount/2 instead of a plain map.
  # Use this pattern when you need to modify the conn (set headers, assign values)
  # alongside your props. Call props/2 to attach the props map to the conn.
  def mount(conn, %{"post_id" => id}) do
    post = Blog.Posts.get!(id)

    conn
    |> props(%{
      post: post,
      categories: Blog.Posts.categories()
    })
  end

  def action(conn, %{"post" => params, "post_id" => id}, :update) do
    post = Blog.Posts.get!(id)

    case Blog.Posts.update(post, params) do
      {:ok, updated_post} ->
        conn
        # inertia_flash/3 sends one-time data that doesn't persist in browser
        # history. Unlike put_flash, it's Inertia-specific and cleared after
        # the next page visit.
        |> inertia_flash(:info, "Post updated successfully")
        |> redirect(to: "/posts/#{updated_post.id}")

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def render do
    ~TSX"""
    import { useForm } from '@nordbeam/nb-inertia/react/useForm'

    export default function PostEdit({ post, categories }: Props) {
      const form = useForm({
        title: post.title,
        body: post.body,
        status: post.status,
        category: post.category,
      })

      return (
        <form onSubmit={e => {
          e.preventDefault()
          form.submit('patch', `/posts/${post.id}`)
        }}>
          <h1>Edit: {post.title}</h1>

          <div>
            <label htmlFor="title">Title</label>
            <input
              id="title"
              value={form.data.title}
              onChange={e => form.setData('title', e.target.value)}
            />
            {form.errors.title && <span className="error">{form.errors.title}</span>}
          </div>

          <div>
            <label htmlFor="body">Body</label>
            <textarea
              id="body"
              value={form.data.body}
              onChange={e => form.setData('body', e.target.value)}
              rows={12}
            />
            {form.errors.body && <span className="error">{form.errors.body}</span>}
          </div>

          <div>
            <label htmlFor="status">Status</label>
            <select
              id="status"
              value={form.data.status}
              onChange={e => form.setData('status', e.target.value)}
            >
              <option value="draft">Draft</option>
              <option value="published">Published</option>
              <option value="archived">Archived</option>
            </select>
          </div>

          <div>
            <label htmlFor="category">Category</label>
            <select
              id="category"
              value={form.data.category}
              onChange={e => form.setData('category', e.target.value)}
            >
              <option value="">None</option>
              {categories.map((cat: string) => (
                <option key={cat} value={cat}>{cat}</option>
              ))}
            </select>
          </div>

          <button type="submit" disabled={form.processing}>
            {form.processing ? 'Saving...' : 'Save Changes'}
          </button>
        </form>
      )
    }
    """
  end
end
