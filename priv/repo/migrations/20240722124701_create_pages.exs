defmodule MySuperApp.Repo.Migrations.Pages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :name, :string
      add :operator_id, references(:sites, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create unique_index(:pages, [:name])
  end
end
