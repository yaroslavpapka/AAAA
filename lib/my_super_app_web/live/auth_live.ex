defmodule MySuperAppWeb.AuthLive do
  use MySuperAppWeb, :live_view
  alias MySuperApp.Accounts

  @mailjet_api_key System.get_env("MAILJET_API_KEY") 
  @mailjet_secret_key System.get_env("MAILJET_SECRET_KEY") 

  def mount(_params, _session, socket) do
    users = Accounts.get_all_users()
    emails = Enum.map(users, fn user -> user.email end)
    {:ok, assign(socket, users: emails, selected_users: [], email_content: "", message: nil, search_results: [])}
  end

  def handle_event("remove_user", %{"user" => user_to_remove}, socket) do
    new_selected_users = socket.assigns.selected_users -- [user_to_remove]
    new_users_list = [user_to_remove | socket.assigns.users] |> Enum.sort()

    {:noreply, assign(socket, selected_users: new_selected_users, users: new_users_list)}
  end

  def handle_event("search_users", %{"value" => query}, socket) do
    search_results =
      if query != "" do
        Enum.filter(socket.assigns.users, fn user -> String.contains?(user, query) end)
      else
        []
      end

    {:noreply, assign(socket, search_results: search_results)}
  end

  def handle_event("add_user", %{"user" => user_to_add}, socket) do
    updated_users = Enum.filter(socket.assigns.users, fn user -> user != user_to_add end)
    updated_selected_users = Enum.uniq([user_to_add | socket.assigns.selected_users])

    {:noreply, assign(socket, users: updated_users, selected_users: updated_selected_users, search_results: [])}
  end

  def handle_event("update_email_content", %{"email_content" => email_content}, socket) do
    {:noreply, assign(socket, email_content: email_content)}
  end

  def handle_event("send_bulk_email", %{"email_content" => email_content}, socket) do
    case send_bulk_email(socket.assigns.selected_users, email_content) do
      :ok ->
        {:noreply, assign(socket, message: "Emails sent successfully!")}
      :error ->
        {:noreply, assign(socket, message: "Failed to send emails.")}
    end
  end

  def render(assigns) do
    ~L"""
    <div class="max-w-md mx-auto p-6 bg-white shadow-lg rounded-lg">
      <h1 class="text-2xl font-bold mb-4 text-gray-700">Send Bulk Email</h1>

      <form phx-submit="send_bulk_email" class="space-y-6">
        <div>
          <label for="selected_users" class="block text-sm font-medium text-gray-600">Selected Users:</label>
          <div class="flex flex-wrap mt-2 space-x-2">
            <%= for user <- @selected_users do %>
              <div class="flex items-center bg-blue-100 text-blue-600 px-3 py-1 rounded-full">
                <span><%= user %></span>
                <button type="button" phx-click="remove_user" phx-value-user="<%= user %>" class="ml-2 text-red-500 hover:text-red-700">
                  &times;
                </button>
              </div>
            <% end %>
          </div>
        </div>

        <div>
          <label for="user_search" class="block text-sm font-medium text-gray-600">Add User:</label>
          <input type="text" id="user_search" name="user_search" class="mt-2 block w-full rounded-md border-gray-300 shadow-sm" phx-keyup="search_users" placeholder="Type to search...">
          <div class="bg-white border mt-1 rounded-md shadow-lg">
            <%= for user <- @search_results do %>
              <div phx-click="add_user" phx-value-user="<%= user %>" class="px-4 py-2 cursor-pointer hover:bg-gray-200">
                <%= user %>
              </div>
            <% end %>
          </div>
        </div>

        <div>
          <label for="email_content" class="block text-sm font-medium text-gray-600">Email Content:</label>
          <textarea id="email_content" name="email_content" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm" placeholder="Write your message..." phx-change="update_email_content"></textarea>
        </div>

        <div>
          <button type="submit" class="w-full bg-blue-500 text-white rounded-md p-2 hover:bg-blue-600">Send Email</button>
        </div>
      </form>

      <%= if @message do %>
        <div class="mt-4 p-2 bg-green-100 text-green-700 border border-green-300 rounded-md">
          <%= @message %>
        </div>
      <% end %>
    </div>
    """
  end

  defp send_bulk_email([], _email_content), do: :ok

  defp send_bulk_email([email | rest], email_content) do
    body = %{
      "Messages" => [
        %{
          "From" => %{"Email" => "arjpriyanka2110@gmail.com"},
          "To" => [%{"Email" => email}],
          "Subject" => "Important Notification",
          "TextPart" => email_content
        }
      ]
    }

    headers = [
      {"Authorization", "Basic " <> Base.encode64("#{@mailjet_api_key}:#{@mailjet_secret_key}")},
      {"Content-Type", "application/json"}
    ]

    body_json = Jason.encode!(body)

    case Tesla.post("https://api.mailjet.com/v3.1/send", body_json, headers: headers) do
      {:ok, _response} -> send_bulk_email(rest, email_content)
      {:error, _reason} -> :error
    end
  end
end
