defmodule MySuperApp.Tag do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :name, :string

    many_to_many :posts, MySuperApp.Blog.Post, join_through: "posts_tags", on_replace: :delete
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
