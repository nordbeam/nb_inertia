# Example: Comment creation modal
#
# Features demonstrated:
#   - modal macro with dynamic base_url (function capture)
#   - Modal rendering: page works both as a full page AND as a modal overlay
#   - redirect_modal_success/3 for closing modal with success message
#   - action/3 with :create verb inside a modal
#   - form_inputs for comment form type generation
#   - ~TSX with useForm inside a modal
#
# When opened via <ModalLink>, this page renders as an overlay on top of the
# post show page. When visited directly, it renders as a full page.
#
# Route: inertia "/posts/:post_id/comments", CommentsPage.Create
# HTTP:  GET /posts/:post_id/comments → mount/2
#        POST /posts/:post_id/comments → action/3 with :create

defmodule BlogWeb.CommentsPage.Create do
  use NbInertia.Page

  prop :post, Blog.PostSerializer

  # Dynamic base_url: the function receives conn.params at request time.
  # When rendered as a modal, the "page behind" shows the content at base_url.
  # Here, that's the post show page the comment belongs to.
  modal base_url: &"/posts/#{&1["post_id"]}",
        size: :md,
        position: :center

  form_inputs :comment_form do
    field :body, :string
  end

  def mount(_conn, %{"post_id" => post_id}) do
    %{post: Blog.Posts.get!(post_id)}
  end

  def action(conn, %{"comment" => params, "post_id" => post_id}, :create) do
    case Blog.Comments.create(post_id, conn.assigns.current_user, params) do
      {:ok, _comment} ->
        # Closes the modal and shows a flash message on the underlying page.
        # The user sees the post show page with the new comment (via channels)
        # and a brief success notification.
        redirect_modal_success(conn, "Comment added!", to: "/posts/#{post_id}")

      {:error, changeset} ->
        # Re-renders the modal with validation errors displayed inline.
        {:error, changeset}
    end
  end

  def render do
    ~TSX"""
    import { useForm } from '@nordbeam/nb-inertia/react/useForm'

    export default function CommentCreate({ post }: Props) {
      const form = useForm({ body: '' })

      return (
        <div className="comment-form">
          <h2>Add Comment to "{post.title}"</h2>

          <form onSubmit={e => {
            e.preventDefault()
            form.submit('post', `/posts/${post.id}/comments`)
          }}>
            <div>
              <textarea
                value={form.data.body}
                onChange={e => form.setData('body', e.target.value)}
                placeholder="Write your comment..."
                rows={4}
              />
              {form.errors.body && <span className="error">{form.errors.body}</span>}
            </div>

            <button type="submit" disabled={form.processing}>
              {form.processing ? 'Posting...' : 'Post Comment'}
            </button>
          </form>
        </div>
      )
    }
    """
  end
end
