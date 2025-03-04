defmodule MySuperAppWeb.PostController do
  use MySuperAppWeb, :controller

  alias MySuperApp.Blog
  alias MySuperApp.Blog.Post

  def index(conn, %{"start_date" => start_date, "end_date" => end_date}) do
    start_date = Date.from_iso8601!(start_date)
    end_date = Date.from_iso8601!(end_date)
    posts = Blog.get_posts_by_period(start_date, end_date)
    render(conn, :index, posts: posts)
  end

  def index(conn, %{"date" => date}) do
    date = Date.from_iso8601!(date)
    posts = Blog.get_posts_by_date(date)
    render(conn, :index, posts: posts)
  end

  def index(conn, %{"tags" => tags}) do
    tag_names = String.split(tags, ",")
    posts = MySuperApp.Blog.get_posts_by_tags(tag_names)
    render(conn, :index, posts: posts)
  end

  def index(conn, %{"user_id" => user_id}) do
    posts = Blog.get_posts_by_user_id(user_id)
    render(conn, :index, posts: posts)
  end

  def index(conn, %{"limit" => limit}) do
    limit = String.to_integer(limit)
    posts = Blog.get_recent_posts(limit)
    render(conn, :index, posts: posts)
  end

  def index(conn, _params) do
    posts = Blog.list_posts()
    render(conn, :index, posts: posts)
  end

  def create(conn, %{"post" => %{"tags" => tag_params} = post_params}) do
    tags =
      tag_params
      |> Enum.map(fn %{"name" => name} ->
        case Blog.get_or_create_tag(name) do
          {:ok, tag} -> tag
          _ -> nil
        end
      end)
      |> Enum.filter(& &1)

    updated_post_params = Map.put(post_params, "tags", tags)

    with {:ok, %Post{} = post} <- Blog.create_post(updated_post_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/posts/#{post}")
      |> render(:show, post: post)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    render(conn, :show, post: post)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Blog.get_post!(id)

    with {:ok, %Post{} = post} <- Blog.update_post_postman(post, post_params) do
      render(conn, :show, post: post)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Blog.get_post!(id)

    with {:ok, %Post{}} <- Blog.delete_post(post) do
      send_resp(conn, :no_content, "")
    end
  end
end
