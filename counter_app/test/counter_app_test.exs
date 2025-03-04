defmodule CounterAppTest do
  use ExUnit.Case
  doctest CounterApp

  test "greets the world" do
    assert CounterApp.hello() == :world
  end
end
