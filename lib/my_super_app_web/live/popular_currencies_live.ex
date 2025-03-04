defmodule MySuperAppWeb.PopularCurrenciesLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.Crypto

  def mount(_params, _session, socket) do
    if connected?(socket) do
      send(self(), :load_popular_currencies)
    end

    {:ok, assign(socket, popular_currencies: [], search_query: "")}
  end

  def handle_info(:load_popular_currencies, socket) do
    popular_currencies = Crypto.get_popular_currencies()
    {:noreply, assign(socket, popular_currencies: popular_currencies)}
  end

  def handle_info(:update_prices, socket) do
    updated_currencies =
      Enum.map(socket.assigns.popular_currencies, fn currency ->
        new_price = Crypto.get_price(currency["symbol"])
        Map.put(currency, "price", new_price)
      end)

    {:noreply, assign(socket, popular_currencies: updated_currencies)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    search_results = Crypto.search_currencies(query)
    {:noreply, assign(socket, popular_currencies: search_results, search_query: query)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-3xl mx-auto bg-white border border-gray-200 rounded-lg shadow-md">
      <h1 class="text-2xl font-semibold text-gray-900 mb-6">Popular Currencies</h1>

      <form phx-change="search" class="mb-6">
        <input type="text" name="query" value={@search_query} placeholder="Search by name or code" class="block w-full p-2 border border-gray-300 rounded-md shadow-sm text-gray-900"/>
      </form>

      <ul class="divide-y divide-gray-200">
        <%= for currency <- @popular_currencies do %>
          <li class="py-4">
            <div class="flex justify-between items-center">
              <div>
                <h2 class="text-lg font-medium text-gray-800"><%= currency["symbol"] %></h2>
                <p class="text-sm text-gray-500">Price:
                  <span class={if String.to_float(currency["price_change"]) >= 0, do: "text-green-500", else: "text-red-500"}>
                    <%= currency["price"] %>
                  </span>
                </p>
                <p class="text-sm text-gray-500">Volume: <%= currency["volume"] %></p>
              </div>
              <a href={"/currencies/#{currency["symbol"]}"} class="text-blue-500 hover:text-blue-700">View Details</a>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
