defmodule MySuperApp.WithdrawalRequests do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:withdrawal_requests, [:set, :public, :named_table])
    {:ok, %{}}
  end

  def add_request(request_id, user_id, amount, usdt_wallet) do
    :ets.insert(:withdrawal_requests, {request_id, user_id, amount, usdt_wallet, :pending})
  end

  def get_all_requests() do
    :ets.tab2list(:withdrawal_requests)
  end

  def get_requests_by_user(user_id) do
    :ets.match_object(:withdrawal_requests, {:_, user_id, :_, :_, :_})
  end

  def update_request_status(request_id, new_status) do
    case :ets.lookup(:withdrawal_requests, request_id) do
      [{^request_id, user_id, amount, usdt_wallet, _old_status}] ->
        :ets.insert(:withdrawal_requests, {request_id, user_id, amount, usdt_wallet, new_status})
        {:ok, new_status}

      _ ->
        {:error, :not_found}
    end
  end
end
