defmodule MySuperAppWeb.HelloHTML do
  use MySuperAppWeb, :html

  def index(assigns) do
    ~H"""
    Hello <%= @message %>!
    """
  end
end
