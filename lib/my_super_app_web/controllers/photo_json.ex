defmodule MySuperAppWeb.PictureJSON do
  alias MySuperApp.Blog.Picture

  @doc """
  Renders a list of pictures.
  """
  def index(%{pictures: pictures}) do
    %{data: for(picture <- pictures, do: data(picture))}
  end

  @doc """
  Renders a single picture.
  """
  def show(%{picture: picture}) do
    %{data: data(picture)}
  end

  defp data(%Picture{} = picture) do
    %{
      id: picture.id,
      url: picture.url,
      post_id: picture.post_id,
      inserted_at: picture.inserted_at,
      updated_at: picture.updated_at
    }
  end
end
