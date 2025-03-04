defmodule MySuperAppWeb.WithdrawalRequestsLive do
  use Phoenix.LiveView
  alias MySuperApp.WithdrawalRequests

  def mount(_params, _session, socket) do
    requests = WithdrawalRequests.get_all_requests()
    {:ok, assign(socket, requests: requests)}
  end

  def handle_event("approve_request", %{"request_id" => request_id}, socket) do
    case WithdrawalRequests.update_request_status(request_id, :approved) do
      {:ok, _status} ->
        requests = WithdrawalRequests.get_all_requests()
        {:noreply, assign(socket, requests: requests)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Request not found.")}
    end
  end

  def render(assigns) do
    ~L"""
    <div class="p-6 bg-gray-100">
      <h1 class="text-2xl font-bold mb-4">Admin Withdrawal Requests</h1>
      <div class="overflow-x-auto">
        <table class="min-w-full bg-white border border-gray-300 rounded-lg shadow-md">
          <thead class="bg-gray-200 text-gray-700">
            <tr>
              <th class="px-4 py-2 border-b text-left">User ID</th>
              <th class="px-4 py-2 border-b text-left">Email</th>
              <th class="px-4 py-2 border-b text-left">Amount</th>
              <th class="px-4 py-2 border-b text-left">Wallet</th>
              <th class="px-4 py-2 border-b text-left">Status</th>
              <th class="px-4 py-2 border-b text-left">Actions</th>
            </tr>
          </thead>
          <tbody class="text-gray-600">
            <%= for {request_id, user_id, amount, wallet, status} <- @requests do %>
              <tr class="hover:bg-gray-100">
                <td class="px-4 py-2 border-b text-left"><%= user_id %></td>
                <td class="px-4 py-2 border-b text-left"><%= MySuperApp.Accounts.get_user!(user_id).email %></td>
                <td class="px-4 py-2 border-b text-left"><%= amount %></td>
                <td class="px-4 py-2 border-b text-left"><%= wallet %></td>
                <td class="px-4 py-2 border-b text-left"><%= status %></td>
                <td class="px-4 py-2 border-b text-left">
                  <button
                    phx-click="approve_request"
                    phx-value-request_id="<%= request_id %>"
                    class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
                  >
                    Approve
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
