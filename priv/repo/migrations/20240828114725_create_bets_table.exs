defmodule MySuperApp.Repo.Migrations.CreateBetsTable do
  use Ecto.Migration

  def change do
    create table(:bets) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :match, :string, null: false
      add :outcome, :string, null: false
      add :bet_amount, :decimal, precision: 10, scale: 2, null: false
      add :odds, :decimal, precision: 5, scale: 2, null: false
      add :result, :string, null: false, default: "pending"
      add :win_amount, :decimal, precision: 10, scale: 2
      add :placed_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:bets, [:user_id])
  end
end
