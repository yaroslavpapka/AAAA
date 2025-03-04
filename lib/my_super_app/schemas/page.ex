defmodule MySuperApp.Page do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false
  schema "pages" do
    field :name, :string
    belongs_to :site, MySuperApp.Site
    timestamps()
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> unique_constraint(:name)
  end
end
