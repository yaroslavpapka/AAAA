defmodule MySuperApp.Blog.Picture do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pictures" do
    field :url, :string
    belongs_to :post, MySuperApp.Blog.Post

    timestamps(type: :utc_datetime)
  end

  def changeset(picture, attrs) do
    picture
    |> cast(attrs, [:url, :post_id])
    |> validate_required([:url])
  end
end
