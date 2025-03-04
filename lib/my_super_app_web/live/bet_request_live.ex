defmodule MySuperAppWeb.BetLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.Bet
  alias MySuperApp.Repo

  def mount(_params, _session, socket) do
    bets = list_bets()
    {:ok, assign(socket, bets: bets, selected_bet: nil)}
  end

  def handle_event("select_bet", %{"bet_id" => bet_id}, socket) do
    bet = Repo.get(Bet, bet_id)
    {:noreply, assign(socket, selected_bet: bet)}
  end

  def handle_event("update_bet", %{"bet_id" => bet_id, "result" => result}, socket) do
    bet = Repo.get(Bet, bet_id)

    win_amount =
      if result == "win" do
        Decimal.mult(bet.bet_amount, bet.odds)
      else
        Decimal.new(0)
      end

    changeset =
      Bet.changeset(bet, %{result: result, win_amount: win_amount})

    case Repo.update(changeset) do
      {:ok, updated_bet} ->
        bets = list_bets()
        {:noreply, assign(socket, bets: bets, selected_bet: updated_bet)}

      {:error, _changeset} ->
        {:noreply, assign(socket, error: "Failed to update the bet.")}
    end
  end

  defp list_bets do
    Repo.all(Bet)
  end

  def render(assigns) do
    ~L"""
    <div class="p-6">
      <h1 class="text-2xl font-bold mb-4">Bets</h1>
      <div class="overflow-x-auto">
        <table class="min-w-full bg-white border border-gray-300 rounded-lg shadow-md">
          <thead class="bg-gray-200 text-gray-700">
            <tr>
              <th class="px-4 py-2 border-b text-left">Match</th>
              <th class="px-4 py-2 border-b text-left">Outcome</th>
              <th class="px-4 py-2 border-b text-left">Bet Amount</th>
              <th class="px-4 py-2 border-b text-left">Odds</th>
              <th class="px-4 py-2 border-b text-left">Result</th>
              <th class="px-4 py-2 border-b text-left">Win Amount</th>
              <th class="px-4 py-2 border-b text-left">Placed At</th>
              <th class="px-4 py-2 border-b text-left">Actions</th>
            </tr>
          </thead>
          <tbody class="text-gray-600">
            <%= for bet <- @bets do %>
              <tr class="<%= bet_row_class(bet.result) %>">
                <td class="px-4 py-2 border-b text-left"><%= bet.match %></td>
                <td class="px-4 py-2 border-b text-left"><%= bet.outcome %></td>
                <td class="px-4 py-2 border-b text-left"><%= bet.bet_amount %></td>
                <td class="px-4 py-2 border-b text-left"><%= bet.odds %></td>
                <td class="px-4 py-2 border-b text-left"><%= bet.result %></td>
                <td class="px-4 py-2 border-b text-left"><%= bet.win_amount %></td>
                <td class="px-4 py-2 border-b text-left"><%= bet.placed_at %></td>
                <td class="px-4 py-2 border-b text-left">
                  <%= if bet.result == "pending" do %>
                    <button
                      phx-click="select_bet"
                      phx-value-bet_id="<%= bet.id %>"
                      class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
                    >
                      View
                    </button>
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <%= if @selected_bet do %>
        <div class="mt-6 p-4 border rounded bg-white shadow-md">
          <h2 class="text-xl font-bold mb-2">Bet Details</h2>
          <p><strong>Match:</strong> <%= @selected_bet.match %></p>
          <p><strong>Outcome:</strong> <%= @selected_bet.outcome %></p>
          <p><strong>Bet Amount:</strong> <%= @selected_bet.bet_amount %></p>
          <p><strong>Odds:</strong> <%= @selected_bet.odds %></p>
          <p><strong>Result:</strong> <%= @selected_bet.result %></p>
          <p><strong>Win Amount:</strong> <%= @selected_bet.win_amount %></p>
          <p><strong>Placed At:</strong> <%= @selected_bet.placed_at %></p>

          <div class="mt-4">
            <button
              phx-click="update_bet"
              phx-value-bet_id="<%= @selected_bet.id %>"
              phx-value-result="win"
              class="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
            >
              Win
            </button>
            <button
              phx-click="update_bet"
              phx-value-bet_id="<%= @selected_bet.id %>"
              phx-value-result="lose"
              class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
            >
              Lose
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp bet_row_class(result) do
    case result do
      "win" -> "bg-green-100 hover:bg-green-200"
      "lose" -> "bg-red-100 hover:bg-red-200"
      _ -> "hover:bg-gray-100"
    end
  end
end
