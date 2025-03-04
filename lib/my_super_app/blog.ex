defmodule MySuperApp.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query
  alias MySuperApp.Repo
  alias MySuperApp.Blog.Post
  alias MySuperApp.Tag
  alias MySuperApp.Blog.Picture
  alias ExAws.S3
  require Logger

  @bucket "test"
  @s3_region "test"

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts do
    Repo.all(Post)
    |> Repo.preload(:tags)
  end

  def list_posts(user_id: user_id) do
    Post
    |> where([p], p.user_id == ^user_id)
    |> Repo.all()
    |> Repo.preload(:tags)
  end

  @doc """
  Returns a list of tags formatted for selection.

  ## Examples

      iex> list_posts_with_tags()
      [%{key: "Tag1", value: 1, name: "Tag1", disabled: false}, ...]
  """
  def list_posts_with_tags do
    list_tags()
    |> Enum.map(fn tag ->
      %{
        key: tag.name,
        value: tag.id,
        name: tag.name,
        disabled: false
      }
    end)
  end

  @doc """
  Gets a single post with preloaded tags.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

  """
  def get_post!(id) do
    Repo.get!(Post, id)
    |> Repo.preload(:tags)
    |> Repo.preload(:picture)
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}
  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tags, attrs[:tags] || attrs["tags"])
    |> Repo.insert()
  end

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}
  """
  def create_tag(attrs) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}
  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tags, attrs[:tags] || attrs["tags"])
    |> Ecto.Changeset.put_assoc(:picture, attrs[:picture])
    |> Repo.update()
  end

  def create_post_with_photo(post_attrs, photo_url) do
    Repo.transaction(fn ->
      {:ok, post} = create_post(post_attrs)

      create_picture(%{url: photo_url, post_id: post.id})

      {:ok, post}
    end)
  end

  def add_picture_to_post(post_id, picture_url) do
    changeset =
      Repo.get!(Post, post_id)
      |> Repo.preload(:picture)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:picture, %Picture{url: picture_url})

    case Repo.update(changeset) do
      {:ok, updated_post} -> {:ok, updated_post}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def sort_posts(posts, sort) do
    case sort do
      :desc -> Enum.sort_by(posts, & &1.inserted_at, {:desc, DateTime})
      :asc -> Enum.sort_by(posts, & &1.inserted_at, {:asc, DateTime})
      _ -> posts
    end
  end

  def update_post_postman(%Post{} = post, attrs) do
    tags =
      (attrs[:tags] || attrs["tags"] || [])
      |> Enum.map(fn tag ->
        case MySuperApp.Blog.get_or_create_tag(tag["name"]) do
          {:ok, tag} -> tag
          _ -> nil
        end
      end)
    |> Enum.filter(& &1)
    post
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}
  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  def delete_post_by_id(id) do
    Repo.get(Post, id)
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}
  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  @doc """
  Gets a list of posts by a specific date.

  ## Examples

      iex> get_posts_by_date(~D[2023-08-10])
      [%Post{}, ...]
  """
  def get_posts_by_date(date) do
    from(p in Post, where: fragment("DATE(?) = ?", p.inserted_at, ^date))
    |> Repo.all()
  end

  @doc """
  Gets a list of posts within a date range.

  ## Examples

      iex> get_posts_by_period(~D[2023-08-01], ~D[2023-08-10])
      [%Post{}, ...]
  """
  def get_posts_by_period(start_date, end_date) do
    from(p in Post,
      where:
        fragment("date(?)", p.inserted_at) >= ^start_date and
          fragment("date(?)", p.inserted_at) <= ^end_date
    )
    |> Repo.all()
  end

  @doc """
  Gets a post by ID with preloaded tags and user.

  ## Examples

      iex> get_post_with_details(123)
      %Post{}
  """
  def get_post_with_details(id) do
    Repo.get(Post, id)
    |> Repo.preload([:tags, :user])
  end

  @doc """
  Counts the total number of posts.

  ## Examples

      iex> count_posts()
      10
  """
  def count_posts do
    Repo.aggregate(Post, :count, :id)
  end

  @doc """
  Lists all tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]
  """
  def list_tags do
    Repo.all(Tag)
    |> Repo.preload(:posts)
    |> Enum.map(&(&1 |> Map.from_struct()))
  end

  @doc """
  Lists tags by their names.

  ## Examples

      iex> list_tags_by_names(["elixir", "phoenix"])
      [%Tag{}, ...]
  """
  def list_tags_by_names(names) do
    from(t in Tag, where: t.name in ^names) |> Repo.all()
  end


  def extract_tags(tags) do
    tags
    |> Enum.map(&String.trim/1)
  end

  @doc """
  Preloads tags for a given post.

  ## Examples

      iex> preload_tags(post)
      %Post{tags: [%Tag{}, ...]}
  """
  def preload_tags(post) do
    Repo.preload(post, :tags)
  end

  @doc """
  Searches posts by a filter applied to the title.

  ## Examples

      iex> search_posts("elixir")
      [%Post{}, ...]
  """
  def search_posts(filter) do
    from(p in Post, where: like(p.title, ^"%#{filter}%"))
    |> Repo.all()
    |> Repo.preload(:tags)
  end

  @doc """
  Gets posts by their associated tags.

  ## Examples

      iex> get_posts_by_tags(["elixir", "phoenix"])
      [%Post{}, ...]
  """
  def get_posts_by_tags(tag_names) do
    from(p in Post,
      join: t in assoc(p, :tags),
      where: t.name in ^tag_names,
      distinct: p.id
    )
    |> Repo.all()
    |> Repo.preload(:tags)
  end

  def list_posts_by_tag(tag_id) do
    query =
      from p in Post,
        join: pt in "posts_tags", on: pt.post_id == p.id,
        join: t in Tag, on: t.id == pt.tag_id,
        where: t.id == ^tag_id,
        preload: [:tags]

    Repo.all(query)
  end

  def get_or_create_tag(tag_name) do
    case Repo.get_by(Tag, name: tag_name) do
      nil ->
        create_tag(%{name: tag_name})

      tag ->
        {:ok, tag}
    end
  end

  def get_posts_by_user_id(user_id) do
    from(p in Post, where: p.user_id == ^user_id)
    |> Repo.all()
    |> Repo.preload(:tags)
  end

  def sort_posts_picture(posts, sort_order) do
    sort_direction = if sort_order == "newest", do: {:desc, DateTime}, else: {:asc, DateTime}
    Enum.sort_by(posts, & &1.inserted_at, sort_direction)
  end

  def get_recent_posts(limit) do
    from(p in Post, order_by: [desc: p.inserted_at], limit: ^limit)
    |> Repo.all()
    |> Repo.preload(:tags)
  end

  def get_tag_by_name(name) do
    Repo.get_by(Tag, name: name)
  end

  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  def get_tag!(id), do: Repo.get!(Tag, id)

  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  def get_or_create_tags(tag_names) do
    tags =
      Enum.map(tag_names, fn tag_name ->
        case get_tag_by_name(tag_name) do
          nil ->
            case create_tag(%{name: tag_name}) do
              {:ok, tag} -> tag
              {:error, _reason} -> nil
            end
          tag -> tag
        end
      end)

    if Enum.any?(tags, &is_nil/1) do
      {:error, "Failed to create some tags"}
    else
      {:ok, tags}
    end
  end

  def get_tags_by_ids(tag_ids) when is_list(tag_ids) do
    Repo.all(from t in Tag, where: t.id in ^tag_ids)
  end

  def list_posts_sorted_by(column, direction) do
    direction = if direction in ["ASC", "DESC"], do: direction, else: "ASC"

    Repo.all(
      from p in Post,
        join: t in assoc(p, :tags),
        order_by: [{^direction, field(p, ^String.to_existing_atom(column))}],
        preload: [tags: t]
    )
  end

  def list_posts_by_author_id(author_id) do
    Repo.all(from p in Post, where: p.user_id == ^author_id, preload: [:tags, :user])
  end

  def search_posts_by_title(search_term) do
    search_term = "%#{search_term}%"

    from(p in Post, where: ilike(p.title, ^search_term))
    |> Repo.all()
  end

  def upload_to_s3(source_path, dest_path) do
    config = %{
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key,
      region: @s3_region
    }

    source_path
    |> ExAws.S3.Upload.stream_file()
    |> S3.upload(@bucket, dest_path)
    |> ExAws.request(config: config)
    |> case do
      {:ok, response} ->
        Logger.info("Uploaded to S3: #{dest_path}")
        {:ok, response}

      {:error, reason} ->
        Logger.error("Error uploading to S3: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def create_picture(attrs \\ %{}) do
    %Picture{}
    |> Picture.changeset(attrs)
    |> Repo.insert()
  end

  def toggle_publish_post(post) do
    post
    |> Post.changeset(%{published: !post.published})
    |> MySuperApp.Repo.update()
  end

  def delete_picture(post) do
    case post.picture do
      nil -> {:error, "No picture to delete"}
      picture ->
        Repo.delete(picture)
    end
  end

  def delete_picture_by_id(id) do
    picture = get_picture_by_id(id)

    case Repo.delete(picture) do
      {:ok, _deleted_picture} -> {:ok, picture}

      {:error, changeset} -> {:error, changeset}
    end
  end

  def list_posts_with_pictures() do
    Repo.all(
      from p in Post,
        left_join: pic in assoc(p, :picture),
        preload: [picture: pic]
    )
  end

  def picture_filename(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> Path.basename()
  end

  def list_posts_without_pictures() do
    Repo.all(
      from p in Post,
        left_join: pic in assoc(p, :picture),
        where: is_nil(pic.id),
        preload: [picture: pic]
    )
  end

  def upload_photo_to_s3(%{path: path}, %{uuid: uuid, client_name: client_name}) do
    dest = "#{uuid}-#{client_name}"
    Logger.info("Uploading file: #{path} to S3 as #{dest}")

    case upload_to_s3(path, dest) do
      {:ok, _response} ->
        url_path = "https://#{@bucket}.s3.#{@s3_region}.amazonaws.com/#{dest}"
        Logger.info("File uploaded successfully to #{url_path}")
        {:ok, url_path}

      {:error, reason} ->
        Logger.error("Failed to upload to S3: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def update_post_with_photos(post_id, photo_locations) do
    post = get_post!(post_id)

    changeset_attrs =
      %{
        title: post.title,
        body: post.body,
        tags: post.tags,
        user_id: post.user_id
      }

    changeset_attrs =
        Map.put(changeset_attrs, :picture, %{
          url: photo_locations,
          post_id: post.id
        })

    case update_post(post, changeset_attrs) do
      {:ok, post} ->
        Logger.info("Post updated successfully with ID: #{post.id}")
        {:ok, post}

      {:error, changeset} ->
        Logger.error("Failed to update post: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  def paginate_posts(posts, page, per_page) do
    posts
    |> Enum.chunk_every(per_page)
    |> Enum.at(page - 1, [])
  end

  def subscribe do
    Phoenix.PubSub.subscribe(MySuperApp.PubSub, "posts")
  end

  def notify_post_updated(post) do
    Phoenix.PubSub.broadcast(MySuperApp.PubSub, "posts", {:post_updated, post})
  end

  def broadcast(event, payload) do
    Phoenix.PubSub.broadcast(MySuperApp.PubSub, "posts", %{event: event, payload: payload})
  end

  def search_posts_with_pictures(query, "title") do
    base_query =
      from(p in Post,
        join: pic in Picture, on: pic.post_id == p.id,
        preload: [picture: pic],
        where: ilike(p.title, ^"%#{query}%"),
        order_by: [asc: p.title]
      )

    Repo.all(base_query)
  end

  def search_posts_with_pictures(query, "filename") do
    base_query =
      from(p in Post,
        join: picture in Picture, on: picture.post_id == p.id,
        preload: [picture: picture],
        where: ilike(fragment("split_part(?, '/', -1)", picture.url), ^"%#{query}%"),
        order_by: [asc: fragment("split_part(?, '/', -1)", picture.url)]
      )

    Repo.all(base_query)
  end

  def search_posts_with_pictures(query, "extension") do
    base_query =
      from(p in Post,
        join: picture in Picture, on: picture.post_id == p.id,
        preload: [picture: picture],
        where: ilike(fragment("split_part(?, '.', -1)", picture.url), ^"%#{query}%"),
        order_by: [asc: fragment("split_part(?, '.', -1)", picture.url)]
      )

    Repo.all(base_query)
  end

  def search_posts_with_pictures(query, "email") do
    base_query =
      from(p in Post,
        join: u in assoc(p, :user),
        join: pic in Picture, on: pic.post_id == p.id,
        preload: [picture: pic, user: u],
        where: ilike(u.email, ^"%#{query}%"),
        order_by: [asc: u.email]
      )

    Repo.all(base_query)
  end

  def search_posts_with_pictures(query, "username") do
    base_query =
      from(p in Post,
        join: u in assoc(p, :user),
        join: pic in Picture, on: pic.post_id == p.id,
        preload: [picture: pic, user: u],
        where: ilike(u.username, ^"%#{query}%"),
        order_by: [asc: u.username]
      )

    Repo.all(base_query)
  end

  def search_posts_with_pictures(query, _sort_by) do
    base_query =
      from(p in Post,
        join: pic in Picture, on: pic.post_id == p.id,
        preload: [picture: pic]
      )

    Repo.all(base_query)
  end

  def get_sorted_posts_with_pictures("newest") do
    from(p in Post,
      join: pic in assoc(p, :picture),
      preload: [picture: pic],
      order_by: [desc: p.updated_at]
    )
    |> Repo.all()
  end

  def get_sorted_posts_with_pictures("oldest") do
    from(p in Post,
      join: pic in assoc(p, :picture),
      preload: [picture: pic],
      order_by: [asc: p.updated_at]
    )
    |> Repo.all()
  end

  def get_sorted_posts_with_pictures(_order) do
    from(p in Post,
      join: pic in assoc(p, :picture),
      preload: [picture: pic]
    )
    |> Repo.all()
  end

  def get_posts_within_date_range(start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

    query = from p in MySuperApp.Blog.Post,
    left_join: pic in assoc(p, :picture),
    where: not is_nil(pic.url),
    where: p.inserted_at >= ^start_datetime and p.inserted_at <= ^end_datetime,
    preload: [picture: pic]
    Repo.all(query)
  end

  #----------------------------------------------------API


  def get_pictures_by_post_id(post_id) do
    Repo.all(from p in Picture, where: p.post_id == ^post_id)
  end

  def get_all_pictures() do
    Repo.all(Picture)
  end

  def get_pictures_by_author(author_name) do
    Repo.all(
      from p in Picture,
      join: post in assoc(p, :post),
      join: user in assoc(post, :user),
      where: ilike(user.username, ^"%#{author_name}%"),
      select: p
    )
  end

  def get_pictures_by_email(email) do
    Repo.all(
      from p in Picture,
      join: post in assoc(p, :post),
      join: user in assoc(post, :user),
      where: user.email == ^email,
      select: p
    )
  end

  def list_posts(params \\ %{}) do
    tag_id = Map.get(params, "tag_id")
    body_search = Map.get(params, "body")
    author_id = Map.get(params, "author_id")
    page = Map.get(params, "page", 1)

    query =
      Post
      |> where([p], p.published == true)
      |> preload([p], [:picture, :tags, :user])
      |> maybe_filter_by_tag(tag_id)
      |> maybe_search_body(body_search)
      |> maybe_filter_by_author(author_id)

    per_page = 10
    offset = (page - 1) * per_page

    query =
      query
      |> limit(^per_page)
      |> offset(^offset)

    Repo.all(query)
  end

  defp maybe_filter_by_tag(query, nil), do: query
  defp maybe_filter_by_tag(query, tag_id) do
    from(p in query,
      join: t in assoc(p, :tags),
      where: t.id == ^tag_id
    )
  end

  defp maybe_search_body(query, nil), do: query
  defp maybe_search_body(query, body_search) do
    from(p in query,
      where: ilike(p.body, ^"%#{body_search}%")
    )
  end

  defp maybe_filter_by_author(query, nil), do: query
  defp maybe_filter_by_author(query, author_id) do
    from(p in query, where: p.user_id == ^author_id)
  end




  #------------------------------------------------------
  def get_picture_by_id(id) do
    Repo.get(Picture, id)
    |> Repo.preload(post: [:user])
  end

  def get_pictures_by_period(start_date, end_date, order_by \\ []) do
    query =
      from p in Picture,
        where: p.inserted_at >= ^start_date and p.inserted_at <= ^end_date,
        order_by: ^order_by

    Repo.all(query)
  end

  def get_posts_with_pictures do
    from(pic in Picture,
      left_join: p in assoc(pic, :post),
      left_join: u in assoc(p, :user),
      where: not is_nil(pic.url),
      preload: [post: {p, user: u}]
    )
    |> Repo.all()
  end

  def search_pictures(search_term, sort_order \\ "newest") do
    from(pic in Picture,
      left_join: p in assoc(pic, :post),
      left_join: u in assoc(p, :user),
      left_join: pt in "posts_tags",
      on: p.id == pt.post_id,
      left_join: t in Tag,
      on: t.id == pt.tag_id,
      where: not is_nil(pic.url),
      where: fragment("CAST(? AS TEXT)", p.id) == ^search_term or
             ilike(p.title, ^"%#{search_term}%") or
             ilike(pic.url, ^"%#{search_term}%") or
             ilike(u.email, ^"%#{search_term}%") or
             ilike(u.username, ^"%#{search_term}%") or
             ilike(t.name, ^"%#{search_term}%") or
             is_nil(p.id),
      order_by: ^order_by_date(sort_order),
      preload: [post: {p, user: u}]
    )
    |> Repo.all()
  end

  defp order_by_date("oldest"), do: [asc: :updated_at]
  defp order_by_date("newest"), do: [desc: :updated_at]
  defp order_by_date(_), do: [desc: :updated_at]

  def list_pictures(order) do
    order = if order in ["asc", "desc"], do: String.to_existing_atom(order), else: :asc

    Picture
    |> order_by([{^order, :inserted_at}])
    |> Repo.all()
    |> Repo.preload(:post)
  end


  def replace_picture(post_id, url) do
    picture = Repo.get_by(Picture, post_id: post_id)

    case picture do
      nil -> {:error, "Picture not found"}
      picture ->
        picture
        |> Picture.changeset(%{url: url})
        |> Repo.update()
    end
  end



end
