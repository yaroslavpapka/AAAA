defmodule MySuperApp.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :email, :string
    timestamps(type: :utc_datetime)
    belongs_to :role, MySuperApp.Role
    belongs_to :operator, MySuperApp.Operator
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :role_id, :operator_id])
    |> validate_required([:username, :email])
    |> validate_length(:username, min: 3, max: 50)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end
