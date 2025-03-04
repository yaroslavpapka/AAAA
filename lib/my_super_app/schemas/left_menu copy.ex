defmodule MySuperApp.ExchangeTicket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exchange_tickets" do
    field :from_currency, :string
    field :to_currency, :string
    field :amount, :decimal
    field :rate, :decimal
    field :status, :string, default: "pending"
    field :fixed_at, :naive_datetime

    timestamps()
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:from_currency, :to_currency, :amount, :rate, :status, :fixed_at])
    |> validate_required([:from_currency, :to_currency, :amount, :rate, :status, :fixed_at])
  end
end
