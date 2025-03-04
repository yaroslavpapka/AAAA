defmodule MySuperApp.Repo.Migrations.Sites do
  use Ecto.Migration

  def change do
    create table(:sites) do
      add :brand, :string
      add :status, :string

      add :operator_id, references(:operators)
      timestamps(type: :utc_datetime)
    end
  end
end
