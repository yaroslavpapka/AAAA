defmodule MySuperApp.Photos.Photo do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "photos" do
    field :name, :string
    field :photo_locations, {:array, :string}, default: []

    timestamps()
  end

  def changeset(photo, attrs) do
    photo
    |> cast(attrs, [:name, :photo_locations])
    |> validate_required([:name, :photo_locations])
  end
end
