defmodule MySuperAppWeb.PictureController do
  use MySuperAppWeb, :controller

  alias MySuperApp.Blog

  def index(conn, %{"id" => id}) do
    case Blog.get_picture_by_id(id) do
      nil -> send_resp(conn, 404, "Picture not found")
      picture -> json(conn, %{path: picture.url})
    end
  end

  def index(conn, %{"start_date" => start_date, "end_date" => end_date}) do
    case Blog.get_pictures_by_period(start_date, end_date) do
      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Bad pattern"})

      pictures ->
        render(conn, :index, pictures: pictures)
    end
  end

  def index(conn, %{"post_id" => post_id}) do
    render(conn, :index, pictures: Blog.get_pictures_by_post_id(post_id))
  end

  def index(conn, %{"order" => order}) do
    order = if order in ["asc", "desc"], do: order, else: "asc"

    render(conn, :index, pictures: Blog.list_pictures(order))
  end

  def index(conn, %{"author" => author_name}) do
    render(conn, :index, pictures: Blog.get_pictures_by_author(author_name))
  end

  def index(conn, %{"email" => email}) do
    render(conn, :index, pictures: Blog.get_pictures_by_email(email))
  end

def create(conn, %{"post_id" => post_id, "picture" =>  upload}) do
  case Blog.upload_to_s3(upload.path, upload.filename) do
    {:ok, response} ->
      case Blog.replace_picture(post_id, response.body.location) do
        {:ok, picture} -> render(conn, :show, picture: picture)
        {:error, changeset} -> conn |> put_status(400) |> json(%{error: changeset})
      end

    {:error, reason} ->
      conn
      |> put_status(500)
      |> json(%{error: "Failed to upload to S3", reason: reason})
  end
end

def create(conn, %{"artical_id" => post_id, "picture" =>  upload}) do
  case Blog.upload_to_s3(upload.path, upload.filename) do
    {:ok, response} ->
      case Blog.update_post_with_photos(post_id, response.body.location) do
        {:ok, post} -> render(conn, :show, picture: post.picture)
        {:error, changeset} -> conn |> put_status(400) |> json(%{error: changeset})
      end

    {:error, reason} ->
      conn
      |> put_status(500)
      |> json(%{error: "Failed to upload to S3", reason: reason})
  end
end

def create(conn, %{"picture" =>  upload}) do
  case Blog.upload_to_s3(upload.path, upload.filename) do
    {:ok, response} -> conn
      |> json(%{path: response.body.location})

    {:error, reason} -> conn
      |> put_status(500)
      |> json(%{error: "Failed to upload to S3", reason: reason})
  end
end

  def update(conn, %{"post_id" => post_id, "url" => url}) do
    case Blog.replace_picture(post_id, url) do
      {:ok, picture} -> render(conn, :show, picture: picture)
      {:error, changeset} -> conn |> put_status(400) |> json(%{error: changeset})
    end
  end

end
