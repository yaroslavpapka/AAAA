defmodule MySuperApp.PictureTest do
  alias MySuperApp.Blog
  use MySuperApp.DataCase
  alias MySuperApp.Blog.Post
  alias MySuperApp.Tag
  alias MySuperApp.Blog.Picture

  alias MySuperApp.User

  defp setup_user_attrs do

  end

  describe "create_picture/1" do
    test "creates a picture with valid attributes" do
      valid_attrs = %{url: "http://example.com/pic.jpg"}

      assert {:ok, %Picture{} = picture} = Blog.create_picture(valid_attrs)
      assert picture.url == "http://example.com/pic.jpg"
    end

    test "returns error changeset with invalid attributes" do
      invalid_attrs = %{url: nil}

      assert {:error, changeset} = Blog.create_picture(invalid_attrs)
      assert changeset.valid? == false
    end
  end

  describe "delete_picture_by_id/1" do
    test "deletes a picture by id" do
      valid_attrs = %{url: "http://example.com/pic.jpg"}

      assert {:ok, %Picture{} = picture} = Blog.create_picture(valid_attrs)
      assert picture.url == "http://example.com/pic.jpg"

      assert {:ok, _picture} = Blog.delete_picture_by_id(picture.id)
      refute Repo.get(Picture, picture.id)
    end

    test "returns error if picture not found" do
      assert {:error, _} = Blog.delete_picture_by_id(-1)
    end
  end

  describe "list_posts_with_pictures/0" do
    test "lists posts with associated pictures" do
      valid_attrs = %{url: "http://example.com/pic.jpg"}

      assert {:ok, %Picture{} = picture} = Blog.create_picture(valid_attrs)
      assert picture.url == "http://example.com/pic.jpg"

      posts = Blog.list_posts_with_pictures()

      assert Enum.all?(posts, fn p -> p.picture end)
    end
  end


  describe "picture_filename/1" do
    test "returns the filename from a URL" do
      url = "https://example.com/images/photo.jpg"
      assert Blog.picture_filename(url) == "photo.jpg"
    end
  end

  #API test

end


# valid_upload = %{path: "path/to/file.jpg", filename: "file.jpg"}
# invalid_upload = %{path: "invalid/path", filename: "file.jpg"}


#   test "returns 200 and picture path if picture exists", %{conn: conn} do
#     picture = Blog.create_picture!(%{url: "http://example.com/picture.jpg"})
#     conn = get(conn, Routes.picture_path(conn, :index, %{id: picture.id}))

#     assert json_response(conn, 200)["path"] == picture.url
#   end

#   test "returns 404 if picture does not exist", %{conn: conn} do
#     conn = get(conn, Routes.picture_path(conn, :index, %{id: -1}))

#     assert response(conn, 404)
#   end

#   test "returns pictures within date range", %{conn: conn} do
#     # Create some pictures within and outside the date range
#     picture_1 = Blog.create_picture!(%{url: "http://example.com/1.jpg", inserted_at: ~N[2023-01-01 12:00:00]})
#     picture_2 = Blog.create_picture!(%{url: "http://example.com/2.jpg", inserted_at: ~N[2023-02-01 12:00:00]})

#     conn = get(conn, Routes.picture_path(conn, :index, %{start_date: "2023-01-01", end_date: "2023-02-01"}))

#     assert json_response(conn, 200)["pictures"] != []
#   end

#   test "returns 400 if invalid date format", %{conn: conn} do
#     conn = get(conn, Routes.picture_path(conn, :index, %{start_date: "invalid", end_date: "invalid"}))

#     assert json_response(conn, 400)["error"] == "Bad pattern"
#   end

#   test "uploads and returns picture path for valid upload", %{conn: conn} do
#     Blog.stub(:upload_to_s3, fn _, _ -> {:ok, %{body: %{location: "http://s3.amazonaws.com/pic.jpg"}}} end)

#     conn = post(conn, Routes.picture_path(conn, :create, %{picture: @valid_upload}))

#     assert json_response(conn, 200)["path"] == "http://s3.amazonaws.com/pic.jpg"
#   end

#   test "returns 500 on failed S3 upload", %{conn: conn} do
#     Blog.stub(:upload_to_s3, fn _, _ -> {:error, "Failed upload"} end)

#     conn = post(conn, Routes.picture_path(conn, :create, %{picture: @invalid_upload}))

#     assert json_response(conn, 500)["error"] == "Failed to upload to S3"
#   end


#   test "updates picture URL for a post", %{conn: conn} do
#     post = Blog.create_post!(%{title: "Test Post"})
#     Blog.create_picture!(%{url: "http://example.com/old.jpg", post_id: post.id})

#     conn = put(conn, Routes.picture_path(conn, :update, %{post_id: post.id, url: "http://example.com/new.jpg"}))

#     assert json_response(conn, 200)["picture"]["url"] == "http://example.com/new.jpg"
#   end

#   test "returns 400 if invalid update params", %{conn: conn} do
#     conn = put(conn, Routes.picture_path(conn, :update, %{post_id: -1, url: ""}))

#     assert json_response(conn, 400)["error"]
#   end
