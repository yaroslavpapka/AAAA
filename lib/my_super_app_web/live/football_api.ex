defmodule MySuperApp.ApiFootball do
  use GenServer
  @api_key System.get_env("API_KEY")
  @base_url "https://v3.football.api-sports.io"

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(_) do
    :ets.new(:players_table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, self()}
  end

  def get_players(league_id \\ 39, season \\ 2021, page \\ 1) do
    url = "#{@base_url}/players?league=#{league_id}&season=#{season}&page=#{page}"
    headers = [{"x-apisports-key", @api_key}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Jason.decode!(body)
        players = response["response"]

        Enum.each(players, fn player ->
          :ets.insert(:players_table, {player["player"]["id"], player})
        end)

        {:ok, players}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def get_players_from_ets do
    case :ets.tab2list(:players_table) do
      [] -> {:error, :no_data}
      players -> {:ok, Enum.map(players, fn {_id, player} -> player end)}
    end
  end
end

defmodule MySuperAppWeb.FantasyLive do
  use MySuperAppWeb, :live_view
  alias MySuperApp.ApiFootball

  def mount(_params, _session, socket) do
    players = fetch_players()
    teams = extract_teams(players)
    positions = extract_positions(players)

    {:ok,
     assign(socket,
       all_players: players,
       players: players,
       selected_team: nil,
       selected_position: nil,
       selected_players: [],
       page: 1,
       teams: teams,
       positions: positions
     )}
  end

  defp fetch_players do
    case ApiFootball.get_players_from_ets() do
      {:ok, players} -> players
      {:error, :no_data} ->
        {:ok, players} = ApiFootball.get_players()
        players
    end
  end

  defp extract_teams(players) do
    Enum.uniq_by(players, fn player ->
      Enum.at(player["statistics"], 0)["team"]["name"]
    end)
  end

  defp extract_positions(players) do
    Enum.uniq_by(players, fn player ->
      Enum.at(player["statistics"], 0)["games"]["position"]
    end)
  end

  def handle_event("filter", %{"team" => team, "position" => position}, socket) do
    team = if team == "", do: socket.assigns.selected_team, else: team
    position = if position == "", do: socket.assigns.selected_position, else: position

    filtered_players =
      socket.assigns.all_players
      |> Enum.filter(fn player ->
        player_team = Enum.at(player["statistics"], 0)["team"]["name"]
        player_position = Enum.at(player["statistics"], 0)["games"]["position"]

        (team == nil || player_team == team) && (position == nil || player_position == position)
      end)

    {:noreply, assign(socket, players: filtered_players, selected_team: team, selected_position: position)}
  end

  def handle_event("select_player", %{"player_id" => player_id}, socket) do
    selected_players = socket.assigns.selected_players

    if length(selected_players) < 5 && !Enum.any?(selected_players, fn player -> player["player"]["id"] == String.to_integer(player_id) end) do
      new_selected_players = selected_players ++
        Enum.filter(socket.assigns.players, fn player ->
          player["player"]["id"] == String.to_integer(player_id)
        end)

      {:noreply, assign(socket, :selected_players, new_selected_players)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("load_more", _params, socket) do
    next_page = socket.assigns.page + 1
    {:ok, more_players} = ApiFootball.get_players(39, 2022, next_page)

    {:noreply, assign(socket, all_players: (socket.assigns.all_players ++ more_players), players: (socket.assigns.players ++ more_players), page: next_page)}
  end

  def render(assigns) do
    ~L"""
      <div>
        <h2 class="text-xl font-bold mb-4">Filter Players</h2>
        <form phx-change="filter" class="mb-4">
          <div class="flex justify-between">
            <select name="team" class="mr-2 px-3 py-2 border rounded-md">
              <option value="">All Teams</option>
              <%= for team <- @teams do %>
                <option value="<%= Enum.at(team["statistics"], 0)["team"]["name"] %>"
                <%= if @selected_team == Enum.at(team["statistics"], 0)["team"]["name"], do: "selected" %>>
                  <%= Enum.at(team["statistics"], 0)["team"]["name"] %>
                </option>
              <% end %>
            </select>

            <select name="position" class="ml-2 px-3 py-2 border rounded-md">
              <option value="">All Positions</option>
              <%= for position <- @positions do %>
                <option value="<%= Enum.at(position["statistics"], 0)["games"]["position"] %>"
                <%= if @selected_position == Enum.at(position["statistics"], 0)["games"]["position"], do: "selected" %>>
                  <%= Enum.at(position["statistics"], 0)["games"]["position"] %>
                </option>
              <% end %>
            </select>
          </div>
        </form>

        <h2 class="text-xl font-bold mb-4">Players</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          <%= for player <- @players do %>
            <% player_id = player["player"]["id"] %>
            <% is_selected = Enum.any?(@selected_players, fn p -> p["player"]["id"] == player_id end) %>

            <div class="flex flex-col items-center p-4 border rounded-lg shadow-sm bg-white">
              <img src="<%= player["player"]["photo"] %>" alt="<%= player["player"]["name"] %>" class="w-20 h-20 rounded-full mb-2"/>
              <p class="text-center font-medium"><%= player["player"]["name"] %></p>
              <p class="text-center text-sm text-gray-500">
                <%= Enum.at(player["statistics"], 0)["games"]["position"] %> -
                <%= Enum.at(player["statistics"], 0)["team"]["name"] %>
              </p>
              <button
              phx-click="select_player"
              phx-value-player_id="<%= player_id %>"
              class="mt-2 px-3 py-1 rounded-md <%= if is_selected or length(@selected_players) >= 5 do %>bg-gray-400 text-white cursor-not-allowed<% else %>bg-blue-500 text-white hover:bg-blue-600<% end %>"
              <%= if is_selected or length(@selected_players) >= 5 do %>disabled<% end %>>
              <%= if is_selected, do: "Selected", else: "Select" %>
            </button>
            </div>
          <% end %>
        </div>
        <div class="mt-6 text-center">
          <button phx-click="load_more" class="px-4 py-2 bg-indigo-500 text-white rounded-md hover:bg-indigo-600">
            Load More Players
          </button>
        </div>
      </div>

      <div>
        <h2 class="text-xl font-bold mb-4">Selected Players</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          <%= for player <- @selected_players do %>
            <div class="flex flex-col items-center p-4 border rounded-lg shadow-sm bg-white">
              <img src="<%= player["player"]["photo"] %>" alt="<%= player["player"]["name"] %>" class="w-20 h-20 rounded-full mb-2"/>
              <p class="text-center font-medium"><%= player["player"]["name"] %></p>
              <p class="text-center text-sm text-gray-500">
                <%= Enum.at(player["statistics"], 0)["games"]["position"] %> -
                <%= Enum.at(player["statistics"], 0)["team"]["name"] %>
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
