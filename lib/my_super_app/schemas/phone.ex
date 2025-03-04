defmodule MySuperApp.Phone do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "phones" do
    field :phone_number, :string

    many_to_many :rooms, MySuperApp.Phone, join_through: "rooms_phones"
  end

  def changeset(phone, attrs) do
    phone
    |> cast(attrs, [:phone_number])
    |> validate_required([:phone_number])
    |> validate_length(:phone_number, min: 10, max: 12)
  end
end
