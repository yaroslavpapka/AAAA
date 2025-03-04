defmodule MySuperAppWeb.TransactionLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.Payment

  def mount(_params, _session, socket) do
    {:ok, assign(socket, from_address: "", to_address: "", amount: "", balance: nil, transaction_hash: nil, error: nil)}
  end

  def handle_event("check_balance", %{"address" => address}, socket) do
    case Payment.get_balance(address) do
      {:ok, balance} ->
        {:noreply, assign(socket, balance: balance, error: nil)}

      {:error, error_message} ->
        {:noreply, assign(socket, error: error_message)}
    end
  end

  def handle_event("send_transaction", %{"transaction" => %{"from" => from, "to" => to, "amount" => amount_str}}, socket) do
    case Float.parse(amount_str) do
      {amount, ""} ->
        case MySuperApp.Payment.send_transaction(from, to, amount, "<private_key>") do
          {:ok, tx_hash} ->
            {:noreply, assign(socket, transaction_hash: tx_hash, error: nil)}

          {:error, reason} ->
            {:noreply, assign(socket, error: reason)}
        end

      :error ->
        {:noreply, assign(socket, error: "Invalid amount format")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-8 bg-white shadow-lg rounded-lg">
      <h1 class="text-3xl font-bold text-gray-800 mb-6 text-center">Ethereum Transaction</h1>

      <form phx-submit="check_balance" class="mb-6 bg-gray-100 p-6 rounded-lg shadow-md">
        <label for="address" class="block text-xl font-semibold text-gray-700 mb-2">Check Balance</label>
        <input type="text" name="address" placeholder="Enter Ethereum address"
               class="border border-gray-300 p-3 w-full rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400 mb-4"/>
        <button type="submit" class="w-full bg-blue-600 text-white font-semibold py-2 rounded-lg shadow-md hover:bg-blue-700 focus:ring-2 focus:ring-blue-500">
          Check Balance
        </button>
      </form>

      <%= if @balance do %>
        <div class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg text-center">
          <strong class="text-blue-700 text-lg">Balance:</strong>
          <span class="text-blue-700 text-lg font-semibold"><%= @balance %> ETH</span>
        </div>
      <% end %>

      <form phx-submit="send_transaction" class="bg-gray-100 p-6 rounded-lg shadow-md">
        <h2 class="text-2xl font-bold text-gray-700 mb-4">Send Transaction</h2>

        <div class="mb-4">
          <label for="from" class="block text-lg font-medium text-gray-600">From Address:</label>
          <input type="text" name="transaction[from]" placeholder="Sender address"
                 class="border border-gray-300 p-3 w-full rounded-lg focus:outline-none focus:ring-2 focus:ring-green-400"/>
        </div>

        <div class="mb-4">
          <label for="to" class="block text-lg font-medium text-gray-600">To Address:</label>
          <input type="text" name="transaction[to]" placeholder="Recipient address"
                 class="border border-gray-300 p-3 w-full rounded-lg focus:outline-none focus:ring-2 focus:ring-green-400"/>
        </div>

        <div class="mb-4">
          <label for="amount" class="block text-lg font-medium text-gray-600">Amount (ETH):</label>
          <input type="text" name="transaction[amount]" placeholder="Amount in ETH"
                 class="border border-gray-300 p-3 w-full rounded-lg focus:outline-none focus:ring-2 focus:ring-green-400"/>
        </div>

        <button type="submit" class="w-full bg-green-600 text-white font-semibold py-2 rounded-lg shadow-md hover:bg-green-700 focus:ring-2 focus:ring-green-500">
          Send Transaction
        </button>
      </form>

      <%= if @transaction_hash do %>
        <div class="mt-6 p-4 bg-green-50 border border-green-200 rounded-lg text-center">
          <strong class="text-green-700 text-lg">Transaction Hash:</strong>
          <span class="text-green-700 text-lg font-semibold"><%= @transaction_hash %></span>
        </div>
      <% end %>

      <%= if @error do %>
        <div class="mt-6 p-4 bg-red-50 border border-red-200 rounded-lg text-center">
          <strong class="text-red-700 text-lg">Error:</strong>
          <span class="text-red-700 text-lg font-semibold"><%= @error %></span>
        </div>
      <% end %>
    </div>
    """
  end

end
