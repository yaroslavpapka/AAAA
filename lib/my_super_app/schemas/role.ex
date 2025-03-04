defmodule MySuperApp.Role do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field :name, :string
    belongs_to :operator, MySuperApp.Operator
    belongs_to :permission, MySuperApp.Permission
    timestamps(type: :utc_datetime)
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :operator_id, :permission_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
