defmodule MySuperAppWeb.DocumentUploadLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.DocumentRequests
  require Logger

  @bucket Application.get_env(:my_super_app, :aws)[:bucket]
  @s3_region Application.get_env(:my_super_app, :aws)[:s3_region]
  @access_key_id Application.get_env(:my_super_app, :aws)[:access_key_id]
  @secret_access_key Application.get_env(:my_super_app, :aws)[:secret_access_key]

  def mount(_params, session, socket) do
    user = MySuperApp.Accounts.get_user_by_session_token(session["user_token"])
    if connected?(socket), do: DocumentRequests.subscribe()

    socket =
      socket
      |> assign(:form_data, %{})
      |> assign(:requests, DocumentRequests.get_requests_by_user(user.id))

    socket =
      allow_upload(
        socket,
        :photos,
        accept: ~w(.png .jpeg .jpg),
        max_entries: 3,
        max_file_size: 10_000_000
      )

    {:ok, assign(socket, user_id: user.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto p-6 bg-white rounded-lg shadow-md">
      <h1 class="text-2xl font-bold text-center text-gray-800 mb-6">Add your photo to the site?</h1>

      <.form phx-submit="save" phx-change="validate">
        <input type="text" name="name" placeholder="Name" class="w-full p-2 mb-4 border rounded" />

        <div class="text-sm text-gray-500 mb-4">
          Add up to <%= @uploads.photos.max_entries %> photos
          (max <%= trunc(@uploads.photos.max_file_size / 1_000_000) %> MB each)
        </div>

        <label class="block border-2 border-dashed border-blue-500 p-4 text-center bg-gray-100 rounded mb-4 cursor-pointer"
               phx-drop-target={@uploads.photos.ref}>
          <.live_file_input upload={@uploads.photos} class="hidden" />
          <span>Click to upload or drag and drop files here</span>
        </label>

        <.error :for={err <- upload_errors(@uploads.photos)}>
          <div class="text-red-500 text-sm mb-2"><%= Phoenix.Naming.humanize(err) %></div>
        </.error>

        <div :for={entry <- @uploads.photos.entries} class="mb-4">
          <.live_img_preview entry={entry} class="w-full mb-2 rounded" />
          <div class="h-2 bg-gray-300 rounded-full overflow-hidden mb-2">
            <div class="h-full bg-blue-500" style={"width: #{entry.progress}%"}></div>
          </div>

          <.error :for={err <- upload_errors(@uploads.photos, entry)}>
            <div class="text-red-500 text-sm"><%= Phoenix.Naming.humanize(err) %></div>
          </.error>

          <a phx-click="cancel" phx-value-ref={entry.ref} class="text-red-500 hover:underline text-sm">
            Cancel
          </a>
        </div>

        <button type="submit" phx-disable-with="Uploading..."
                class="w-full bg-blue-500 hover:bg-blue-600 text-white py-2 rounded transition ease-in-out">
          Upload
        </button>
      </.form>
    </div>

    <div id="photos" class="max-w-lg mx-auto mt-8">
      <div :for={{request_id, user_id, link, status} <- @requests} class="mb-6">
        <img src={link} alt="Uploaded photo" class="w-full h-auto rounded mb-4" />
        <div class="font-semibold text-gray-700 mb-2">
          <%= request_id %> - <%= status %>
        </div>
        <button class="bg-red-500 hover:bg-red-600 text-white py-2 px-4 rounded transition ease-in-out"
                phx-click="delete" phx-value-id={request_id}>
          Delete
        </button>
      </div>
    </div>
    """
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  def handle_event("validate", %{"name" => name}, socket) do
    {:noreply, assign(socket, :form_data, %{name: name})}
  end

  def handle_event("save", _, socket) do
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

        request_id = Ecto.UUID.generate()

        DocumentRequests.add_request(request_id, socket.assigns.user_id, photo_locations)

        Logger.info("Document request saved to ETS with request_id: #{request_id}")

        updated_requests = DocumentRequests.get_requests_by_user(socket.assigns.user_id)

        {:noreply, assign(socket, :requests, updated_requests)}
      end

  def handle_event("delete", %{"id" => request_id}, socket) do
    DocumentRequests.delete_request(request_id)

    updated_requests = DocumentRequests.get_requests_by_user(socket.assigns.user_id)

    {:noreply, assign(socket, :requests, updated_requests)}
  end

  def handle_info({:photo_created, _photo}, socket) do
    {:noreply, assign(socket, :requests, DocumentRequests.get_all_requests())}
  end

  defp upload_to_s3(source_path, dest_path) do
    config = %{
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key,
      region: @s3_region
    }

    source_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(@bucket, dest_path)
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

end
