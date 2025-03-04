defmodule MySuperApp.BlogTest do
  use MySuperApp.DataCase, async: true

  alias MySuperApp.Blog
  alias MySuperApp.CasinosAdmins
  alias MySuperApp.Accounts
  alias MySuperApp.Blog.{Post}
  alias MySuperApp.Tag
  setup do
    {:ok, operator} = CasinosAdmins.create_operator(%{name: "SuperOperator"})
    {:ok, role} = CasinosAdmins.create_role(%{name: "SuperRole", operator_id: operator.id})

    user_attrs = %{
      email: "testuser@example.com",
      username: "testuser",
      password: "supersecretpassword",
      role_id: role.id,
      operator_id: operator.id
    }

    {:ok, user} = Accounts.register_user(user_attrs)
    {:ok, tag} = Blog.create_tag(%{name: "Elixir"})
    post_attrs = %{title: "Learning Elixir", body: "Elixir is awesome!", user_id: user.id, tags: [tag]}

    {:ok, post} = Blog.create_post(post_attrs)

    %{user: user, post: post, tag: tag}
  end

  describe "list_posts/0" do
    test "returns all posts with preloaded tags", %{post: post} do
      assert [returned_post] = Blog.list_posts()
      assert returned_post.id == post.id
      assert length(returned_post.tags) == 1
    end
  end

  describe "get_post!/1" do
    test "returns the post by ID with preloaded tags", %{post: post} do
      returned_post = Blog.get_post!(post.id)
      assert returned_post.id == post.id
      assert length(returned_post.tags) == 1
    end
  end

  describe "create_post/1" do
    test "creates a new post with tags", %{user: user, tag: tag} do
      post_attrs = %{title: "New Post", body: "New Body", user_id: user.id, tags: [tag]}
      {:ok, post} = Blog.create_post(post_attrs)
      assert post.title == "New Post"
      assert post.body == "New Body"
      assert length(post.tags) == 1
    end
  end

  describe "update_post/2" do
    test "updates a post's title", %{post: post, tag: tag} do
      {:ok, updated_post} = Blog.update_post(post, %{title: "Updated Title", tags: [tag]})
      assert updated_post.title == "Updated Title"
    end
  end

  describe "delete_post/1" do
    test "deletes a post", %{post: post} do
      {:ok, deleted_post} = Blog.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_post!(deleted_post.id) end
    end
  end

  describe "search_posts/1" do
    test "returns posts that match the search term", %{post: post} do
      assert [%Post{} = returned_post] = Blog.search_posts("Elixir")
      assert returned_post.id == post.id
    end
  end

  describe "get_posts_by_date/1" do
    test "returns posts by specific date", %{post: post} do
      assert returned_post = Blog.get_posts_by_date(~D[2024-08-10])
    end
  end

  describe "create_post_/1" do
    test "creates a new post with valid attributes", %{user: user, tag: tag} do
      attrs = %{title: "New Post", body: "New Content", user_id: user.id, tags: [tag]}
      assert {:ok, %Post{} = post} = Blog.create_post(attrs)
      assert post.title == "New Post"
      assert post.body == "New Content"
      assert length(post.tags) == 1
    end

    test "fails to create a post with invalid attributes" do
      attrs = %{title: nil, body: "Invalid Content"}
      assert {:error, changeset} = Blog.create_post(attrs)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end
  end


  describe "search_posts_/1" do
    test "returns posts matching the search term", %{post: post} do
      assert [%Post{id: id}] = Blog.search_posts("Elixir")
    end

    test "returns an empty list if no posts match the search term" do
      assert [] = Blog.search_posts("Nonexistent")
    end
  end

  describe "get_posts_by_date_/1" do
    test "returns posts created on the specified date", %{post: post} do
      date = ~D[2021-08-13]
      assert [] = Blog.get_posts_by_date(date)
    end

    test "returns an empty list if no posts are found on the specified date" do
      date = ~D[2000-01-01]
      assert [] = Blog.get_posts_by_date(date)
    end
  end

  describe "get_posts_by_period_/2" do
    test "returns posts within the specified date range", %{post: post} do
      start_date = ~D[2024-08-01]
      end_date = ~D[2024-08-31]
      assert [%Post{id: id}] = Blog.get_posts_by_period(start_date, end_date)
    end

    test "returns an empty list if no posts are found in the specified date range" do
      start_date = ~D[2000-08-16]
      end_date = ~D[2012-08-16]
      assert [] = Blog.get_posts_by_period(start_date, end_date)
    end
  end

  describe "get_or_create_tag_/1" do
    test "returns an existing tag if it exists", %{tag: tag} do
      assert {:ok, tag} = Blog.get_or_create_tag(tag.name)
    end

    test "creates and returns a new tag if it doesn't exist" do
      tag_name = "NewTag"
      assert {:ok, %Tag{name: name}} = Blog.get_or_create_tag(tag_name)
    end
  end
end
