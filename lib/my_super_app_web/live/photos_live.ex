defmodule MySuperAppWeb.PhotosLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.Photos
  alias MySuperApp.Photos.Photo
  alias MySuperApp.Repo
  alias ExAws.S3
  require Logger

  @bucket Application.get_env(:my_super_app, :aws)[:bucket]
  @s3_region Application.get_env(:my_super_app, :aws)[:s3_region]
  @access_key_id Application.get_env(:my_super_app, :aws)[:access_key_id]
  @secret_access_key Application.get_env(:my_super_app, :aws)[:secret_access_key]

  def mount(_params, _session, socket) do
    if connected?(socket), do: Photos.subscribe()

    socket =
      assign(socket,
        form: to_form(Photos.change_photo(%Photo{}))
      )

    socket =
      allow_upload(
        socket,
        :photos,
        accept: ~w(.png .jpeg .jpg),
        max_entries: 3,
        max_file_size: 10_000_000
      )

    {:ok, stream(socket, :photos, Photos.list_photos())}
  end

  def render(assigns) do
    ~H"""
    <h1>Add your's photo to site?</h1>

    <div id="photos">
      <.form for={@form} phx-submit="save" phx-change="validate">
        <.input field={@form[:name]} placeholder="Name" />
        <div class="hint">
          Add up to <%= @uploads.photos.max_entries %> photos
          (max <%= trunc(@uploads.photos.max_file_size / 1_000_000) %> MB each)
        </div>

        <div class="drop" phx-drop-target={@uploads.photos.ref}>
          <.live_file_input upload={@uploads.photos} /> or drag and drop here
        </div>

        <.error :for={err <- upload_errors(@uploads.photos)}>
          <%= Phoenix.Naming.humanize(err) %>
        </.error>

        <div :for={entry <- @uploads.photos.entries} class="entry">
          <.live_img_preview entry={entry} />
          <div class="progress">
            <div class="value">
              <%= entry.progress %>%
            </div>

            <div class="bar">
              <span style={"width: #{entry.progress}%"}></span>
            </div>

            <.error :for={err <- upload_errors(@uploads.photos, entry)}>
              <%= Phoenix.Naming.humanize(err) %>
            </.error>
          </div>

          <a phx-click="cancel" phx-value-ref={entry.ref}>
            &times;
          </a>
        </div>

        <.button phx-disable-with="Uploading...">
          Upload
        </.button>
      </.form>

      <div id="photos" phx-update="stream">
        <div :for={{dom_id, photo} <- @streams.photos} id={dom_id}>
          <div
            :for={
              {photo_location, index} <-
                Enum.with_index(photo.photo_locations)
            }
            class="photo"
          >
            <img src={photo_location} />
            <div class="name">
              <%= photo.name %> (<%= index + 1 %>)
            </div>
             <button class="delete-button" phx-click="delete" phx-value-id={photo.id}>Delete</button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  def handle_event("validate", %{"photo" => params}, socket) do
    changeset =
      %Photo{}
      |> Photos.change_photo(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"photo" => params}, socket) do
    photo_locations =
      consume_uploaded_entries(socket, :photos, fn meta, entry ->
        dest = "#{entry.uuid}-#{entry.client_name}"

        Logger.info("Uploading file: #{meta.path} to S3 as #{dest}")

        case upload_to_s3(meta.path, dest) do
          {:ok, _response} ->
            url_path = "https://#{@bucket}.s3.#{@s3_region}.amazonaws.com/#{dest}"
            Logger.info("File uploaded successfully to #{url_path}")
            {:ok, url_path}

          {:error, reason} ->
            Logger.error("Failed to upload to S3: #{inspect(reason)}")
            {:error, reason}
        end
      end)

    params = Map.put(params, "photo_locations", photo_locations)

    case Photos.create_photo(params) do
      {:ok, _photo} ->
        changeset = Photos.change_photo(%Photo{})
        {:noreply, assign_form(socket, changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    photo = get_photo!(id)

    case delete_photo(photo) do
      {:ok, _photo} ->
        {:noreply, stream_delete(socket, :photos, photo)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_info({:photo_created, photo}, socket) do
    {:noreply, stream_insert(socket, :photos, photo, at: 0)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp upload_to_s3(source_path, dest_path) do
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

  def get_photo!(id), do: Repo.get!(Photo, id)

  def delete_photo(%Photo{} = photo) do
    Repo.delete(photo)
  end
end
