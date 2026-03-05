# Example: Create post — form_inputs + precognition
#
# Features demonstrated:
#   - form_inputs macro with field declarations (generates TypeScript form types)
#   - action/3 with :create verb
#   - precognition macro for real-time server-side validation
#   - {:error, changeset} return for validation failures
#   - Redirect on success with put_flash
#   - ~TSX with useForm and onBlur validation
#
# Route: inertia_resource "/posts", PostsPage
# HTTP:  GET /posts/new → mount/2
#        POST /posts → action/3 with :create

defmodule BlogWeb.PostsPage.New do
  use NbInertia.Page

  prop :categories, :list

  # form_inputs declares the shape of form data for TypeScript type generation.
  # nb_ts generates a PostFormInputs interface from this block.
  # The :optional flag means the field isn't required for submission.
  form_inputs :post_form do
    field :title, :string
    field :body, :string
    field :status, :string, optional: true
    field :category, :string, optional: true
  end

  def mount(_conn, _params) do
    %{categories: Blog.Posts.categories()}
  end

  def action(conn, %{"post" => params}, :create) do
    changeset = Blog.Posts.change_post(%Blog.Post{}, params)

    # precognition/3 macro:
    #
    # When the request has the `Precognition: true` header (sent by useForm's
    # validate() method), this validates the changeset and returns immediately
    # with 204 (valid) or 422 (errors) — the do-block is NOT executed.
    #
    # Only real form submissions (without the Precognition header) reach the
    # do-block. This gives you free real-time validation with zero extra code.
    precognition conn, changeset do
      case Blog.Posts.create(params) do
        {:ok, post} ->
          conn
          |> put_flash(:info, "Post created!")
          |> redirect(to: "/posts/#{post.id}")

        {:error, changeset} ->
          # Returning {:error, changeset} re-renders the page with validation
          # errors. The errors are automatically converted to a map and sent
          # as the `errors` prop to the frontend.
          {:error, changeset}
      end
    end
  end

  def render do
    ~TSX"""
    import { useForm } from '@nordbeam/nb-inertia/react/useForm'

    export default function PostNew({ categories }: Props) {
      const form = useForm({ title: '', body: '', status: 'draft', category: '' })

      return (
        <form onSubmit={e => { e.preventDefault(); form.submit('post', '/posts') }}>
          <div>
            <label htmlFor="title">Title</label>
            <input
              id="title"
              value={form.data.title}
              onChange={e => form.setData('title', e.target.value)}
              onBlur={() => form.validate('title')}
            />
            {form.errors.title && <span className="error">{form.errors.title}</span>}
          </div>

          <div>
            <label htmlFor="body">Body</label>
            <textarea
              id="body"
              value={form.data.body}
              onChange={e => form.setData('body', e.target.value)}
              onBlur={() => form.validate('body')}
              rows={10}
            />
            {form.errors.body && <span className="error">{form.errors.body}</span>}
          </div>

          <div>
            <label htmlFor="category">Category</label>
            <select
              id="category"
              value={form.data.category}
              onChange={e => form.setData('category', e.target.value)}
            >
              <option value="">Select a category...</option>
              {categories.map((cat: string) => (
                <option key={cat} value={cat}>{cat}</option>
              ))}
            </select>
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
            </select>
          </div>

          <button type="submit" disabled={form.processing}>
            {form.processing ? 'Creating...' : 'Create Post'}
          </button>
        </form>
      )
    }
    """
  end
end
