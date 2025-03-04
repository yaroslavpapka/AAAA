defmodule MySuperAppWeb.BlackJackLive do
  use MySuperAppWeb, :live_view
  alias MySuperApp.Accounts

  @deck_values [{"A", 11}, {"K", 10}, {"Q", 10}, {"J", 10}] ++ Enum.map(2..10, &{Integer.to_string(&1), &1})
  @suits ["♠", "♥", "♦", "♣"]

  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])

    deck = generate_deck() |> Enum.shuffle()
    {:ok, assign(socket, deck: deck, player_hand: [], dealer_hand: [], game_state: :initial, bet_amount: 0, error_message: nil, current_user: user)}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-green-800 p-8 rounded-lg mx-auto mt-10 shadow-2xl border-4 border-yellow-400">
      <h1 class="text-4xl font-extrabold text-yellow-400 text-center mb-8">Blackjack</h1>

      <%= if @game_state != :initial do %>
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-white text-center mb-2">Player's Hand</h2>
          <div class="flex justify-center space-x-4">
            <%= for {value, suit} <- @player_hand do %>
              <div class={
                case suit do
                  "♥" -> "bg-white text-red-500 rounded-lg shadow-lg p-4 text-center w-16 h-24"
                  "♦" -> "bg-white text-red-500 rounded-lg shadow-lg p-4 text-center w-16 h-24"
                  _ -> "bg-white text-black rounded-lg shadow-lg p-4 text-center w-16 h-24"
                end
              }>
                <span class="block text-xl font-bold"><%= value %></span>
                <span class="block text-2xl"><%= suit %></span>
              </div>
            <% end %>
          </div>
          <p class="text-white text-center font-bold mt-2">Total: <%= calculate_total(@player_hand) %></p>
        </div>
      <% end %>

      <%= if @game_state != :initial do %>
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-white text-center mb-2">Dealer's Hand</h2>
          <div class="flex justify-center space-x-4">
            <%= if @game_state == :in_progress do %>
              <div class={
                case elem(hd(@dealer_hand), 1) do
                  "♥" -> "bg-white text-red-500 rounded-lg shadow-lg p-4 text-center w-16 h-24"
                  "♦" -> "bg-white text-red-500 rounded-lg shadow-lg p-4 text-center w-16 h-24"
                  _ -> "bg-white text-black rounded-lg shadow-lg p-4 text-center w-16 h-24"
                end
              }>
                <span class="block text-xl font-bold"><%= elem(hd(@dealer_hand), 0) %></span>
                <span class="block text-2xl"><%= elem(hd(@dealer_hand), 1) %></span>
              </div>
              <div class="bg-gray-500 rounded-lg shadow-lg p-4 text-center w-16 h-24 flex items-center justify-center">
                <span class="text-xl font-bold text-white">?</span>
              </div>
            <% else %>
              <%= for {value, suit} <- @dealer_hand do %>
                <div class={
                  case suit do
                    "♥" -> "bg-white text-red-500 rounded-lg shadow-lg p-4 text-center w-16 h-24"
                    "♦" -> "bg-white text-red-500 rounded-lg shadow-lg p-4 text-center w-16 h-24"
                    _ -> "bg-white text-black rounded-lg shadow-lg p-4 text-center w-16 h-24"
                  end
                }>
                  <span class="block text-xl font-bold"><%= value %></span>
                  <span class="block text-2xl"><%= suit %></span>
                </div>
              <% end %>
            <% end %>
          </div>
          <%= if @game_state != :in_progress do %>
            <p class="text-white text-center font-bold mt-2">Total: <%= calculate_total(@dealer_hand) %></p>
          <% end %>
        </div>
      <% end %>

      <div class="flex justify-center space-x-4 mb-4">
        <%= if @game_state == :initial do %>
          <form phx-change="update_bet" class="flex items-center space-x-4">
            <input type="number" name="bet" min="1" step="0.01" placeholder="Enter your bet" class="px-4 py-2 border rounded-lg" />
          </form>
          <button phx-click="deal" class="px-6 py-2 bg-yellow-400 text-green-900 font-bold rounded-lg shadow-lg hover:bg-yellow-500">Deal</button>
        <% else %>
          <button phx-click="hit" class="px-6 py-2 bg-blue-500 text-white font-bold rounded-lg shadow-lg hover:bg-blue-600">Hit</button>
          <button phx-click="stand" class="px-6 py-2 bg-red-500 text-white font-bold rounded-lg shadow-lg hover:bg-red-600">Stand</button>
        <% end %>
      </div>

      <%= if @game_state == :finished do %>
        <div class="mt-6 text-center">
          <h2 class="text-3xl font-bold text-white"><%= @result %></h2>
          <button phx-click="play_again" class="mt-4 px-6 py-2 bg-yellow-400 text-green-900 font-bold rounded-lg shadow-lg hover:bg-yellow-500">Play Again</button>
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


  def handle_event("update_bet", %{"bet" => bet_amount_str}, socket) do
    case Integer.parse(bet_amount_str) do
      {bet_amount, ""} when bet_amount > 0 ->
        {:noreply, assign(socket, bet_amount: bet_amount, error_message: nil)}
      _ ->
        {:noreply, assign(socket, error_message: "Invalid bet amount")}
    end
  end

  def handle_event("deal", _value, socket) do
    bet_amount = socket.assigns.bet_amount
    current_user = socket.assigns.current_user

    if bet_amount > 0 do
      user = Accounts.get_user!(current_user.id)
      new_balance = Decimal.sub(user.balance, bet_amount)

      if Decimal.compare(new_balance, 0) != :lt do
        Accounts.update_user_balance(current_user.id, new_balance)
        {deck, player_hand, dealer_hand} = deal_initial_cards(socket.assigns.deck)
        {:noreply, assign(socket, deck: deck, player_hand: player_hand, dealer_hand: dealer_hand, game_state: :in_progress, error_message: nil)}
      else
        {:noreply, assign(socket, error_message: "Insufficient funds")}
      end
    else
      {:noreply, assign(socket, error_message: "Invalid bet amount")}
    end
  end

  def handle_event("hit", _value, socket) do
    {deck, player_hand} = hit(socket.assigns.deck, socket.assigns.player_hand)
    total = calculate_total(player_hand)

    if total > 21 do
      {:noreply, finish_game(assign(socket, deck: deck, player_hand: player_hand), :lose)}
    else
      {:noreply, assign(socket, deck: deck, player_hand: player_hand)}
    end
  end

  def handle_event("stand", _value, socket) do
    {_deck, dealer_hand} = dealer_turn(socket.assigns.deck, socket.assigns.dealer_hand)

    player_total = calculate_total(socket.assigns.player_hand)
    dealer_total = calculate_total(dealer_hand)

    result = determine_winner(player_total, dealer_total, socket.assigns.player_hand, dealer_hand)
    updated_socket = finish_game(socket, result, dealer_hand)

    if result == :win do
      user = Accounts.get_user!(socket.assigns.current_user.id)
      new_balance = Decimal.add(user.balance, Decimal.mult(socket.assigns.bet_amount, 2))
      Accounts.update_user_balance(socket.assigns.current_user.id, new_balance)
    end

    {:noreply, updated_socket}
  end

  def handle_event("play_again", _value, socket) do
    deck = generate_deck() |> Enum.shuffle()
    {:noreply, assign(socket, deck: deck, player_hand: [], dealer_hand: [], game_state: :initial, bet_amount: 0, error_message: nil)}
  end

  defp generate_deck do
    for {value, _points} <- @deck_values, suit <- @suits do
      {value, suit}
    end
  end

  defp deal_initial_cards(deck) do
    [p1, d1, p2, d2 | deck] = deck
    {deck, [p1, p2], [d1, d2]}
  end

  defp hit(deck, hand) do
    [card | deck] = deck
    {deck, hand ++ [card]}
  end

  defp dealer_turn(deck, hand) do
    dealer_total = calculate_total(hand)

    if dealer_total < 17 do
      {new_deck, new_hand} = hit(deck, hand)
      dealer_turn(new_deck, new_hand)
    else
      {deck, hand}
    end
  end

  defp calculate_total(hand) do
    {total, aces} = Enum.reduce(hand, {0, 0}, fn
      {"A", _suit}, {sum, aces} -> {sum + 11, aces + 1}
      {value, _suit}, {sum, aces} ->
        points = Enum.find_value(@deck_values, 0, fn {v, p} -> if v == value, do: p, else: nil end)
        {sum + points, aces}
    end)

    adjust_for_aces(total, aces)
  end

  defp adjust_for_aces(total, aces) when total > 21 and aces > 0 do
    adjust_for_aces(total - 10, aces - 1)
  end

  defp adjust_for_aces(total, _aces) do
    total
  end

  defp finish_game(socket, result, dealer_hand \\ nil) do
    assign(socket, game_state: :finished, result: result_message(result), dealer_hand: dealer_hand || socket.assigns.dealer_hand)
  end

  defp determine_winner(player_total, dealer_total, _player_hand, _dealer_hand) do
    cond do
      player_total > 21 -> :lose
      dealer_total > 21 -> :win
      player_total > dealer_total -> :win
      player_total < dealer_total -> :lose
      true -> :tie
    end
  end

  defp result_message(:win), do: "You Win!"
  defp result_message(:lose), do: "You Lose!"
  defp result_message(:tie), do: "It's a Tie!"
end
