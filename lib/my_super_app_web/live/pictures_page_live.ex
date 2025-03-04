# defmodule MySuperAppWeb.PictureLive do
#   use MySuperAppWeb, :live_view
#   alias MySuperApp.Blog
#   alias MySuperApp.Blog.Post

#   def mount(_params, _session, socket) do
#     if connected?(socket), do: MySuperAppWeb.Endpoint.subscribe("posts")

#     posts = Blog.get_posts_with_pictures()
#     posts_without_pictures = Blog.list_posts_without_pictures()
#     changeset = Blog.change_post(%Post{})
#     all_tags = Blog.list_tags()

#     socket =
#       socket
#       |> stream(:posts, posts)
#       |> assign(:form, changeset)
#       |> assign(:posts_without_pictures, posts_without_pictures)
#       |> assign(:selected_post_id, "")
#       |> assign(:sort_order, "newest")
#       |> assign(:query, "")
#       |> assign(:all_tags, all_tags)
#       |> assign(:show_modal , false)
#       |> assign(:search_value, "")
#       |> assign(:photo, nil)
#       |> assign(:show_create_modal, false)
#       |> allow_upload(:photos,
#         accept: ~w(.png .jpeg .jpg),
#         max_entries: 1,
#         max_file_size: 10_000_000
#       )

#     {:ok, socket}
#   end

#   def render(assigns) do
#     ~H"""
#     <div class="container mx-auto p-4">
#       <h1 class="text-3xl font-bold mb-6 text-center text-gray-800">Posts Pictures</h1>

#       <div class="flex justify-between items-center mb-6">

#   <div class="flex space-x-6">
#     <button
#       phx-click="open_create_modal"
#       class="bg-gradient-to-r from-blue-500 to-indigo-600 text-white py-3 px-8 rounded-full shadow-lg transform transition-transform duration-300 hover:scale-105"
#     >
#       + Add a Photo
#     </button>

#   </div>

#   <div class="flex items-center space-x-4">
#     <label class="text-gray-700 font-semibold">Sort by:</label>
#     <div class="flex items-center space-x-2">
#       <label class="flex items-center">
#         <input
#           type="radio"
#           name="sort_order"
#           value="newest"
#           phx-click="sort_order"
#           phx-value-order="newest"
#           class="hidden"
#           checked={@sort_order == "newest"}
#         />
#         <span
#           class={"cursor-pointer py-2 px-4 rounded-full transition-colors " <>
#             if @sort_order == "newest", do: "bg-green-500 text-white", else: "bg-gray-300 text-gray-700 hover:bg-gray-400"}
#         >
#           Newest
#         </span>
#       </label>

#       <label class="flex items-center">
#         <input
#           type="radio"
#           name="sort_order"
#           value="oldest"
#           phx-click="sort_order"
#           phx-value-order="oldest"
#           class="hidden"
#           checked={@sort_order == "oldest"}
#         />
#         <span
#           class={"cursor-pointer py-2 px-4 rounded-full transition-colors " <>
#             if @sort_order == "oldest", do: "bg-red-500 text-white", else: "bg-gray-300 text-gray-700 hover:bg-gray-400"}
#         >
#           Oldest
#         </span>
#       </label>
#     </div>
#   </div>
# </div>

# <div class="flex justify-center mb-4">

#   <input
#     type="text"
#     name="search_query"
#     placeholder="Search..."
#     phx-debounce="300"
#     phx-keyup="search"
#     class="border border-gray-300 rounded-lg shadow-sm p-2 focus:outline-none focus:border-indigo-500 transition duration-200 w-full max-w-lg"
#     value={@search_value}
#   />

#   <button
#       phx-click="clear_fields"
#       class="bg-gradient-to-r from-red-500 to-red-600 text-white py-3 px-8 rounded-full shadow-lg transform transition-transform duration-300 hover:scale-105"
#     >
#       Clear All
#     </button>
# </div>

# <div id="post-management">
#   <div
#     id="posts"
#     phx-update="stream"
#     class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6"
#   >
#     <div
#       :for={{post_id, post} <- @streams.posts}
#       class="border border-gray-200 rounded-lg p-4 shadow-lg bg-white transform transition-transform duration-300 hover:scale-105"
#       id={post_id}
#     >
#       <%= if post.post do %>
#         <h2 class="text-xl font-bold mb-2 text-gray-700 text-center"><%= post.post.title %></h2>

