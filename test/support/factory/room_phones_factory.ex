defmodule MySuperApp.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: MySuperApp.Repo
  alias MySuperApp.Room

  def room_factory do
    %Room{room_number: 666}
  end
end
