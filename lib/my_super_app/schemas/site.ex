defmodule MySuperApp.Site do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false
  schema "sites" do
    field :brand, :string
    field :status, Ecto.Enum, values: [:ACTIVE, :STOPPED], default: :ACTIVE
    has_many :pages, MySuperApp.Page
    belongs_to :operator, MySuperApp.Operator
    timestamps()
  end

  @doc false
  def changeset(site, attrs) do
    site
    |> cast(attrs, [:brand, :status, :operator_id])
    |> validate_required([:brand, :operator_id])
    |> validate_length(:brand, min: 3, max: 50)
    |> unique_constraint(:brand)
  end
end