#         <div class="text-gray-600 text-sm text-center mb-2">
#           <strong>Post ID:</strong> <%= post.post.id %><br/>
#           <strong>Author Name:</strong> <%= post.post.user.username %><br/>
#           <strong>Author Email:</strong> <%= post.post.user.email %><br/>

#         </div>

#         <button phx-click="open_modal" phx-value-id={post_id} class="w-full">
#           <img
#             src={post.url}
#             class="w-full h-64 object-cover rounded-lg shadow-md mb-4"
#             alt={post.post.title}
#           />
#         </button>
#         <div class="text-center text-gray-500 mb-4">
#           <%= Blog.picture_filename(post.url) %> (<%= Path.extname(post.url) %>)
#         </div>
#       <% else %>
#         <h2 class="text-xl font-bold mb-2 text-gray-700 text-center">No post available</h2>
#         <button phx-click="open_modal" phx-value-id={post_id} class="w-full">
#           <img
#             src={post.url}
#             class="w-full h-64 object-cover rounded-lg shadow-md mb-4"
#             alt="No post"
#           />
#         </button>
#         <div class="text-center text-gray-500 mb-4">
#           <%= Blog.picture_filename(post.url) %> (<%= Path.extname(post.url) %>)
#         </div>
#       <% end %>

#       <div class="text-center">
#         <button
#           phx-click="delete_post"
#           phx-value-id={post_id}
#           class="bg-red-600 text-white py-2 px-4 rounded-lg hover:bg-red-700 transition-colors"
#         >
#           Delete
#         </button>
#       </div>
#     </div>
#   </div>


#   <%= if @show_modal do %>
#   <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center transition-opacity duration-300 ease-out">
#     <div class="bg-white rounded-lg shadow-lg transform transition-all duration-300 ease-out p-6 w-full max-w-lg relative">
#       <button
#         type="button"
#         phx-click="close_modal"
#         class="absolute top-2 right-2 bg-gray-100 hover:bg-gray-200 text-gray-600 p-1 rounded-full focus:outline-none"
#         aria-label="Close"
#       >
#         ✕
#       </button>

#       <h2 class="text-2xl font-semibold text-gray-800 mb-4 text-center">Photo Settings</h2>

#       <img
#         src={@photo.url}
#         class="w-full h-64 object-cover rounded-lg shadow-md mb-4 transition-transform hover:scale-105 duration-200 ease-in-out"
#       />

#       <form phx-submit="save_photo_to_post" class="space-y-6">
#         <%= if @photo.post_id == nil do %>
#           <div>
#             <label for="post" class="block text-sm font-medium text-gray-700 mb-2">Select a Post</label>
#             <select
#               id="post"
#               name="post_id"
#               class="w-full text-gray-700 bg-gray-100 border border-gray-300 rounded-md p-2 focus:ring-indigo-500 focus:border-indigo-500"
#               phx-change="post_selected"
#             >
#               <option value="">Select Post</option>
#               <%= for post <- @posts_without_pictures do %>
#                 <option value={post.id} selected={@selected_post_id == post.id}>
#                   <%= post.title %>
#                 </option>
#               <% end %>
#             </select>
#           </div>
#           <button
#             type="submit"
#             class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-4 rounded-md disabled:opacity-50 transition-colors duration-200"
#           >
#             Save
#           </button>
#         <% end %>

#         <div class="flex justify-end space-x-2">
#           <button
#             type="button"
#             phx-click="close_modal"
#             class="bg-gray-300 hover:bg-gray-400 text-gray-700 font-medium py-2 px-4 rounded-md transition-colors duration-200"
#           >
#             Close
#           </button>
#         </div>
#       </form>
#     </div>
#   </div>
# <% end %>

