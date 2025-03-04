defmodule MySuperApp.OddsAPI do
  @api_key System.get_env("API_KEY")
  @base_url "https://api.the-odds-api.com/v3"

  def get_tournaments do
    url = "#{@base_url}/sports/?apiKey=#{@api_key}"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def get_odds(sport_key) do
    url = "#{@base_url}/odds/?apiKey=#{@api_key}&sport=#{sport_key}&region=us&mkt=h2h"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
