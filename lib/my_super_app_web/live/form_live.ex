defmodule MySuperAppWeb.FormLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.Blog
  alias MySuperApp.Blog.Post
  alias MySuperApp.User
  import Ecto.Query

  @posts_per_page 10

  def mount(_params, _session, socket) do
    posts = list_paginated_posts(0, :inserted_at, :asc)

    socket =
      socket
      |> assign(:page, 0)
      |> assign(:sort_by, :inserted_at)
      |> assign(:sort_order, :asc)
      |> stream(:posts, posts)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Posts Table</h1>
    <table id="posts-table">
      <thead>
        <tr>
          <th><a href="#" phx-click="sort" phx-value-column="id">ID</a></th>
          <th><a href="#" phx-click="sort" phx-value-column="title">Title</a></th>
          <th><a href="#" phx-click="sort" phx-value-column="inserted_at">Created at</a></th>
          <th><a href="#" phx-click="sort" phx-value-column="user">Author</a></th>
          <th><a href="#">Tags</a></th>
          <th><a href="#" phx-click="sort" phx-value-column="published">Published</a></th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody id="posts" phx-update="stream">
        <tr :for={{post_id, post} <- @streams.posts} id={post_id}>
          <td><%= post.id %></td>
          <td><%= post.title %></td>
          <td><%= post.inserted_at |> Timex.format!("{Mshort} {D}, {YYYY}, {h12}:{m}:{s}") %></td>
          <td><%= post.user.username %></td>
          <td><%= Enum.join(Enum.map(post.tags, & &1.name), ", ") %></td>
          <td><%= if post.published, do: "✔️", else: "❌" %></td>
          <td>
            <button phx-click="edit" phx-value-id={post_id}>Edit</button>
            <button phx-click="delete" phx-value-id={post_id}>Delete</button>
          </td>
        </tr>
      </tbody>
    </table>
    <button phx-click="load_more">Load more</button>
    """
  end

  def handle_event("sort", %{"column" => column}, socket) do
    sort_order =
      if socket.assigns.sort_by == String.to_existing_atom(column) do
        if socket.assigns.sort_order == :asc, do: :desc, else: :asc
      else
        :asc
      end

    sort_by = String.to_existing_atom(column)
    page = 0

    # Получаем отсортированные посты
    posts = list_paginated_posts(page, sort_by, sort_order)

    # Удаляем все текущие элементы из стрима
    socket =
      Enum.reduce(socket.assigns.streams.posts, fn {dom_id, _post}, acc_socket ->
        [_, post_id] = String.split(dom_id, "-")
        post_id = String.to_integer(post_id)
        post = MySuperApp.Blog.get_post!(post_id)

        # Удаляем пост по ID из стрима
        stream_delete(acc_socket, :posts, post)
      end)

    # Добавляем отсортированные посты обратно в стрим
    socket =
      socket
      |> assign(:sort_by, sort_by)
      |> assign(:sort_order, sort_order)
      |> assign(:page, page)
      |> stream(:posts, posts)

    {:noreply, socket}
  end
  def handle_event("load_more", _params, socket) do
    page = socket.assigns.page + 1
    posts = list_paginated_posts(page, socket.assigns.sort_by, socket.assigns.sort_order)

    socket =
      socket
      |> assign(:page, page)
      |> stream(:posts, posts)

    {:noreply, socket}
  end

  defp list_paginated_posts(page, sort_by, sort_order) do
    offset = page * @posts_per_page

    from(p in Post,
      limit: ^@posts_per_page,
      offset: ^offset,
      order_by: [{^sort_order, ^sort_by}],
      preload: [:user, :tags]
    )
    |> MySuperApp.Repo.all()
  end

  def handle_event("delete", %{"id" => id}, socket) do
    [_, post_id] = String.split(id, "-")
    post_id = String.to_integer(post_id)
    post = MySuperApp.Blog.get_post!(post_id)
    socket = stream_delete(socket, :posts, post)
    {:ok, _} = MySuperApp.Blog.delete_post(post)
    {:noreply, socket}
  end

end
