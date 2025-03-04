defmodule MySuperAppWeb.MatchSelectionLive do
  use Phoenix.LiveView
  alias HTTPoison

  @api_key System.get_env("API_KEY")
  @base_url "https://api.the-odds-api.com/v4/sports/"

  def mount(_params, session, socket) do
    user = MySuperApp.Accounts.get_user_by_session_token(session["user_token"])

    case get_tournaments() do
      {:ok, tournaments} ->
        socket = assign(socket, tournaments: tournaments, selected_tournament: nil, matches: [], selected_match: nil, user: user)
        {:ok, socket}

      {:error, _reason} ->
        {:ok, assign(socket, tournaments: [], selected_tournament: nil, matches: [], error: "Failed to load tournaments")}
    end
  end

  def render(assigns) do
    ~L"""
    <div class="h-screen flex flex-col px-4 lg:px-8">
    <h1 class="text-lg font-bold mb-4">Select Tournament</h1>
      <form phx-change="select_tournament">
        <select name="tournament" class="block w-full pl-10 text-sm text-gray-700">
          <option value="" disabled selected>Select a tournament</option>
          <%= for tournament <- @tournaments do %>
            <option value="<%= tournament["key"] %>"><%= tournament["title"] %></option>
          <% end %>
        </select>
      </form>

      <div class="flex mt-6">
        <div class="w-2/3">
          <%= if @selected_tournament do %>
            <h2 class="text-lg font-bold mb-4">Matches for <%= @selected_tournament %></h2>
            <ul class="list-none mb-0">
              <%= for match <- @matches do %>
                <li class="flex flex-col py-4">
                  <span class="text-gray-700 font-medium mb-2">
                    <%= match["home_team"] %> vs <%= match["away_team"] %>
                  </span>
                  <div class="flex space-x-2">
                    <%= for bookmaker <- match["bookmakers"], market <- bookmaker["markets"], outcome <- market["outcomes"] do %>
                      <%= if outcome["name"] == match["home_team"] do %>
                        <button
                          phx-click="select_outcome"
                          phx-value-match="<%= match["home_team"] %> vs <%= match["away_team"] %>"
                          phx-value-outcome="W1"
                          phx-value-price="<%= outcome["price"] %>"
                          class="bg-orange-500 hover:bg-orange-700 text-white font-bold py-2 px-4 rounded">
                          W1: <%= outcome["price"] %>
                        </button>
                      <% end %>
                    <% end %>

                    <%= for bookmaker <- match["bookmakers"], market <- bookmaker["markets"], outcome <- market["outcomes"] do %>
                      <%= if outcome["name"] == "Draw" or outcome["name"] == "X" do %>
                        <button
                          phx-click="select_outcome"
                          phx-value-match="<%= match["home_team"] %> vs <%= match["away_team"] %>"
                          phx-value-outcome="X"
                          phx-value-price="<%= outcome["price"] %>"
                          class="bg-orange-500 hover:bg-orange-700 text-white font-bold py-2 px-4 rounded">
                          X: <%= outcome["price"] %>
                        </button>
                      <% end %>
                    <% end %>

                    <%= for bookmaker <- match["bookmakers"], market <- bookmaker["markets"], outcome <- market["outcomes"] do %>
                      <%= if outcome["name"] == match["away_team"] do %>
                        <button
                          phx-click="select_outcome"
                          phx-value-match="<%= match["home_team"] %> vs <%= match["away_team"] %>"
                          phx-value-outcome="W2"
                          phx-value-price="<%= outcome["price"] %>"
                          class="bg-orange-500 hover:bg-orange-700 text-white font-bold py-2 px-4 rounded">
                          W2: <%= outcome["price"] %>
                        </button>
                      <% end %>
                    <% end %>
                  </div>
                </li>
              <% end %>
            </ul>
          <% else %>
            <p class="text-gray-600">Please select a tournament to see the matches.</p>
          <% end %>
        </div>

        <div class="w-1/3 bg-gray-100 p-4 rounded ml-4">
          <%= if @selected_match do %>
            <h3 class="text-lg font-bold mb-4">Place Your Bet</h3>
            <p class="mb-2"><strong>Match:</strong> <%= @selected_match %></p>
            <p class="mb-2"><strong>Outcome:</strong> <%= @selected_outcome %></p>
            <p class="mb-4"><strong>Price:</strong> <%= @selected_price %></p>
            <form phx-submit="place_bet">
              <label for="bet_amount" class="block mb-2">Bet Amount:</label>
              <input type="number" name="bet_amount" id="bet_amount" class="block w-full mb-4 p-2 border rounded" />
              <button type="submit" class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                Place Bet
              </button>
            </form>
          <% else %>
            <p class="text-gray-600">Select an outcome to place a bet.</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("select_tournament", %{"tournament" => tournament_key}, socket) do
    case get_matches(tournament_key) do
      {:ok, matches} ->
        socket = assign(socket, selected_tournament: tournament_key, matches: matches)
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, assign(socket, matches: [], error: "Failed to load matches")}
    end
  end

  def handle_event("select_outcome", %{"match" => match, "outcome" => outcome, "price" => price}, socket) do
    socket = assign(socket, selected_match: match, selected_outcome: outcome, selected_price: price)
    {:noreply, socket}
  end

  def handle_event("place_bet", %{"bet_amount" => bet_amount}, socket) do
    user_id = socket.assigns.user.id
    match = socket.assigns.selected_match
    outcome = socket.assigns.selected_outcome
    odds = socket.assigns.selected_price

    bet_params = %{
      user_id: user_id,
      match: match,
      outcome: outcome,
      bet_amount: Decimal.new(bet_amount),
      odds: Decimal.new(odds),
      result: "pending",
      placed_at: DateTime.utc_now()
    }

    case create_bet(bet_params) do
      {:ok, _bet} ->
        {:noreply, assign(socket, bet_success: "Bet placed successfully")}

      {:error, _changeset} ->
        {:noreply, assign(socket, bet_error: "Failed to place bet")}
    end
  end

  defp get_tournaments do
    url = "#{@base_url}/?apiKey=#{@api_key}"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def create_bet(attrs \\ %{}) do
    %MySuperApp.Bet{}
    |> MySuperApp.Bet.changeset(attrs)
    |> MySuperApp.Repo.insert()
  end

  defp get_matches(tournament_key) do
    url = "https://api.the-odds-api.com/v4/sports/#{tournament_key}/odds/"
    params = [
      apiKey: @api_key,
      regions: "us",
      bookmakers: "draftkings"
    ]
    query_string = URI.encode_query(params)
    full_url = "#{url}?#{query_string}"

    case HTTPoison.get(full_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, extract_matches(Jason.decode!(body))}

      {:ok, %HTTPoison.Response{status_code: 422, body: _body}} ->
        {:error, "Bad request"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Connection Error: #{reason}")
        {:error, reason}
    end
  end

  defp extract_matches(decoded_body) do
    Enum.map(decoded_body, fn data ->
      %{
        "home_team" => data["home_team"],
        "away_team" => data["away_team"],
        "bookmakers" => Enum.map(data["bookmakers"], fn bookmaker ->
          %{
            "title" => bookmaker["title"],
            "markets" => Enum.map(bookmaker["markets"], fn market ->
              %{
                "key" => market["key"],
                "outcomes" => Enum.map(market["outcomes"], fn outcome ->
                  %{
                    "name" => outcome["name"],
                    "price" => outcome["price"]
                  }
                end)
              }
            end)
          }
        end)
      }
    end)
  end
end
