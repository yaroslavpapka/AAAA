defmodule MySuperAppWeb.BinanceAPI do
  @moduledoc """
  Module for interacting with the Binance API to fetch cryptocurrency price and volume data.
  """

  @api_endpoint "https://api.binance.com/api/v3/ticker/price"
  @volume_endpoint "https://api.binance.com/api/v3/ticker/24hr"

  def get_current_price(symbol) do
    url = "#{@api_endpoint}?symbol=#{symbol}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode()
        |> case do
          {:ok, %{"price" => price}} -> {:ok, Decimal.new(price)}
          error -> {:error, error}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def get_24hr_volume(symbol) do
    url = "#{@volume_endpoint}?symbol=#{symbol}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode()
        |> case do
          {:ok, %{"volume" => volume}} -> {:ok, Decimal.new(volume)}
          error -> {:error, error}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
