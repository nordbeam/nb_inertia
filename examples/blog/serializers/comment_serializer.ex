# Example: Comment serializer
#
# Used in channel real-time updates. When a channel event sends
# a comment, it's serialized with this serializer automatically.

defmodule Blog.CommentSerializer do
  use NbSerializer.Serializer

  field :id, :number
  field :body, :string
  field :inserted_at, :string
  field :author, Blog.UserSerializer
end
