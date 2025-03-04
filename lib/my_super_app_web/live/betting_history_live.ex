defmodule MySuperAppWeb.BettingHistoryLive do
  use Phoenix.LiveView
  alias MySuperApp.Accounts
  import Ecto.Query, warn: false
  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])

    bets = case user do
      nil -> []
      _ -> list_bets_for_user(user.id)
    end

    socket = assign(socket, bets: bets, user: user)
    {:ok, socket}
  end

  def list_bets_for_user(user_id) do
    MySuperApp.Repo.all(from b in MySuperApp.Bet, where: b.user_id == ^user_id, order_by: [desc: b.placed_at])
  end

  def render(assigns) do
    ~L"""
    <div class="h-screen flex flex-col p-4">
      <h1 class="text-lg font-bold mb-4">Betting History</h1>

      <%= if @bets == [] do %>
        <p class="text-gray-600">No bets placed yet.</p>
      <% else %>
        <table class="min-w-full divide-y divide-gray-200">
          <thead>
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Match</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Outcome</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Bet Amount</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Odds</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Result</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for bet <- @bets do %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap"><%= bet.match %></td>
                <td class="px-6 py-4 whitespace-nowrap"><%= bet.outcome %></td>
                <td class="px-6 py-4 whitespace-nowrap"><%= bet.bet_amount %></td>
                <td class="px-6 py-4 whitespace-nowrap"><%= bet.odds %></td>
                <td class="px-6 py-4 whitespace-nowrap"><%= bet.result %></td>
                <td class="px-6 py-4 whitespace-nowrap"><%= bet.placed_at %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end
end
