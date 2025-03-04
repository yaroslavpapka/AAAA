defmodule MySuperAppWeb.WithdrawalLive do
  use MySuperAppWeb, :live_view
  alias MySuperApp.WithdrawalRequests

  def mount(_params, session, socket) do
    current_user = MySuperApp.Accounts.get_user_by_session_token(session["user_token"])
    {:ok, assign(socket, requests: WithdrawalRequests.get_requests_by_user(current_user.id), user_id: nil, amount: nil, current_user: current_user, wallet: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto py-10">
      <h2 class="text-2xl font-bold mb-6">Request Withdrawal</h2>

      <form phx-submit="request_withdrawal" class="space-y-4">
        <div>
          <label for="amount" class="block text-sm font-medium text-gray-700">Amount</label>
          <input type="number" min="1" name="amount" value={@amount} required class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
        </div>

        <div>
          <label for="wallet" class="block text-sm font-medium text-gray-700">USDT Wallet Address</label>
          <input type="text" name="wallet" value={@wallet} required class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
        </div>

        <button type="submit" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">Request Withdrawal</button>
      </form>

      <%= if @flash[:info] do %>
        <p class="mt-4 text-green-600"><%= @flash[:info] %></p>
      <% end %>

      <%= if @flash[:error] do %>
        <p class="mt-4 text-red-600"><%= @flash[:error] %></p>
      <% end %>

      <h3 class="text-lg font-semibold mt-8 mb-4">Your Requests</h3>
      <ul class="space-y-2">
        <%= for {_request_id, _user_id, amount, _wallet, status} <- @requests do %>
          <li class="bg-white shadow-sm rounded-md p-4 border border-gray-200">
            <div class="flex justify-between">
              <span class="font-medium text-gray-900">Amount: <%= amount %></span>
              <span class="text-sm text-gray-500">Status: <%= status %></span>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def handle_event("request_withdrawal", %{"amount" => amount, "wallet" => wallet}, socket) do
    user_id = socket.assigns.current_user.id
    request_id = Ecto.UUID.generate()

    WithdrawalRequests.add_request(request_id, user_id, amount, wallet)
    requests = WithdrawalRequests.get_requests_by_user(user_id)
    {:noreply, assign(socket, :requests, [{request_id, user_id, amount, :pending} | requests])}
  end
end
