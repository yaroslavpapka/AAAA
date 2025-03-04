defmodule MySuperAppWeb.HomeLive do
  use MySuperAppWeb, :surface_live_view

  def render(assigns) do
    ~F"""
    <div class="bg-gray-100 min-h-screen flex items-center justify-center">
      <div class="max-w-md w-full p-6 bg-white shadow-lg rounded-lg">
        <h1 class="text-3xl font-bold text-center mb-4">Welcome to MySuperApp!</h1> <p class="text-lg text-center mb-6">Your go-to platform for all things awesome.</p> <div class="space-y-4">
          <a
            href="/users"
            class="block w-full bg-green-500 hover:bg-green-600 text-white text-center py-3 px-4 rounded-lg transition duration-200"
          >Users Page</a> <a
            href="/form"
            class="block w-full bg-green-500 hover:bg-green-600 text-white text-center py-3 px-4 rounded-lg transition duration-200"
          >Add some user</a> <a
            href="/accordion"
            class="block w-full bg-green-500 hover:bg-green-600 text-white text-center py-3 px-4 rounded-lg transition duration-200"
          >Accordion Page</a> <a
            href="/tabs"
            class="block w-full bg-green-500 hover:bg-green-600 text-white text-center py-3 px-4 rounded-lg transition duration-200"
          >Tabs Page</a> <a
            href="/menu"
            class="block w-full bg-green-500 hover:bg-green-600 text-white text-center py-3 px-4 rounded-lg transition duration-200"
          >Menu Page</a>
        </div>
      </div>
    </div>
    """
  end
end
