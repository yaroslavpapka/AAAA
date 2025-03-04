defmodule MySuperAppWeb.TagsLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.Blog
  alias MySuperApp.Tag

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :tags, Blog.list_tags()) |> assign_new_tag()}
  end

  @impl true
  def handle_event("save", %{"tag" => tag_params}, socket) do
    case socket.assigns[:editing_tag] do
      true ->
        Blog.update_tag(socket.assigns.tag, tag_params)
        |> handle_tag_response(socket, "Tag updated successfully")

      false ->
        Blog.create_tag(tag_params)
        |> handle_tag_response(socket, "Tag created successfully")
    end
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    tag = Blog.get_tag!(id)
    {:noreply, assign(socket, :tag, tag) |> assign(:editing_tag, true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tag = Blog.get_tag!(id)
    {:ok, _} = Blog.delete_tag(tag)
    {:noreply, assign(socket, :tags, Blog.list_tags())}
  end

  defp handle_tag_response({:ok, _tag}, socket, message) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:tags, Blog.list_tags())
     |> assign_new_tag()}
  end

  defp handle_tag_response({:error, changeset}, socket, _message) do
    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp assign_new_tag(socket) do
    socket
    |> assign(:tag, %Tag{})
    |> assign(:editing_tag, false)
    |> assign(:changeset, Blog.change_tag(%Tag{}))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 min-h-screen">
      <div class="bg-white shadow-lg rounded-lg p-6">
        <h1 class="text-4xl font-bold text-gray-800 mb-8">Tags Management</h1>

        <form phx-submit="save" class="space-y-6">
          <div>
            <label class="block text-lg font-medium text-gray-700">Name</label>
            <input
              type="text"
              name="tag[name]"
              value={@tag.name || ""}
              class="mt-2 block w-full shadow-sm sm:text-lg border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          <div class="flex justify-end">
            <button
              type="submit"
              class="bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-3 rounded-lg shadow-lg transition-all duration-200"
            >
              <%= if @editing_tag, do: "Update", else: "Create" %> Tag
            </button>
          </div>
        </form>
      </div>

      <div class="mt-12">
        <div class="mt-8 bg-white shadow-lg rounded-lg">
          <ul class="divide-y divide-gray-200">
            <%= for tag <- @tags do %>
              <li class="flex items-center justify-between py-6 px-8 hover:bg-gray-50 transition-all duration-200">
                <div>
                  <strong class="text-xl text-gray-800"><%= tag.name %></strong>
                </div>

                <div class="flex space-x-6">
                  <button
                    phx-click="edit"
                    phx-value-id={tag.id}
                    class="text-blue-600 hover:text-blue-800 font-medium transition-all duration-200"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12h2m0 0h2m-2 0V7a5 5 0 10-10 0v5m12 0a2 2 0 110 4h-1m-6 0H9a2 2 0 110-4h1m0 0H7a2 2 0 010-4h1m0 0H7a5 5 0 1110 0v5z" />
                    </svg>
                    Edit
                  </button>
                  <button
                    phx-click="delete"
                    phx-value-id={tag.id}
                    class="text-red-600 hover:text-red-800 font-medium transition-all duration-200"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12h2m0 0h2m-2 0V7a5 5 0 10-10 0v5m12 0a2 2 0 110 4h-1m-6 0H9a2 2 0 110-4h1m0 0H7a2 2 0 010-4h1m0 0H7a5 5 0 1110 0v5z" />
                    </svg>
                    Delete
                  </button>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
