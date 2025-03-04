defmodule MySuperAppWeb.PictureLive do
  use MySuperAppWeb, :live_view
  alias MySuperApp.Blog
  alias MySuperApp.Blog.Post

  def mount(_params, _session, socket) do
    if connected?(socket), do: MySuperAppWeb.Endpoint.subscribe("posts")

    posts = Blog.get_posts_with_pictures()
    posts_without_pictures = Blog.list_posts_without_pictures()
    changeset = Blog.change_post(%Post{})
    all_tags = Blog.list_tags()

    db_image_urls = Enum.map(posts, fn post -> post.url end)

    socket =
      socket
      |> assign(:form, changeset)
      |> assign(:posts_without_pictures, posts_without_pictures)
      |> assign(:selected_post_id, "")
      |> assign(:sort_order, "newest")
      |> assign(:query, "")
      |> assign(:all_tags, all_tags)
      |> assign(:show_modal , false)
      |> assign(:search_value, "")
      |> assign(:photo, nil)
      |> assign(:show_create_modal, false)
      |> assign(:all_images, db_image_urls)
      |> assign(:visible_images, Enum.take(db_image_urls, 4)) # Отображаем первые 4
      |> assign(:remaining_images, Enum.drop(db_image_urls, 4)) # Оставшиеся
      |> assign(:load_more, false) # Флаг для подгрузки
      |> allow_upload(:photos,
        accept: ~w(.png .jpeg .jpg),
        max_entries: 1,
        max_file_size: 10_000_000
      )

    {:ok, socket}
  end

  def handle_info(:tick, socket) do
    visible_images = socket.assigns.visible_images
    remaining_images = socket.assigns.remaining_images

    # Подгружаем одну строку (4 картинки)
    {new_images, remaining} = Enum.split(remaining_images, 4)
    updated_visible_images = visible_images ++ new_images

    socket =
      socket
      |> assign(:visible_images, updated_visible_images)
      |> assign(:remaining_images, remaining)

    # Останавливаем таймер, если картинки закончились
    if remaining != [] do
      {:noreply, socket, {:timer, :second}}
    else
      {:noreply, socket}
    end
  end

  def handle_event("load_more", _, socket) do
    remaining_images = socket.assigns.remaining_images
    visible_images = socket.assigns.visible_images

    {new_images, remaining} = Enum.split(remaining_images, 8)
    updated_visible_images = visible_images ++ new_images

    socket =
      socket
      |> assign(:visible_images, updated_visible_images)
      |> assign(:remaining_images, remaining)

    {:noreply, socket}
  end

  def render(assigns) do
    ~L"""
    <div id="slideshow">
      <div class="image-grid">
        <%= for row <- Enum.chunk_every(@visible_images, 4) do %>
          <div class="image-row">
            <%= for image_url <- row do %>
              <img src="<%= image_url %>" class="fade-in" />
            <% end %>
          </div>
        <% end %>
      </div>

      <%= if @remaining_images != [] do %>
        <button phx-click="load_more" class="load-more-button">Load More</button>
      <% end %>
    </div>

    <style>
      .image-grid {
        display: flex;
        flex-direction: column;
        align-items: center;
      }

      .image-row {
        display: flex;
        justify-content: center;
        margin-bottom: 10px;
      }

      .fade-in {
        width: 300px;
        height: 200px;
        margin: 5px;
        opacity: 0;
        animation: fadeIn 2s forwards;
      }

      .load-more-button {
        background-color: #4CAF50;
        border: none;
        color: white;
        padding: 10px 20px;
        text-align: center;
        text-decoration: none;
        display: inline-block;
        font-size: 16px;
        margin: 4px 2px;
        cursor: pointer;
      }

      @keyframes fadeIn {
        from {
          opacity: 0;
        }
        to {
          opacity: 1;
        }
      }
    </style>
    """
  end
end
