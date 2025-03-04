defmodule MySuperApp.Permission do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string
    has_many :roles, MySuperApp.Role
    timestamps(type: :utc_datetime)
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