#   <%= if @show_create_modal do %>
#           <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
#             <div class="bg-white rounded-lg shadow-lg p-6 w-full max-w-lg">
#               <h3 class="text-2xl font-bold text-gray-800 mb-4">Add Photo to Post</h3>
#               <form phx-submit="save_photo" phx-change="validate">
#                 <div class="mb-6">
#                   <select
#                     id="post"
#                     name="post_id"
#                     class="w-full text-gray-700 bg-gray-100 border border-gray-300 rounded-md p-2"
#                   >
#                     <option value="">Without Post</option>
#                     <%= for post <- @posts_without_pictures do %>
#                       <option value={post.id} selected={@selected_post_id == post.id}>
#                         <%= post.title %>
#                       </option>
#                     <% end %>
#                   </select>
#                 </div>

#                 <div class="mb-6">
#                   <label for="photos" class="block text-gray-700">Photos</label>
#                   <div class="text-sm text-gray-500 mb-4">
#                     Add up to <%= @uploads.photos.max_entries %> photos
#                     (max <%= trunc(@uploads.photos.max_file_size / 1_000_000) %> MB )
#                   </div>

#                   <label
#                     class="block border-2 border-dashed border-blue-500 p-4 text-center bg-gray-100 rounded mb-4 cursor-pointer"
#                     phx-drop-target={@uploads.photos.ref}
#                   >
#                     <.live_file_input upload={@uploads.photos} class="hidden" />
#                     <span>Click to upload or drag and drop files here</span>
#                   </label>

#                   <.error :for={err <- upload_errors(@uploads.photos)}>
#                     <div class="text-red-500 text-sm mb-2"><%= Phoenix.Naming.humanize(err) %></div>
#                   </.error>

#                   <div :for={entry <- @uploads.photos.entries} class="mb-4">
#                     <.live_img_preview entry={entry} class="w-full mb-2 rounded" />
#                     <div class="h-2 bg-gray-300 rounded-full overflow-hidden mb-2">
#                       <div class="h-full bg-blue-500" style={"width: #{entry.progress}%"}></div>
#                     </div>
#                     <a
#                       phx-click="cancel"
#                       phx-value-ref={entry.ref}
#                       class="text-red-500 hover:underline text-sm"
#                     >
#                       Cancel
#                     </a>
#                   </div>
#                 </div>

#                 <div class="flex justify-end space-x-3">
#                   <button
#                     type="submit"
#                     class="bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-md"
#                   >
#                     Save
#                   </button>
#                   <button
#                     type="button"
#                     phx-click="set_close_create"
#                     class="bg-gray-300 hover:bg-gray-400 text-gray-700 font-medium py-2 px-4 rounded-md"
#                   >
#                     Close
#                   </button>
#                 </div>
#               </form>
#             </div>
#           </div>
#         <% end %>

# </div>

#     </div>
#     """
#   end

#   def handle_event("post_selected", %{"post_id" => post_id}, socket) do
#     {:noreply, assign(socket, :selected_post_id, post_id)}
#   end

#   def handle_event("save_photo_to_post", %{"post_id" => post_id}, socket) do
#     photo_url = socket.assigns.photo.url

#     if post_id != "" and photo_url != "" do
#       case Blog.update_post_with_photos(socket.assigns.selected_post_id, photo_url) do
#         {:ok, _post} ->

#              socket =
#           socket
#           |> put_flash(:info, "Photo successfully linked to post!")
#           |> assign(:show_modal, false)
#           |> stream_insert(:posts, Blog.get_picture_by_id(socket.assigns.photo.id), at: 0)

#           {:noreply, socket}
#         {:error, reason} ->
#           {:noreply,
#             socket
#             |> put_flash(:error, "Failed to update post: #{inspect(reason)}")
#           }
#       end
#     else
#       {:noreply,
#         socket
#         |> put_flash(:error, "Please select a post and ensure photo is available.")
#       }
#     end
#   end

#   def handle_event("open_modal", %{"id" => post_id}, socket) do
#     [_, photo_id] = String.split(post_id, "-")
#     photo = Blog.get_picture_by_id(photo_id)
#     {:noreply, assign(socket, show_modal: true, photo: photo )}
#   end

#   def handle_event("close_modal", _params, socket) do
#     {:noreply, assign(socket, :show_modal, false)}
#   end

#   def handle_event("search", %{"value" => query}, socket) do
#     posts_with_pictures = Blog.search_pictures(query, socket.assigns.sort_order)

