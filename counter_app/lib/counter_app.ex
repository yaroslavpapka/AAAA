defmodule CounterApp.Counter do
  use Agent

  # Start the Agent with an initial value of 0
  def start_link(_args) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  # Function to increment the counter
  def increment do
    Agent.update(__MODULE__, &(&1 + 1))
  end

  # Function to get the current counter value
  def get do
    Agent.get(__MODULE__, & &1)
  end
end
