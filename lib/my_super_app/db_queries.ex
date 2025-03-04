defmodule MySuperApp.DbQueries do
  @moduledoc false
  alias MySuperApp.{Repo, Room, Phone}
  import Ecto.Query

  def rooms_with_phones() do
    Repo.all(
      from room in Room,
        join: phones in assoc(room, :phones),
        preload: [phones: phones],
        select:
          map(
            room,
            [
              :id,
              :room_number,
              phones: [:id, :phone_number]
            ]
          )
    )
  end

  def rooms_without_phones() do
    Repo.all(
      from room in Room,
        left_join: phone in assoc(room, :phones),
        where: is_nil(phone.id),
        select: %{
          room_number: room.room_number
        }
    )
  end

  def phones_without_rooms() do
    Repo.all(
      from phone in Phone,
        left_join: room in assoc(phone, :rooms),
        where: is_nil(room.id),
        select: %{
          phone_number: phone.phone_number
        }
    )
  end
end
