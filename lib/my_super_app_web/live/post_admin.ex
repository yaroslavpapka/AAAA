defmodule MySuperAppWeb.PostAdmin do
  use MySuperAppWeb, :live_view
  alias MySuperApp.{Blog, Accounts}
  require Logger

  def mount(_params, session, socket) do
    user = MySuperApp.Accounts.get_user_by_session_token(session["user_token"])
    posts = Blog.list_posts()
    all_tags = Blog.list_tags()
    all_users = Accounts.get_all_users()

    {:ok,
     assign(socket,
       sort: %{column: "title", direction: "ASC"},
       posts: Blog.paginate_posts(posts, 1, 10),
       changeset: Blog.Post.changeset(%Blog.Post{}, %{}),
       selected: nil,
       id: nil,
       filter: nil,
       all_tags: all_tags,
       tags: [],
       selected_post: %{title: "", body: ""},
       tag_input: nil,
       show_create_modal: false,
       show_edit_modal: false,
       show_post_modal: false,
       show_delete_modal: false,
       page: 1,
       per_page: 10,
       total_pages: div(length(posts) + 9, 10),
       all_users: all_users,
       selected_user_id: nil,
       selected_tag_id: nil,
       search_term: "",
       user_id: user.id,
       uploaded_image_url: nil
     )
     |> allow_upload(:photos,
       accept: ~w(.png .jpeg .jpg),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  def handle_event("update_tag_input", %{"value" => value}, socket) do
    {:noreply, assign(socket, tag_input: value)}
  end

  def handle_event("add_tag", _, socket) do
    new_tag = socket.assigns.tag_input

    if Enum.any?(socket.assigns.tags, fn tag -> tag == new_tag end) do
      {:noreply, socket}
    else
      updated_tags = [new_tag | socket.assigns.tags]
      {:noreply, assign(socket, tags: updated_tags)}
    end
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    tags = socket.assigns.tags || []
    {:noreply, assign(socket, tags: Enum.reject(tags, &(&1 == tag)))}
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  def handle_event("delete_picture", _, socket) do
    post = socket.assigns.selected_post

    case MySuperApp.Blog.delete_picture(post) do
      {:ok, _} ->
        {:noreply, assign(socket, :selected_post, %{post | picture: nil})}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to delete picture: #{reason}")}
    end
  end

  def handle_event("validate", %{"body" => body, "title" => title}, socket) do
    photos_upload_errors =
      Enum.map(socket.assigns.uploads.photos.entries, fn entry ->
        if entry.valid?, do: nil, else: {:error, entry.client_name}
      end)
      |> Enum.reject(&is_nil/1)

    socket =
      if Enum.empty?(photos_upload_errors) do
       socket=
        socket
        |> assign(:photos_upload_errors, photos_upload_errors)
        |> assign(:selected_post, %{socket.assigns.selected_post | title: title, body: body})

      else
        socket=
         socket
         |> assign(:photos_upload_errors, photos_upload_errors)
         |> assign(:selected_post, %{socket.assigns.selected_post | title: title, body: body})
      end

    {:noreply, socket}
  end

  def handle_event("filter_posts", %{"search" => search_term}, socket) do
    posts =
      if socket.assigns.filter["user"] do
        Blog.list_posts(user_id: socket.assigns.filter["user"])
      else
        Blog.list_posts()
      end
      |> Enum.filter(fn post ->
        String.contains?(String.downcase(post.title), String.downcase(search_term))
      end)
      |> sort_posts(socket.assigns.sort)

    total_pages = div(length(posts) + socket.assigns.per_page - 1, socket.assigns.per_page)

    paginated_posts = Blog.paginate_posts(posts, socket.assigns.page, socket.assigns.per_page)

    {:noreply,
     assign(socket,
       search_term: search_term,
       posts: paginated_posts,
       total_pages: total_pages
     )}
  end

  def handle_event("published", %{"id" => post_id}, socket) do
    post = MySuperApp.Blog.get_post!(post_id)

    case MySuperApp.Blog.toggle_publish_post(post) do
      {:ok, _post} ->
        posts =
          MySuperApp.Blog.list_posts()
          |> sort_posts(socket.assigns.sort)
          |> Blog.paginate_posts(socket.assigns.page, socket.assigns.per_page)

        {:noreply, assign(socket, posts: posts)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("show_post", %{"id" => id}, socket) do
    post = Blog.get_post!(String.to_integer(id))

    {:noreply,
     assign(socket,
       selected_post: post,
       show_post_modal: true
     )}
  end

  def handle_event("close_show_modal", _params, socket) do
    {:noreply, assign(socket, show_post_modal: false)}
  end

  def handle_event("sort_by", %{"column" => column}, socket) do
    direction =
      if socket.assigns.sort.column == column do
        if socket.assigns.sort.direction == "ASC", do: "DESC", else: "ASC"
      else
        "ASC"
      end

    posts =
      case socket.assigns.filter["user"] do
        nil ->
          Blog.list_posts()

        user_id ->
          Blog.list_posts(user_id: user_id)
      end
      |> Enum.filter(fn post ->
        String.contains?(String.downcase(post.title), String.downcase(socket.assigns.search_term))
      end)
      |> sort_posts(%{column: column, direction: direction})

    total_pages = div(length(posts) + socket.assigns.per_page - 1, socket.assigns.per_page)

    paginated_posts = Blog.paginate_posts(posts, socket.assigns.page, socket.assigns.per_page)

    {:noreply,
     assign(socket,
       sort: %{column: column, direction: direction},
       posts: paginated_posts,
       total_pages: total_pages
     )}
  end

  def handle_event("previous_page", _params, socket) do
    posts =
      Blog.list_posts()
      |> sort_posts(socket.assigns.sort)
      |> Blog.paginate_posts(socket.assigns.page - 1, socket.assigns.per_page)

    {:noreply,
     assign(socket,
       page: max(socket.assigns.page - 1, 1),
       posts: posts
     )}
  end

  def handle_event("next_page", _params, socket) do
    posts =
      Blog.list_posts()
      |> sort_posts(socket.assigns.sort)
      |> Blog.paginate_posts(socket.assigns.page + 1, socket.assigns.per_page)

    {:noreply,
     assign(socket,
       page: min(socket.assigns.page + 1, socket.assigns.total_pages),
       posts: posts
     )}
  end

  def handle_event("filter_by_user", %{"user" => user_id}, socket) do
    user_id = if user_id == "", do: nil, else: String.to_integer(user_id)

    posts =
      case user_id do
        nil ->
          Blog.list_posts()

        _ ->
          Blog.list_posts(user_id: user_id)
      end
      |> Enum.filter(fn post ->
        String.contains?(String.downcase(post.title), String.downcase(socket.assigns.search_term))
      end)
      |> sort_posts(socket.assigns.sort)

    total_pages = div(length(posts) + socket.assigns.per_page - 1, socket.assigns.per_page)

    paginated_posts = Blog.paginate_posts(posts, socket.assigns.page, socket.assigns.per_page)

    {:noreply,
     assign(socket,
       selected_user_id: user_id,
       posts: paginated_posts,
       filter: %{"user" => user_id},
       total_pages: total_pages
     )}
  end

  def handle_event("filter_by_tag", %{"tag_id" => tag_id}, socket) do
    tag_id = if tag_id == "", do: nil, else: String.to_integer(tag_id)

    posts =
      case tag_id do
        nil ->
          Blog.list_posts()

        _ ->
          Blog.list_posts_by_tag(tag_id)
      end

    total_pages = div(length(posts) + socket.assigns.per_page - 1, socket.assigns.per_page)

    paginated_posts = Blog.paginate_posts(posts, socket.assigns.page, socket.assigns.per_page)

    {:noreply,
     assign(socket,
       selected_tag_id: tag_id,
       posts: paginated_posts,
       total_pages: total_pages
     )}
  end

  def handle_event("modal_open_create", _, socket) do
    {:noreply, assign(socket, show_create_modal: true)}
  end

  def handle_event("modal_open_edit", %{"id" => id}, socket) do
    post = Blog.get_post!(String.to_integer(id))

    tags = post.tags |> Enum.map(& &1.name)

    {:noreply,
     assign(socket,
       show_edit_modal: true,
       tags: tags,
       selected_post: post
     )}
  end

  def handle_event("modal_open_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, show_delete_modal: true, id: id)}
  end

  def handle_event("set_close_create", _params, socket) do
    {:noreply, assign(socket, show_create_modal: false, tags: [], selected_post: %{title: "", body: ""})}
  end

  def handle_event("set_close_edit", _params, socket) do
    {:noreply, assign(socket, show_edit_modal: false, tags: [], selected_post: %{title: "", body: ""})}
  end

  def handle_event("set_close_delete", _params, socket) do
    {:noreply, assign(socket, show_delete_modal: false)}
  end

  def handle_event("create_post", %{"author_id" => author_id, "title" => title, "body" => body}, socket) do
    photo_location =
      consume_uploaded_entries(socket, :photos, fn meta, entry ->
        dest = "#{entry.uuid}-#{entry.client_name}"

        case Blog.upload_to_s3(meta.path, dest) do
          {:ok, url_path} -> {:ok, url_path}
          {:error, reason} -> {:error, reason}
        end
      end)
      |> List.first()

    case Blog.get_or_create_tags(Blog.extract_tags(socket.assigns.tags)) do
      {:ok, tags} ->
        attrs = %{title: title, body: body, tags: tags, user_id: String.to_integer(author_id)}

        result =
          if photo_location do
            Blog.create_post_with_photo(attrs, photo_location.body.location)
          else
            Blog.create_post(attrs)
          end

        case result do
          {:ok, _post} ->
            posts =
              Blog.list_posts()
              |> Blog.sort_posts(socket.assigns.sort)
              |> Blog.paginate_posts(socket.assigns.page, socket.assigns.per_page)

            {:noreply,
             assign(socket, show_create_modal: false, posts: posts,
               total_pages: div(length(posts) + socket.assigns.per_page - 1, socket.assigns.per_page),
               selected_post: %{title: "", body: ""}, tags: [])}

          {:error, changeset} ->
            {:noreply, assign(socket, show_create_modal: false, changeset: changeset)}
        end

      {:error, _reason} ->
        {:noreply, assign(socket, show_create_modal: false, error: "Unable to process tags")}
    end
  end

  def handle_event("edit_post", %{"title" => title, "body" => body}, socket) do
    photo_location =
      consume_uploaded_entries(socket, :photos, fn meta, entry ->
        dest = "#{entry.uuid}-#{entry.client_name}"

        case Blog.upload_to_s3(meta.path, dest) do
          {:ok, url_path} -> {:ok, url_path}
          {:error, reason} -> {:error, reason}
        end
      end)
      |> List.first()

    if photo_location, do: Blog.add_picture_to_post(socket.assigns.selected_post.id, photo_location.body.location)

    case Blog.get_or_create_tags(Blog.extract_tags(socket.assigns.tags)) do
      {:ok, tags} ->
        attrs = %{title: title, body: body, tags: tags}

        case Blog.update_post(Blog.get_post!(socket.assigns.selected_post.id), attrs) do
          {:ok, _post} ->
            posts =
              if socket.assigns.filter["user"] do
                Blog.list_posts(user_id: socket.assigns.filter["user"])
              else
                Blog.list_posts()
              end

            posts =
              posts
              |> Blog.sort_posts(socket.assigns.sort)
              |> Blog.paginate_posts(socket.assigns.page, socket.assigns.per_page)

            {:noreply, assign(socket, show_edit_modal: false, posts: posts,tags: [], selected_post: %{title: "", body: ""})}

          {:error, changeset} ->
            {:noreply, assign(socket, show_edit_modal: false, changeset: changeset)}
        end

      {:error, _reason} ->
        {:noreply, assign(socket, show_edit_modal: false, error: "Unable to process tags")}
    end
  end

  defp sort_posts(posts, %{column: column, direction: direction}) do
    Enum.sort_by(posts, &Map.get(&1, String.to_atom(column)), fn x, y ->
      case direction do
        "ASC" -> x <= y
        "DESC" -> x >= y
      end
    end)
  end

  defp sort_icon(%{column: column, direction: "ASC"}, column), do: "↑"
  defp sort_icon(%{column: column, direction: "DESC"}, column), do: "↓"
  defp sort_icon(_, _), do: ""
end
