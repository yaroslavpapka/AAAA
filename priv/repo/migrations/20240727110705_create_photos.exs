defmodule MySuperApp.Repo.Migrations.CreatePhotos do
  use Ecto.Migration

  def change do
    create table(:photos) do
      add :name, :string
      add :photo_locations, {:array, :string}, null: false, default: []

      timestamps()
    end
  end
end
