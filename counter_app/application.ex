defmodule CounterApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      CounterApp.CounterSupervisor,
      %{
        id: CounterApp.CounterTask,
        start: {CounterApp.CounterTask, :start, []}
      }
    ]

    opts = [strategy: :one_for_one, name: CounterApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
