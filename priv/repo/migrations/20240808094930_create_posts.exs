defmodule MySuperApp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :body, :text
      add :published, :boolean, default: false, null: false
      add :published_at, :utc_datetime

      add :user_id, references(:users, type: :bigserial, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end
  end
end
