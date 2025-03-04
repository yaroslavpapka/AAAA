defmodule MySuperApp.Bet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bets" do
    field :match, :string
    field :outcome, :string
    field :bet_amount, :decimal
    field :odds, :decimal
    field :result, :string, default: "pending" # "pending", "win", "lose"
    field :win_amount, :decimal
    field :placed_at, :utc_datetime

    belongs_to :user, MySuperApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:user_id, :match, :outcome, :bet_amount, :odds, :result, :win_amount, :placed_at])
    |> validate_required([:user_id, :match, :outcome, :bet_amount, :odds, :placed_at])
    |> validate_number(:bet_amount, greater_than: 0)
    |> validate_number(:odds, greater_than: 1)
  end
end