#     socket =
#       socket
#       |> stream(:posts, posts_with_pictures, reset: true)
#       |> assign(:search_value, query)
#       |> assign(:query, query)

#     {:noreply, assign(socket, search: query)}
#   end

#   def handle_event("sort_order", %{"value" => order}, socket) do
#     sorted_posts = Blog.search_pictures(socket.assigns.search_value, order)

#     socket =
#       socket
#       |> assign(:sort_order, order)
#       |> stream(:posts, sorted_posts, reset: true)

#     {:noreply, socket}
#   end

#   def handle_event("clear_fields", _params, socket) do
#     posts_with_pictures = Blog.get_posts_with_pictures

#     socket =
#       socket
#       |> assign(:search_value, "")
#       |> stream(:posts, posts_with_pictures, reset: true)

#     {:noreply, socket}
#   end

#   def handle_event("validate", %{"post_id" => post_id}, socket) do
#     post_id = if post_id != "", do: String.to_integer(post_id), else: ""
#     photos_upload_errors =
#       Enum.map(socket.assigns.uploads.photos.entries, fn entry ->
#         if entry.valid?, do: nil, else: {:error, entry.client_name}
#       end)
#       |> Enum.reject(&is_nil/1)

#     socket =
#       socket
#       |> assign(:photos_upload_errors, photos_upload_errors)
#       |> assign(:selected_post_id, post_id)
#     {:noreply, socket}
#   end

#   def handle_event("cancel", %{"ref" => ref}, socket) do
#     {:noreply, cancel_upload(socket, :photos, ref)}
#   end

#   def handle_event("open_create_modal", _params, socket) do
#     {:noreply, assign(socket, show_create_modal: true, selected_post_id: "")}
#   end

#   def handle_event("set_close_create", _params, socket) do
#     {:noreply, assign(socket, show_create_modal: false, selected_post_id: "")}
#   end

#   def handle_event("save_photo", %{"post_id" => post_id}, socket) do
#     photo_locations =
#       consume_uploaded_entries(socket, :photos, fn meta, entry ->
#         case Blog.upload_photo_to_s3(meta, entry) do
#           {:ok, url_path} -> {:ok, url_path}
#           {:error, reason} -> {:error, reason}
#         end
#       end)
#       |> List.first()

#     if post_id == "" do
#       case Blog.create_picture(%{url: photo_locations}) do
#         {:ok, picture} ->
#           MySuperAppWeb.Endpoint.broadcast!("posts", "post_added", %{post: Blog.get_picture_by_id(picture.id)})

#           socket =
#             socket
#             |> assign(:show_create_modal, false)

#           {:noreply, socket}

#         {:error, changeset} ->
#           {:noreply, assign(socket, :form, changeset)}
#       end

#     else
#       case Blog.update_post_with_photos(post_id, photo_locations) do
#         {:ok, updated_post} ->
#           post = Blog.get_post!(updated_post.id)
#           IO.inspect(updated_post)
#           updated_post1 = Blog.get_picture_by_id(post.picture.id)
#           MySuperAppWeb.Endpoint.broadcast!("posts", "post_added", %{post: updated_post1})

#           socket =
#             socket
#             |> assign(:show_create_modal, false)
#             |> assign(:selected_post_id, "")
#             |> assign(:form, Blog.change_post(%Post{}))

#           {:noreply, socket}

#         {:error, changeset} ->
#           {:noreply, assign(socket, :form, changeset)}
#       end
#     end
#   end

#   def handle_event("delete_post", %{"id" => id}, socket) do
#     [_, post_id] = String.split(id, "-")
#     post_id = String.to_integer(post_id)
#     post = MySuperApp.Blog.get_picture_by_id(post_id)
#     MySuperAppWeb.Endpoint.broadcast!("posts", "post_deleted", %{post: post})
#     Blog.delete_picture_by_id(post_id)
#     {:noreply, socket}
#   end

#   def handle_info(%{event: "post_added", payload: %{post: post}}, socket) do
#     socket = stream_insert(socket, :posts, post, at: 0)
#     {:noreply, socket}
#   end

#   def handle_info(%{event: "post_deleted", payload: %{post: post}}, socket) do
#     socket = stream_delete(socket, :posts, post)
#     {:noreply, socket}
#   end

# end
