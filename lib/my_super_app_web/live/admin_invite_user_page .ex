defmodule MySuperAppWeb.InviteUserAdmin do
  @moduledoc false
  use MySuperAppWeb, :surface_live_view
  alias MySuperApp.CasinosAdmins
  alias Moon.Design.Table
  alias Moon.Design.Table.Column
  alias Moon.Design.Button
  alias MySuperApp.{User, Accounts}
  alias Moon.Design.Modal
  alias Moon.Design.Pagination
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft
  alias Moon.Design.Search
  alias Moon.Design.Dropdown
  alias Moon.Design.Chip

  data(current_page, :integer, default: 1)
  data(limit, :integer, default: 10)

  def mount(_params, session, socket) do
    current_user = MySuperApp.Accounts.get_user_by_session_token(session["user_token"])
    operator_id = current_user.operator_id
    total_users = CasinosAdmins.count_users(operator_id)
    all_roles = CasinosAdmins.all_roles()

    {
      :ok,
      assign(
        socket,
        sort: [name: "ASC"],
        users: CasinosAdmins.get_users(1, 10, operator_id),
        form: to_form(User.changeset(%User{}, %{})),
        selected: nil,
        id: nil,
        filter: "",
        total_pages: ceil(total_users / 10),
        total_users: total_users,
        operator_id: operator_id,
        all_roles: all_roles,
        role_id: nil,
        selected_user: nil,
        selected_role: nil,
        current_user: current_user,
        sort_key: nil,
        sort_dir: nil,
        selected_role_id: nil
      )
    }
  end

  def render(assigns) do
    ~F"""
    <Search
      id="default-search"
      {=@filter}
      on_keyup="change_filter"
      options={[]}
      class="pb-8"
      prompt="Search by username"
    >
    <Dropdown id="1" disabled >
    <Dropdown.Trigger disabled />
    </Dropdown></Search>

    <div class="container mx-auto p-6 text-black">
      <div class="flex justify-between items-center mb-6">
        <div class="flex gap-4">
          <form phx-change="role_changed" class="flex items-center">
            <label for="role" class="mr-2 text-sm font-medium text-blue-600">Role:</label>
            <select
              id="role"
              name="role"
              class="pe-8 bg-white border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 p-2.5"
            >
              <option value="">All Roles</option>
              {#for role <- @all_roles}
                <option value={role.id} selected={@selected_role_id == role.id}>
                  {role.name}
                </option>
              {/for}
            </select>
          </form>
        </div>

        <form phx-change="users_per_page_changed" class="flex items-center">
          <label for="users_per_page" class="mr-2 text-sm font-medium text-blue-600">Users per page:</label>
          <select
            id="users_per_page"
            name="users_per_page"
            class="pe-8 bg-white border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 p-3.5"
          >
            <option value={3} selected={@limit == 3}>3</option>
            <option value={5} selected={@limit == 5}>5</option>
            <option value={7} selected={@limit == 7}>7</option>
            <option value={10} selected={@limit == 10}>10</option>
          </select>
        </form>
      </div>

      <div class="flex items-center justify-between p-2">
      <div class="text-blue-600 whitespace-nowrap">
        Page {@current_page} of {@total_pages}
      </div>

      <div class="flex items-center space-x-2 ml-auto">
        <Pagination
        id="with_buttons"
        total_pages={@total_pages}
        value={@current_page}
        on_change="handle_paging_click"
        class="flex items-center space-x-2"
      >
        <Pagination.PrevButton class="border-none p-2 text-blue-600 dark:text-blue-300 bg-gray-100 dark:bg-gray-800 rounded">
          <ControlsChevronLeft class="text-moon-24 rtl:rotate-180" />
        </Pagination.PrevButton>

        <Pagination.NextButton class="border-none p-2 text-blue-600 dark:text-blue-300 bg-gray-100 dark:bg-gray-800 rounded">
          <ControlsChevronRight class="text-moon-24 rtl:rotate-180" />
        </Pagination.NextButton>
      </Pagination>
    </div>
    </div>

      <Table {=@sort} items={user <- @users} sorting_click="handle_sorting_click" is_cell_border>
        <Table.Column name="id" label="ID" sortable>
          {user.id}
        </Table.Column>
        <Table.Column name="username" label="Name" sortable>
          {user.username}
        </Table.Column>
        <Table.Column name="created_at" label="Created at" sortable>
          {Timex.format!(user.inserted_at, "%b %d, %Y, %H:%M:%S", :strftime)}
        </Table.Column>
        <Table.Column name="updated_at" label="Updated at" sortable>
          {Timex.format!(user.updated_at, "%b %d, %Y, %H:%M:%S", :strftime)}
        </Table.Column>
        <Table.Column name="role" label="Role" sortable>
          {CasinosAdmins.get_role!(user.role_id).name}
        </Table.Column>
        <Table.Column name="operator" label="Operator" sortable>
          {CasinosAdmins.get_operator(user.operator_id).name}
        </Table.Column>
        <Column label="Actions" class="text-center">
          <div class="flex gap-2 justify-center">
            <Button
              disabled={CasinosAdmins.disable_edit_button?(@current_user, user)}
              on_click={"modal_open_edit#{user.id}"}
              class="bg-blue-600 hover:bg-blue-700 text-white py-1 px-3 rounded-lg text-sm transition-all"
            >
              Edit Role
            </Button>
            <Button
              disabled={CasinosAdmins.disable_delete_button?(@current_user, user)}
              on_click={"modal_open_delete#{user.id}"}
              class="bg-red-600 hover:bg-red-700 text-white py-1 px-3 rounded-lg text-sm transition-all"
            >
              Delete
            </Button>
          </div>
        </Column>
      </Table>

      <Modal id="modal_delete">
        <Modal.Backdrop class="bg-black bg-opacity-50 fixed inset-0" />
        <Modal.Panel class="bg-white rounded-lg shadow-lg max-w-lg mx-auto mt-20">
          <div class="p-4 border-b-2 border-gray-300">
            <h3 class="text-xl font-semibold mb-4 text-gray-800">Are you sure you want to delete user {@selected}?</h3>
            <div class="flex justify-end gap-2">
              <Button
                on_click={"delete_#{@id}"}
                class="bg-red-600 hover:bg-red-700 text-white py-2 px-4 rounded-lg transition-all"
              >
                Delete
              </Button>
              <Button
                on_click="set_close_drawer"
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 py-2 px-4 rounded-lg transition-all"
              >
                Close
              </Button>
            </div>
          </div>
        </Modal.Panel>
      </Modal>

      <Modal id="modal_edit_role">
      <Modal.Backdrop class="bg-black bg-opacity-50 fixed inset-0" />
      <Modal.Panel class="w-full bg-white rounded-lg shadow-lg min-h-[90vh] flex flex-col">
        <div class="p-6 border-b border-gray-200 flex-grow">
          <h3 class="text-2xl font-bold text-gray-800 mb-4 overflow-y-auto">Edit Role for {@selected}</h3>
          <div class="mb-6">
            <Dropdown id="dropdown-role" on_change="update_role">
              <Dropdown.Options
                titles={@all_roles
                  |> Enum.filter(&(&1.permission_id > @current_user.role.permission.id))
                  |> Enum.map(& &1.name)}
                class="max-h-40 overflow-y-auto"
              />
              <Dropdown.Trigger :let={value: value}>
                <Chip class="w-full text-gray-700 bg-gray-100 border border-gray-300 rounded-md p-2 text-left">
                  {value || "Choose role..."}
                </Chip>
              </Dropdown.Trigger>
            </Dropdown>
          </div>
        </div>
        <div class="p-6 border-t border-gray-200 flex justify-end space-x-3">
          <Button
            on_click="set_close_drawer"
            class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-md transition-all"
          >
            Save
          </Button>
          <Button
            on_click="set_close_drawer"
            class="bg-gray-300 hover:bg-gray-400 text-gray-700 font-medium py-2 px-4 rounded-md transition-all"
          >
            Close
          </Button>
        </div>
      </Modal.Panel>
    </Modal>
    </div>
    """
  end


  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     assign(socket,
       current_page: current_page,
       users:
       CasinosAdmins.get_users(
           current_page,
           socket.assigns.limit,
           socket.assigns.operator_id,
           socket.assigns.role_id,
           socket.assigns.sort_key,
           socket.assigns.sort_dir
         )
     )}
  end

  def handle_event("users_per_page_changed", %{"users_per_page" => users_per_page}, socket) do
    users_per_page = String.to_integer(users_per_page)

    users = CasinosAdmins.get_users(1, users_per_page, socket.assigns.operator_id)
    total_users = CasinosAdmins.count_users(socket.assigns.operator_id)

    {:noreply,
     assign(socket,
       current_page: 1,
       limit: users_per_page,
       users: users,
       total_pages: ceil(total_users / users_per_page)
     )}
  end

  def handle_event("modal_open_delete" <> user_id, _params, socket) do
    Modal.open("modal_delete")
    selected = Accounts.get_user!(user_id)

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

  def handle_event("modal_open_edit" <> user_id, _params, socket) do
    Modal.open("modal_edit_role")
    selected_user = Accounts.get_user!(user_id)

    {:noreply,
     assign(socket,
       selected: selected_user.username,
       selected_user: selected_user
     )}
  end

  def handle_event("update_role", %{"value" => role_name}, socket) do
    selected_user = socket.assigns.selected_user
    role = CasinosAdmins.get_role_by_name(role_name)

    case Accounts.update_user_role(selected_user, role.id) do
      {:ok, _user} ->
        Modal.close("modal_edit_role")

        users =
          CasinosAdmins.get_users(socket.assigns.current_page, socket.assigns.limit, socket.assigns.operator_id)

        total_users = CasinosAdmins.count_users(socket.assigns.operator_id)

        {:noreply,
         assign(socket,
           users: users,
           total_users: total_users,
           total_pages: ceil(total_users / socket.assigns.limit),
           selected_user: nil
         )
         |> put_flash(:info, "User role updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("set_close_drawer", _, socket) do
    Modal.close("modal_edit_role")

    {:noreply, socket}
  end

  def handle_event("delete_" <> id, _, socket) do
    user = Accounts.get_user!(id)

    case Accounts.delete_user(user) do
      {:ok, _} ->
        users =
          CasinosAdmins.get_users(socket.assigns.current_page, socket.assigns.limit, socket.assigns.operator_id)

        total_users = CasinosAdmins.count_users(socket.assigns.operator_id)

        {:noreply,
         assign(socket,
           id: nil,
           users: users,
           selected: nil,
           total_pages: ceil(total_users / socket.assigns.limit),
           total_users: total_users
         )
         |> put_flash(:info, "User deleted successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event(
        "handle_sorting_click",
        %{"sort-dir" => _sort_dir, "sort-key" => sort_key},
        socket
      ) do
    sort_dir =
      if socket.assigns.sort_key == sort_key and socket.assigns.sort_dir == "asc",
        do: "desc",
        else: "asc"

    {:noreply,
     assign(socket,
       sort_key: sort_key,
       sort_dir: sort_dir,
       users:
       CasinosAdmins.get_users(
           socket.assigns.current_page,
           socket.assigns.limit,
           socket.assigns.operator_id,
           socket.assigns.role_id,
           sort_key,
           sort_dir
         )
     )}
  end

  def handle_event("change_filter", %{"value" => ""}, socket) do
    total_users = CasinosAdmins.count_users(socket.assigns.operator_id, socket.assigns.role_id)
    users = CasinosAdmins.get_users(1, socket.assigns.limit, socket.assigns.operator_id, socket.assigns.role_id, socket.assigns.sort_key, socket.assigns.sort_dir)

    {:noreply,
     assign(socket,
       filter: "",
       users: users,
       total_users: total_users,
       total_pages: ceil(total_users / socket.assigns.limit),
       current_page: 1
     )}
  end

  def handle_event("change_filter", %{"value" => filter}, socket) do
    {users, total_users, total_pages} =
      MySuperApp.CasinosAdmins.filter_users(
        filter,
        socket.assigns.operator_id,
        socket.assigns.role_id,
        socket.assigns.limit,
        (socket.assigns.current_page - 1) * socket.assigns.limit
      )

    {:noreply,
     assign(socket,
       filter: filter,
       users: users,
       total_users: total_users,
       total_pages: total_pages
     )}
  end

  def handle_event("role_changed", %{"role" => role_id}, socket) do
    role_id = if role_id == "", do: nil, else: String.to_integer(role_id)
    users = CasinosAdmins.get_users(1, socket.assigns.limit, socket.assigns.operator_id, role_id)
    total_users = CasinosAdmins.count_users(socket.assigns.operator_id, role_id)

    {:noreply,
     assign(socket,
       selected_role_id: role_id,
       role_id: role_id,
       current_page: 1,
       users: users,
       total_users: total_users,
       total_pages: ceil(total_users / socket.assigns.limit)
     )}
  end

end
