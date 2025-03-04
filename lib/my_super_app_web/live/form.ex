defmodule MySuperAppWeb.Form1Live do
  use MySuperAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(:form_data, %{
       name: "",
       email: "",
       phone: "",
       company: "",
       services: [],
       budget: nil,
       sections: []
     })}
  end

  def handle_event("next_step", _params, socket) do
    {:noreply, assign(socket, :step, socket.assigns.step + 1)}
  end

  def handle_event("previous_step", _params, socket) do
    {:noreply, assign(socket, :step, socket.assigns.step - 1)}
  end

  def handle_event("update_form", %{"field" => field, "value" => value}, socket) do
    updated_form_data = Map.put(socket.assigns.form_data, String.to_atom(field), value)
    {:noreply, assign(socket, :form_data, updated_form_data)}
  end

  def render(assigns) do
    ~H"""
    <form id="form" phx-hook="Form" class="flex justify-center items-center h-screen bg-gray-100">
      <div class="bg-white rounded-lg shadow-xl w-[500px] px-8 py-6">
        <!-- Header with Steps -->
        <div class="flex justify-between items-center mb-8">
          <%= for {section, idx} <- Enum.with_index(@sections) do %>
            <div class="flex items-center space-x-2">
              <div class="flex justify-center items-center h-8 w-8 rounded-full text-sm font-medium text-white bg-blue-600">
                <%= idx + 1 %>
              </div>
              <%= if idx < length(@sections) - 1 do %>
                <div class="h-[2px] w-8 bg-gray-300"></div>
              <% end %>
            </div>
          <% end %>
        </div>

        <!-- Form Content -->
        <div id="section-1" class="">
          <h2 class="text-xl font-semibold mb-2">Contact Details</h2>
          <p class="text-gray-500 text-sm mb-6">Please provide your personal details below.</p>
          <div class="space-y-4">
            <!-- Name -->
            <div class="relative">
              <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
              <input
                type="text"
                id="name"
                name="name"
                class="mt-1 block w-full px-4 py-2 border rounded-lg shadow-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder="John Doe"
                required
              />
              <svg class="absolute top-3 right-3 w-5 h-5 text-gray-400">
                <use href="/images/form_sprite.svg#Name"></use>
              </svg>
            </div>
            <!-- Email -->
            <div class="relative">
              <label for="email" class="block text-sm font-medium text-gray-700">Email</label>
              <input
                type="email"
                id="email"
                name="email"
                class="mt-1 block w-full px-4 py-2 border rounded-lg shadow-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder="example@example.com"
                required
              />
              <svg class="absolute top-3 right-3 w-5 h-5 text-gray-400">
                <use href="/images/form_sprite.svg#Email"></use>
              </svg>
            </div>
          </div>
        </div>

        <!-- Navigation Buttons -->
        <div class="mt-8 flex justify-between">
          <button
            class="px-4 py-2 rounded-lg border border-blue-600 text-blue-600 hover:bg-blue-50 hidden"
            id="prev-btn"
            type="button"
            phx-click="handle_step_backward_animation"
          >
            Previous
          </button>
          <button
            class="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700"
            id="next-btn"
            type="button"
            phx-click="handle_step_forward_animation"
          >
            Next
          </button>
        </div>
      </div>
    </form>
    """
  end

end
