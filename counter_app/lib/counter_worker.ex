defmodule CounterApp.CounterWorker do
  use GenServer

  # Start the GenServer
  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    schedule_increment()  # Schedule the first increment
    {:ok, %{}}
  end

  # Callback to handle scheduled work
  @impl true
  def handle_info(:increment, state) do
    CounterApp.Counter.increment()  # Increment the counter
    IO.puts("Counter updated: #{CounterApp.Counter.get()}")

    schedule_increment()  # Schedule the next increment
    {:noreply, state}
  end

  # Helper function to schedule the increment every second
  defp schedule_increment do
    Process.send_after(self(), :increment, 1_000)  # 1,000 ms (1 second)
  end
end

defmodule CounterApp.CounterTask do
  def start do
    Task.start(fn -> log_counter() end)
  end

  defp log_counter do
    IO.puts("Task logs counter: #{CounterApp.Counter.get()}")
    Process.sleep(3_000)  # Wait for 3 seconds
    log_counter()         # Repeat logging
  end
end
