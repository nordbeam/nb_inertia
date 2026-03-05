# Example: User serializer
#
# Serializers define the shape of data sent to the frontend.
# nb_ts generates TypeScript interfaces from these declarations.
#
# Usage in Page modules:
#   prop :user, Blog.UserSerializer              # single user
#   prop :users, list: Blog.UserSerializer       # list of users

defmodule Blog.UserSerializer do
  use NbSerializer.Serializer

  field :id, :number
  field :name, :string
  field :email, :string
  field :role, :string
  field :avatar_url, :string
  field :inserted_at, :string
end
