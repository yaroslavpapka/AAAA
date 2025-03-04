defmodule MySuperApp.Operator do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "operators" do
    field :name, :string
    has_many :roles, MySuperApp.Role
    has_many :users, MySuperApp.Accounts.User
    has_many :sites, MySuperApp.Site
    timestamps()
  end

  @doc false
  def changeset(operator, attrs) do
    operator
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> unique_constraint(:name)
  end
end
