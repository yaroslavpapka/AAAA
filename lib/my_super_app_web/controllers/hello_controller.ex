defmodule MySuperAppWeb.HelloController do
  use MySuperAppWeb, :controller

  def index(conn, %{"message" => message}) do
    render(conn, :index, message: message)
  end
end
