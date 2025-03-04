defmodule MySuperApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :title, :body, :inserted_at, :updated_at]}
  schema "posts" do
    field :title, :string
    field :body, :string
    field :published, :boolean, default: false
    field :published_at, :utc_datetime

    has_one :picture, MySuperApp.Blog.Picture, on_replace: :update

    belongs_to :user, MySuperApp.User, type: :id
    many_to_many :tags, MySuperApp.Tag, join_through: "posts_tags", on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :user_id, :published, :published_at])
    |> validate_required([:title, :body, :user_id])
    |> validate_length(:title, min: 1, max: 250)
    |> validate_length(:body, min: 1, max: 250)
    |> cast_assoc(:picture)
    |> set_published_at()
  end

  defp set_published_at(changeset) do
    case {get_change(changeset, :published), get_field(changeset, :published_at)} do
      {true, _} ->
        changeset
        |> put_change(:published_at, DateTime.utc_now() |> DateTime.truncate(:second))

      _ ->
        changeset
        |> put_change(:published_at, nil)
    end
  end

end
