# Example: Post serializer with nested author
#
# Nested serializers generate nested TypeScript types automatically:
#   post.author → User type

defmodule Blog.PostSerializer do
  use NbSerializer.Serializer

  field :id, :number
  field :title, :string
  field :body, :string
  field :status, :string
  field :category, :string
  field :published_at, :string
  field :author, Blog.UserSerializer
end
