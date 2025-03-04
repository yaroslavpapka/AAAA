defmodule MySuperAppWeb.UsersPage do
  @moduledoc false
  use MySuperAppWeb, :surface_live_view
  alias Moon.Design.Table
  alias Moon.Design.Table.Column
  alias Moon.Design.{Button, Drawer, Form}
  alias Moon.Design.Form.Input
  alias Moon.Design.Form.Field
  alias Moon.Design.Button
  alias MySuperApp.{User, Repo, Accounts}
  alias Moon.Design.Modal
  alias Moon.Design.Button
  alias Moon.Design.Pagination
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  data(users, :any)
  data(current_page, :integer, default: 1)
  data(limit, :integer, default: 10)

  def mount(_params, _session, socket) do
    {
      :ok,
      assign(
        socket,
        users:
          User
          |> Repo.all()
          |> Enum.map(&(&1 |> Map.from_struct())),
        form: to_form(User.changeset(%User{}, %{})),
        selected: nil,
        id: nil,
        is_drower_open?: false,
        temp_user: %{username: "", email: ""},
        is_new_user_drawer_open?: false,
        new_user_form: to_form(User.changeset(%User{}, %{})),
        new_user_params: %{}
      )
    }
  end

  def render(assigns) do
    ~F"""
    <div class="container mx-auto p-6 text-black">
      <Button
        on_click="add_new_user"
        class="bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded-lg mb-4"
      >Add new user</Button> <Pagination
        id="with_buttons"
        total_pages={ceil(Enum.count(Repo.all(User)) / @limit)}
        value={@current_page}
        on_change="handle_paging_click"
      >
        <Pagination.PrevButton class="border-none">
          <ControlsChevronLeft class="text-moon-24 rtl:rotate-180" />
        </Pagination.PrevButton>
        <Pagination.Pages /> <Pagination.NextButton class="border-none">
          <ControlsChevronRight class="text-moon-24 rtl:rotate-180" />
        </Pagination.NextButton>
      </Pagination>
      <Table items={user <- get_models_10(assigns)} row_click="single_row_click" {=@selected}>
        <Column label="Last updated" class="text-center">
          {user.updated_at}
        </Column>
        <Column label="User Name" class="text-center">
          {user.username}
        </Column>
        <Column label="Email" class="text-center">
          {user.email}
        </Column>
        <Column label="Actions" class="text-center">
          <div class="flex gap-2">
            <Button
              as="a"
              href={"/users/edit/#{user.id}"}
              class="bg-green-500 hover:bg-green-600 text-white py-1 px-2 rounded-lg text-sm"
            >Edit</Button> <Button
              on_click={"set_open_#{user.id}"}
              class="bg-yellow-500 hover:bg-yellow-600 text-white py-1 px-2 rounded-lg text-sm"
            >Edit</Button> <Button
              on_click={"modal_open_delete#{user.id}"}
              class="bg-red-500 hover:bg-red-600 text-white py-1 px-2 rounded-lg text-sm"
            >Delete</Button>
          </div>
        </Column>
      </Table>
      <Modal id="modal_delete">
        <Modal.Backdrop /> <Modal.Panel>
          <div class="p-4 border-b-2 border-gray-300">
            <h3 class="text-xl font-semibold mb-4">Are you sure you want to delete user {@selected}?</h3> <div class="flex justify-end gap-2">
              <Button
                on_click={"delete_#{@id}"}
                class="bg-red-500 hover:bg-red-600 text-white py-2 px-4 rounded-lg"
              >Delete</Button> <Button
                on_click="set_close_drower"
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 py-2 px-4 rounded-lg"
              >Close</Button>
            </div>
          </div>
        </Modal.Panel>
      </Modal>
      <Drawer id="drawer_upd" on_close="set_close" is_open={@is_drower_open?}>
        <Drawer.Panel>
          <div>Are you sure to change user {@temp_user.username}?</div> <Form for={@form} change="validate" submit="edit">
            <Field field={:username} class="mb-4">
              <Input placeholder="Username" value={@temp_user.username} />
            </Field>
            <Field field={:email} class="mb-4">
              <Input placeholder="Email" value={@temp_user.email} />
            </Field>
            <div class="flex justify-end gap-2">
              <Button type="submit" class="bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded-lg">Save</Button> <Button
                on_click="set_close"
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 py-2 px-4 rounded-lg"
              >Close</Button>
            </div>
          </Form>
        </Drawer.Panel>
      </Drawer>
      <Drawer id="drawer_new_user" on_close="set_close_new_user" is_open={@is_new_user_drawer_open?}>
        <Drawer.Panel>
          <Form for={@new_user_form} change="validate_new_user" submit="save_new_user">
            <Field field={:username} class="mb-4">
              <Input placeholder="Username" />
            </Field>
            <Field field={:email} class="mb-4">
              <Input placeholder="Email" />
            </Field>
            <div class="flex justify-end gap-2">
              <Button type="submit" class="bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded-lg">Save</Button> <Button
                on_click="set_close_new_user"
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 py-2 px-4 rounded-lg"
              >Close</Button>
            </div>
          </Form>
        </Drawer.Panel>
      </Drawer>
    </div>
    """
  end

  def get_all_models() do
    User
    |> Repo.all()
    |> Enum.map(&Map.from_struct/1)
    |> Enum.sort_by(&max(&1.inserted_at, &1.updated_at))
    |> Enum.reverse()
  end

  def get_models_10(assigns) do
    all_models = get_all_models()
    current_page = assigns.current_page
    limit = assigns.limit

    offset = (current_page - 1) * limit

    all_models
    |> Enum.slice(offset..(offset + limit - 1))
  end

  def handle_event("validate_new_user", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, new_user_form: form, new_user_params: params)}
  end

  def handle_event("add_new_user", _, socket) do
    Drawer.open("drawer_new_user")

    {:noreply,
     assign(socket, is_new_user_drawer_open?: true, new_user_params: %{username: "", email: ""})}
  end

  def handle_event("set_close_new_user", _, socket) do
    Drawer.close("drawer_new_user")

    {:noreply,
     assign(socket,
       new_user_form: to_form(User.changeset(%User{}, %{})),
       is_new_user_drawer_open?: false
     )}
  end

  def handle_event("single_row_click", _, socket) do
    {:noreply, socket}
  end

  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     socket
     |> assign(current_page: current_page)}
  end

  def handle_event("modal_open_delete" <> user_id, _params, socket) do
    Modal.open("modal_delete")
    selected = Repo.get(User, user_id)

    {:noreply,
     assign(socket,
       id: user_id,
       selected: selected.username
     )}
  end

  def handle_event("set_close_drower", _, socket) do
    Modal.close("modal_delete")

    {:noreply, socket}
  end

  def handle_event("set_open_" <> user_id, _, socket) do
    Drawer.open("drawer_upd")

    {:noreply,
     assign(socket,
       id: user_id,
       is_drower_open?: true,
       temp_user: Repo.get(User, user_id)
     )}
  end

  def handle_event("set_close", _, socket) do
    Drawer.close("drawer_upd")

    {:noreply,
     assign(socket,
       selected: nil,
       form: to_form(User.changeset(%User{}, %{})),
       is_drower_open?: false
     )}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    # Accounts.change_user(socket.assigns.id, params)

    {:noreply,
     assign(socket,
       form: form,
       temp_user: %{username: params["username"], email: params["email"]}
     )}
  end

  def handle_event("edit", %{"user" => params}, socket) do
    case Accounts.change_user(socket.assigns.id, params) do
      {:ok, _user} ->
        {:noreply,
         assign(socket,
           is_drower_open?: false,
           current_page: 1,
           selected: socket.assigns.id
         )
         |> put_flash(:info, "user #{params["username"]} updated")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("save_new_user", %{"user" => params}, socket) do
    changeset = User.changeset(%User{}, params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        Drawer.close("drawer_new_user")

        {:noreply,
         assign(socket,
           users: User |> Repo.all() |> Enum.map(&(&1 |> Map.from_struct())),
           selected: user.id,
           current_page: 1,
           new_user_form: to_form(User.changeset(%User{}, %{}))
         )
         |> put_flash(:info, "New user added ")}

      {:error, _changeset} ->
        {:noreply, assign(socket, new_user_form: to_form(changeset))}
    end
  end

  def handle_event("delete_" <> user_id, _params, socket) do
    case Accounts.delete_user(Repo.get(User, user_id)) do
      {:ok, _user} ->
        Modal.close("modal_delete")

        {:noreply,
         assign(socket,
           users: User |> Repo.all() |> Enum.map(&(&1 |> Map.from_struct())),
           current_page: 1,
           form: to_form(User.changeset(%User{}, %{}))
         )
         |> put_flash(:info, "user deleted")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("set_page", %{"value" => page}, socket) do
    socket = assign(socket, page: String.to_integer(page))
    {:noreply, socket}
  end
end
