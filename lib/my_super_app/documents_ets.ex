defmodule MySuperApp.DocumentRequests do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:document_requests, [:set, :public, :named_table])
    {:ok, %{}}
  end

  def add_request(request_id, user_id, link) do
    :ets.insert(:document_requests, {request_id, user_id, link, :pending})
  end

  def delete_request(request_id) do
  :ets.delete(:document_requests, request_id)
  end

  def get_all_requests() do
    :ets.tab2list(:document_requests)
  end

  def get_requests_by_user(user_id) do
    :ets.match_object(:document_requests, {:_, user_id, :_, :_})
  end

  def update_request_status(request_id, new_status) do
    case :ets.lookup(:document_requests, request_id) do
      [{^request_id, user_id, link, _old_status}] ->
        :ets.insert(:document_requests, {request_id, user_id, link, new_status})
        {:ok, new_status}

      _ ->
        {:error, :not_found}
    end
  end

  def subscribe do
    Phoenix.PubSub.subscribe(MySuperApp.PubSub, "photos")
  end
end
