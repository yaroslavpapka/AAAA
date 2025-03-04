defmodule MySuperAppWeb.RouletteLive do
  use MySuperAppWeb, :live_view
  alias MySuperApp.Accounts

  @roulette_numbers Enum.to_list(0..36)
  @default_special_bets %{
    red: 0,
    black: 0,
    odd: 0,
    even: 0
  }

  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok, assign(socket,
      bet_amount: 0,
      selected_number: nil,
      bet_type: "single",
      result_number: nil,
      game_state: :initial,
      error_message: nil,
      result_message: nil,
      current_user: user,
      chip_positions: %{},
      special_bets: @default_special_bets,
      roulette_numbers: @roulette_numbers,
      last_chips: []
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-green-900 p-8 rounded-lg max-w-lg mx-auto mt-10 shadow-lg border-4 border-yellow-500">
      <h1 class="text-4xl font-bold text-yellow-500 text-center mb-6">Roulette</h1>
      <div class="text-white mb-4">
        <p>Balance: <%= @current_user.balance %></p>
        <p>Bet Amount: <%= @bet_amount %></p>
      </div>

      <div class="grid grid-cols-1 gap-2">
          <div
            phx-click="place_chip"
            phx-value-number={0}
            class="bg-green-600 text-white text-center py-2 rounded relative ">
            0
            <%= if assigns.chip_positions[0] do %>
              <div class="absolute inset-0 flex justify-center items-center">
                <div class="w-8 h-8 bg-yellow-500 rounded-full flex justify-center items-center">
                  <%= assigns.chip_positions[0] %>
                </div>
              </div>
            <% end %>
        </div>

        <div class="grid grid-cols-3 gap-2">
          <%= for number <- 1..36 do %>
            <div
              phx-click="place_chip"
              phx-value-number={number}
              class={"text-center py-2 rounded relative #{if is_red(number), do: "bg-red-600 text-white", else: "bg-black text-white"}"}>
              <%= number %>
              <%= if assigns.chip_positions[number] do %>
                <div class="absolute inset-0 flex justify-center items-center">
                  <div class="w-8 h-8 bg-yellow-500 rounded-full flex justify-center items-center">
                    <%= assigns.chip_positions[number] %>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <div class="flex justify-between mt-4">
        <button phx-click="place_special_chip" phx-value-type="red" class="px-4 py-2 bg-red-600 text-white rounded relative">
          Red
          <%= if assigns.special_bets.red > 0 do %>
            <div class="absolute inset-0 flex justify-center items-center">
              <div class="w-8 h-8 bg-yellow-500 rounded-full flex justify-center items-center">
                <%= assigns.special_bets.red %>
              </div>
            </div>
          <% end %>
        </button>
        <button phx-click="place_special_chip" phx-value-type="black" class="px-4 py-2 bg-black text-white rounded relative">
          Black
          <%= if assigns.special_bets.black > 0 do %>
            <div class="absolute inset-0 flex justify-center items-center">
              <div class="w-8 h-8 bg-yellow-500 rounded-full flex justify-center items-center">
                <%= assigns.special_bets.black %>
              </div>
            </div>
          <% end %>
        </button>
        <button phx-click="place_special_chip" phx-value-type="odd" class="px-4 py-2 bg-gray-700 text-white rounded relative">
          Odd
          <%= if assigns.special_bets.odd > 0 do %>
            <div class="absolute inset-0 flex justify-center items-center">
              <div class="w-8 h-8 bg-yellow-500 rounded-full flex justify-center items-center">
                <%= assigns.special_bets.odd %>
              </div>
            </div>
          <% end %>
        </button>
        <button phx-click="place_special_chip" phx-value-type="even" class="px-4 py-2 bg-gray-700 text-white rounded relative">
          Even
          <%= if assigns.special_bets.even > 0 do %>
            <div class="absolute inset-0 flex justify-center items-center">
              <div class="w-8 h-8 bg-yellow-500 rounded-full flex justify-center items-center">
                <%= assigns.special_bets.even %>
              </div>
            </div>
          <% end %>
        </button>
      </div>

      <div class="mt-6 text-center">
        <button phx-click="spin" class="mt-4 px-6 py-2 bg-yellow-500 text-green-900 font-bold rounded-lg shadow-lg hover:bg-yellow-600">Spin</button>
        <button phx-click="undo_chip" class="mt-4 px-6 py-2 bg-red-500 text-white font-bold rounded-lg shadow-lg hover:bg-red-600">Undo</button>
      </div>

      <%= if @game_state == :finished do %>
        <div class="mt-6 text-center">
          <h2 class="text-3xl font-bold text-white">Result: <%= @result_number %></h2>
          <h2 class="text-3xl font-bold text-white"><%= @result_message %></h2>
        </div>
      <% end %>

      <%= if @error_message do %>
        <div class="mt-4 text-center text-red-500 font-bold">
          <%= @error_message %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("spin", _value, socket) do
    current_user = socket.assigns.current_user
    special_bets = socket.assigns.special_bets
    chip_positions = socket.assigns.chip_positions

    total_bet =
      Enum.reduce(special_bets, 0, fn {_key, value}, acc -> acc + value end) +
      Enum.reduce(chip_positions, 0, fn {_number, chips}, acc -> acc + chips end)

    if total_bet > 0 do
      user = Accounts.get_user!(current_user.id)
      new_balance = Decimal.sub(user.balance, total_bet)

      if Decimal.compare(new_balance, 0) != :lt do
        result_number = Enum.random(@roulette_numbers)
        Accounts.update_user_balance(current_user.id, new_balance)

        payout =
          Enum.reduce(chip_positions, Decimal.new(0), fn {number, chips}, acc ->
            if number == result_number do
              Decimal.add(acc, Decimal.mult(chips, 36))
            else
              acc
            end
          end)
          |> Decimal.add(
            Enum.reduce(special_bets, Decimal.new(0), fn {bet_type, amount}, acc ->
              cond do
                bet_type == :red and is_red(result_number) -> Decimal.add(acc, Decimal.mult(amount, 1))
                bet_type == :black and is_black(result_number) -> Decimal.add(acc, Decimal.mult(amount, 1))
                bet_type == :odd and rem(result_number, 2) == 1 -> Decimal.add(acc, Decimal.mult(amount, 1))
                bet_type == :even and rem(result_number, 2) == 0 and result_number != 0 -> Decimal.add(acc, Decimal.mult(amount, 1))
                true -> acc
              end
            end)
          )

        result_message =
          if Decimal.compare(payout, 0) == :gt do
            Accounts.update_user_balance(current_user.id, Decimal.add(user.balance, payout))
            "You Win: $#{Decimal.to_string(payout)}!"
          else
            "You Lose!"
          end

        updated_user = Accounts.get_user!(current_user.id)

        {:noreply,
         assign(socket,
           result_number: result_number,
           game_state: :finished,
           result_message: result_message,
           current_user: updated_user,
           chip_positions: %{},
           special_bets: @default_special_bets,
           bet_amount: 0,
           last_chips: []
         )}
      else
        {:noreply, assign(socket, error_message: "Insufficient funds")}
      end
    else
      {:noreply, assign(socket, error_message: "Invalid bet")}
    end
  end

  def handle_event("place_chip", %{"number" => number_str}, socket) do
    number = String.to_integer(number_str)
    chip_positions = Map.update(socket.assigns.chip_positions, number, 1, &(&1 + 1))
    last_chips = [{:number, number} | socket.assigns.last_chips]

    {:noreply,
     assign(socket,
       chip_positions: chip_positions,
       bet_amount: socket.assigns.bet_amount + 1,
       selected_number: number,
       last_chips: last_chips
     )}
  end

  def handle_event("place_special_chip", %{"type" => bet_type}, socket) do
    special_bets = Map.update(socket.assigns.special_bets, String.to_existing_atom(bet_type), 1, &(&1 + 1))
    last_chips = [{:special, bet_type} | socket.assigns.last_chips]

    {:noreply,
     assign(socket,
       special_bets: special_bets,
       bet_amount: socket.assigns.bet_amount + 1,
       last_chips: last_chips
     )}
  end

  def handle_event("undo_chip", _value, socket) do
    case socket.assigns.last_chips do
      [] ->
        {:noreply, socket}

      [{:number, number} | rest] ->
        chip_positions = Map.update!(socket.assigns.chip_positions, number, &(&1 - 1))
        chip_positions = if chip_positions[number] == 0, do: Map.delete(chip_positions, number), else: chip_positions

        {:noreply,
         assign(socket,
           chip_positions: chip_positions,
           bet_amount: socket.assigns.bet_amount - 1,
           last_chips: rest
         )}

      [{:special, bet_type} | rest] ->
        special_bets = Map.update!(socket.assigns.special_bets, String.to_existing_atom(bet_type), &(&1 - 1))

        {:noreply,
         assign(socket,
           special_bets: special_bets,
           bet_amount: socket.assigns.bet_amount - 1,
           last_chips: rest
         )}
    end
  end

  defp is_red(number), do: number in [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
  defp is_black(number), do: not is_red(number)
end
