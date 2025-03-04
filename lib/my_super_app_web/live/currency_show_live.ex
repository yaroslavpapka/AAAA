defmodule MySuperAppWeb.CurrencyShowLive do
  use Phoenix.LiveView
  alias MySuperApp.Crypto

  def mount(%{"symbol" => symbol}, _session, socket) do
    if connected?(socket) do
      send(self(), :load_currency_info)
      :timer.send_interval(1000, self(), :update_currency_info)
    end

    {:ok, assign(socket, symbol: symbol, currency_info: %{})}
  end

  def handle_info(:load_currency_info, socket) do
    currency_info = Crypto.get_currency_info(socket.assigns.symbol)
    {:noreply, assign(socket, currency_info: currency_info)}
  end

  def handle_info(:update_currency_info, socket) do
    updated_info = Crypto.get_currency_info(socket.assigns.symbol)
    {:noreply, assign(socket, currency_info: updated_info)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-2xl mx-auto bg-white border border-gray-200 rounded-lg shadow-md">
      <h1 class="text-2xl font-semibold text-gray-900 mb-6">Currency Details: <%= @symbol %></h1>

      <div class="mb-6">
        <div class="text-lg font-medium text-gray-800">
          <strong>Price:</strong>
          <span class={price_change_class(@currency_info["priceChangePercent"])}>
            <%= @currency_info["lastPrice"] %>
          </span>
        </div>
        <div class="text-lg font-medium text-gray-800">
          <strong>Volume:</strong> <%= @currency_info["volume"] %>
        </div>
        <div class="text-lg font-medium text-gray-800">
          <strong>Price Change (24h):</strong>
          <span class={price_change_class(@currency_info["priceChangePercent"])}>
            <%= @currency_info["priceChangePercent"] || "" %>%
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp price_change_class(price_change_percent) when is_binary(price_change_percent) do
    case String.to_float(price_change_percent) do
      percent when percent >= 0 -> "text-green-500"
      _ -> "text-red-500"
    end
  end
  defp price_change_class(nil), do: "text-gray-500"
end
