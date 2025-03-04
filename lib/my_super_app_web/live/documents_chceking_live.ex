defmodule MySuperAppWeb.AdminDocumentReviewLive do
  use Phoenix.LiveView
  alias MySuperApp.DocumentRequests

  def mount(_params, _session, socket) do
    requests = DocumentRequests.get_all_requests()
    {:ok, assign(socket, requests: requests)}
  end

  def handle_event("approve_request", %{"request_id" => request_id}, socket) do
    case DocumentRequests.update_request_status(request_id, :approved) do
      {:ok, _status} ->
        requests = DocumentRequests.get_all_requests()
        {:noreply, assign(socket, requests: requests)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Request not found.")}
    end
  end

  def handle_event("reject_request", %{"request_id" => request_id}, socket) do
    case DocumentRequests.update_request_status(request_id, :rejected) do
      {:ok, _status} ->
        requests = DocumentRequests.get_all_requests()
        {:noreply, assign(socket, requests: requests)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Request not found.")}
    end
  end

  def render(assigns) do
    ~L"""
    <div class="p-6 bg-gray-100">
      <h1 class="text-2xl font-bold mb-4">Document Requests</h1>
      <div class="overflow-x-auto">
        <table class="min-w-full bg-white border border-gray-300 rounded-lg shadow-md">
          <thead class="bg-gray-200 text-gray-700">
            <tr>
              <th class="px-4 py-2 border-b text-left">Request ID</th>
              <th class="px-4 py-2 border-b text-left">User ID</th>
              <th class="px-4 py-2 border-b text-left">Document Link</th>
              <th class="px-4 py-2 border-b text-left">Status</th>
              <th class="px-4 py-2 border-b text-left">Actions</th>
            </tr>
          </thead>
          <tbody class="text-gray-600">
            <%= for  {request_id, user_id, link, status}  <- @requests do %>
            <tr class="<%= bet_row_class(status) %>">
              <td class="px-4 py-2 border-b text-left"><%= request_id %></td>
                <td class="px-4 py-2 border-b text-left"><%= user_id %></td>
                <td class="px-4 py-2 border-b text-left"><a href="<%= link %>" target="_blank" class="text-blue-500 hover:underline">View Document</a></td>
                <td class="px-4 py-2 border-b text-left"><%= status %></td>
                <td class="px-4 py-2 border-b text-left">
                  <button
                    phx-click="approve_request"
                    phx-value-request_id="<%= request_id %>"
                    class="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
                  >
                    Approve
                  </button>
                  <button
                    phx-click="reject_request"
                    phx-value-request_id="<%= request_id %>"
                    class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
                  >
                    Reject
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

  defp bet_row_class(result) do
    case result do
      :approved -> "bg-green-100 hover:bg-green-200"
      :rejected -> "bg-red-100 hover:bg-red-200"
      _ -> "hover:bg-gray-100"
    end
  end
end
