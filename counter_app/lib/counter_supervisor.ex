defmodule CounterApp.CounterSupervisor do
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      {CounterApp.Counter, []},            # Start the Counter Agent first
      {CounterApp.CounterWorker, []}       # Then start the CounterWorker GenServer
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
