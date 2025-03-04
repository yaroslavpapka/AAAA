defmodule MySuperAppWeb.DepositLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])
    {:ok, balance} = MySuperApp.Payment.get_balance("0xD1E7a9b10971c2238Bd141B938638f0B4ed77952") #just for test

    Process.send_after(self(), :update_balance, 2000)

    {:ok, assign(socket, user: user, amount: "", changeset: nil, balance: balance)}
  end

  @impl true
  def handle_info(:update_balance, socket) do
    {:ok, balance} = MySuperApp.Payment.get_balance("0xD1E7a9b10971c2238Bd141B938638f0B4ed77952") #just for test

    Process.send_after(self(), :update_balance, 2000)
    {:noreply, assign(socket, balance: balance)}
  end

  @impl true
  def handle_event("deposit", %{"amount" => amount}, socket) do
    case Decimal.parse(amount) do
      :error ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid amount format.")
         |> assign(changeset: nil)}

      {decimal_amount, _} ->
        updated_balance = Decimal.add(socket.assigns.user.balance, decimal_amount)

        case Accounts.update_user_balance(socket.assigns.user, updated_balance) do
          {:ok, user} ->
            {:noreply,
             socket
             |> put_flash(:info, "Deposit successful!")
             |> assign(user: user, amount: "", changeset: nil)
             |> push_event("page_reload", %{})}

          {:error, changeset} ->
            {:noreply, assign(socket, changeset: changeset)}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="max-w-2xl mx-auto py-10" phx-hook="PageReloader">
      <h2 class="text-2xl font-bold mb-6">Deposit Funds</h2>

      <%= if @changeset do %>
        <div class="bg-red-100 text-red-700 border border-red-300 p-4 rounded mb-4">
          <%= for {field, msg} <- @changeset.errors do %>
            <p><%= field %> <%= msg %></p>
          <% end %>
        </div>
      <% end %>

      <form id="deposit-form" phx-submit="deposit" class="space-y-4">
        <div>
          <label for="amount" class="block text-sm font-medium text-gray-700">Amount</label>
          <input type="number" name="amount" id="amount" value={@amount}
                 min="1" step="any" required class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"/>
        </div>

        <button type="button" onclick="depositWithMetaMask()" class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
          Deposit with MetaMask
        </button>
      </form>

      <p class="mt-6 text-lg font-semibold">Current Balance: <%= @balance %></p>
    </div>

    <script>
      async function depositWithMetaMask() {
        if (typeof window.ethereum === 'undefined') {
          alert("MetaMask is not installed. Please install it to proceed.");
          return;
        }

        const amount = document.getElementById("amount").value;
        if (!amount) {
          alert("Please enter an amount.");
          return;
        }

        try {
          await window.ethereum.request({ method: 'eth_requestAccounts' });

          const accounts = await window.ethereum.request({ method: 'eth_accounts' });
          const from = accounts[0];
          const value = (parseFloat(amount) * 1e18).toString(16);

          const txHash = await window.ethereum.request({
            method: 'eth_sendTransaction',
            params: [{
              from: from,
              to: "0xD1E7a9b10971c2238Bd141B938638f0B4ed77952439671",
              value: '0x' + value,
            }],
          });

          alert("Transaction sent! Transaction hash: " + txHash);

        } catch (error) {
          console.error(error);
          alert("Transaction failed: " + error.message);
        }
      }
    </script>
    """
  end
end
