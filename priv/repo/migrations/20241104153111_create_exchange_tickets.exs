defmodule MySuperApp.Repo.Migrations.CreateExchangeTickets do
  use Ecto.Migration

  def change do
    create table(:exchange_tickets) do
      add :from_currency, :string
      add :to_currency, :string
      add :amount, :decimal
      add :rate, :decimal
      add :status, :string, default: "pending"
      add :fixed_at, :naive_datetime

      timestamps()
    end
  end
end
