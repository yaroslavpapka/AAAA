defmodule MySuperAppWeb.RolesPage do
  use MySuperAppWeb, :surface_live_view
  alias Moon.Design.{Button, Table, Modal, Drawer, Form, Pagination}
  alias Moon.Design.Table.Column
  alias Moon.Design.Form.{Input, Field}
  alias MySuperApp.{CasinosAdmins, Role}
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  @moduledoc """
  Module for rendering admin page
  """

  def mount(_params, session, socket) do
    roles = CasinosAdmins.get_roles(1, 10, nil)
    total_roles = CasinosAdmins.count_roles(nil)
    changeset = Role.changeset(%Role{}, %{})
    current_user = MySuperApp.Accounts.get_user_by_session_token(session["user_token"])

    form =
      %Role{}
      |> Role.changeset(%{})
      |> to_form()

    operator_id =
      MySuperApp.Accounts.get_user_by_session_token(session["user_token"]).operator_id

    {:ok,
     assign(socket,
       roles: roles,
       role: %Role{},
       sort: [name: "ASC"],
       operator_name: nil,
       add_role_modal_active: false,
       form: form,
       changeset: changeset,
       operator_id: operator_id,
       operator: CasinosAdmins.all_models,
       operators: MySuperApp.CasinosAdmins.all_models(),
       selected: nil,
       current_page: 1,
       roles_per_page: 10,
       total_pages: ceil(total_roles / 10),
       selected_operator_id: nil,
       delete_modal_active: nil,
       role_id: nil,
       current_user: current_user,
       sort_key: nil,
       sort_dir: :asc,
       permissions: CasinosAdmins.list_permissions,
       selected_permissions: []
     )}
  end

  def render(assigns) do
    ~F"""
    <div class="container mx-auto p-6 text-black">
      <div class="flex justify-between items-center mb-4">
        <div>
          <form phx-change="operator_changed">
            <select
              name="operator"
              class="pe-8 bg-white border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2.5"
            >
              <option value="">All Operators</option> {#for operator <- @operators}
                <option value={operator.id} selected={@selected_operator_id == operator.id}>{operator.name}</option>
              {/for}
            </select>
          </form>
        </div>
        <div class="flex gap-4">
          <div>
            <form phx-change="roles_per_page_changed">
              <select
                name="roles_per_page"
                class="pe-8 bg-white border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2.5"
              >
                <option value={3} selected={@roles_per_page == 3}>3</option> <option value={5} selected={@roles_per_page == 5}>5</option> <option value={7} selected={@roles_per_page == 7}>7</option> <option value={10} selected={@roles_per_page == 10}>10</option>
              </select>
            </form>
          </div>
          <Button
            class="bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded-lg"
            on_click="open_add_role_modal"
          >Add New Role</Button>
        </div>
      </div>
      <div class="w-full gap-4">
        <Table
          {=@sort}
          items={role <- @roles}
          row_click="row_click"
          {=@selected}
          sorting_click="handle_sorting_click"
        >
          <Column name="id" label="#">
            {role.id}
          </Column>
          <Column name="name" label="Name" sortable>
            {role.name}
          </Column>
          <Column label="Operator">
            {CasinosAdmins.get_operator_name(role.operator_id)}
          </Column>
          <Column label="Inserted at" sortable>
            {role.inserted_at}
          </Column>
          <Column label="Updated at" sortable>
            {role.updated_at}
          </Column>
        </Table>
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
      <Modal id="add_role_modal" is_open={@add_role_modal_active} on_close="close_add_role_modal">
      <Modal.Backdrop class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" />
      <Modal.Panel class="relative bg-white rounded-lg shadow-lg max-w-md mx-auto mt-24">
        <div class="p-6 border-b border-gray-200">
          <h3 class="text-2xl font-bold mb-4">Add New Role</h3>
          <Form for={@form} change="add_validate" submit="add_role">
            <Field field={:name} label="Role Name" class="mb-4">
              <Input
                placeholder="Role Name"
                class="w-full p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </Field>
            <Field field={:operator_id} label="Operator" class="mb-4">
              <Input
                readonly
                placeholder={CasinosAdmins.get_operator_name(@operator_id)}
                class="w-full p-2 border border-gray-300 rounded-lg bg-gray-100 cursor-not-allowed"
              />
            </Field>
            <Field field={:permissions} label="Permissions" class="mb-4">
              <select
                name="role[permissions][]"
                multiple
                class="w-full p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {#for permission <- @permissions}
                  <option value={permission.id} selected={permission.id in @selected_permissions}>
                    {permission.name}
                  </option>
                {/for}
              </select>
            </Field>
            <div class="flex justify-end gap-2">
              <Button
                type="submit"
                class="bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >Save</Button>
              <Button
                on_click="close_add_modal_by_click"
                class="bg-gray-400 hover:bg-gray-500 text-gray-900 py-2 px-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-500"
              >Close</Button>
            </div>
          </Form>
        </div>
      </Modal.Panel>
    </Modal>
      <Drawer id="update_role" is_open={@selected} on_close="close_add_modal_by_click">
        <Drawer.Panel class="fixed inset-0 overflow-hidden">
          <div class="fixed inset-y-0 left-0 flex max-w-full pr-10 z-50">
            <div class="w-screen max-w-md h-full bg-white shadow-lg rounded-lg">
              <div class="p-6">
                <h3 class="text-2xl font-bold mb-6 text-gray-900">Edit Role</h3> <Form for={@form} change="edit_validate" submit="update_role">
                  <Field field={:name} label="Role Name" class="mb-6">
                    <Input
                      class="mt-1 block w-full rounded-md border-2 border-blue-300 bg-white shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-500 focus:ring-opacity-50 sm:text-sm"
                      placeholder="Role Name"
                      value={@role.name}
                    />
                  </Field>
                  <Field field={:operator_id} label="Operator" class="mb-6">
                    <Input
                      class="mt-1 block w-full rounded-md border-2 border-gray-300 bg-gray-100 shadow-sm cursor-not-allowed focus:border-blue-500 focus:ring focus:ring-blue-500 focus:ring-opacity-50 sm:text-sm"
                      readonly
                      placeholder={CasinosAdmins.get_operator_name(@operator_id)}
                    />
                  </Field>
                  <div class="flex justify-between gap-4">
                    <Button
                      disabled={should_disable_buttons?(@role.name)}
                      type="submit"
                      class="bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      Update
                    </Button>
                    <Button
                      disabled={should_disable_buttons?(@role.name)}
                      on_click="modal_open_delete"
                      type="button"
                      class="bg-red-600 hover:bg-red-700 text-white py-2 px-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-red-500"
                    >
                      Delete
                    </Button>
                    <Button
                      on_click="close_update_drawer_by_click"
                      type="button"
                      class="bg-gray-400 hover:bg-gray-500 text-gray-900 py-2 px-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-500"
                    >
                      Close
                    </Button>
                  </div>
                </Form>
              </div>
            </div>
          </div>
        </Drawer.Panel>
      </Drawer>
      <Modal id="modal_delete" is_open={@delete_modal_active} on_close="set_close_delete_modal">
        <Modal.Backdrop class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" /> <Modal.Panel class="relative bg-white rounded-lg shadow-lg max-w-sm mx-auto mt-24">
          <div class="p-6 border-b border-gray-200">
            <h3 class="text-2xl font-bold mb-6 text-gray-900">Are you sure you want to delete role {@selected}?</h3> <div class="flex justify-end gap-4">
              <Button
                on_click="confirm_delete"
                class="bg-red-600 hover:bg-red-700 text-white py-2 px-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                Delete
              </Button>
              <Button
                on_click="set_close_delete_modal"
                class="bg-gray-400 hover:bg-gray-500 text-gray-900 py-2 px-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-500"
              >
                Close
              </Button>
            </div>
          </div>
        </Modal.Panel>
      </Modal>
    </div>
    """
  end

  def handle_event("open_add_role_modal", _, socket) do
    Modal.open("add_role_modal")

    {:noreply,
     assign(socket,
       add_role_modal_active: true,
       form: to_form(Role.changeset(%Role{}, %{}))
     )}
  end

  def handle_event("add_validate", %{"role" => params}, socket) do
    form =
      %Role{}
      |> Role.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("add_role", %{"role" => role_params}, socket) do
    IO.inspect(String.to_integer(List.first(role_params["permissions"])))
    role_params = %{
      name: role_params["name"],
      operator_id: socket.assigns.operator_id,
      permission_id: String.to_integer(List.first(role_params["permissions"]))
    }

    case CasinosAdmins.create_role(role_params) do
      {:ok, _role} ->
        Modal.close("add_role_modal")

        {:noreply,
         socket
         |> put_flash(:info, "Role created!")
         |> assign(
           roles:
             CasinosAdmins.get_roles(
               socket.assigns.current_page,
               socket.assigns.roles_per_page,
               socket.assigns.selected_operator_id
             ),
           selected: nil,
           add_role_modal_active: false
         )}

      {:error, _reason} ->
        {:noreply,
         assign(
           socket
           |> put_flash(:error, "Please, firstly change role for all of user with this role!"),
           add_role_modal_active: false
         )}
    end
  end


  def handle_event("handle_sorting_click", %{"sort-key" => sort_key}, socket) do
    sort_key_atom = String.to_atom(sort_key)

    new_sort_dir =
      case socket.assigns.sort_dir do
        :asc -> :desc
        :desc -> :asc
        _ -> :asc
      end

    roles = CasinosAdmins.get_roles(
      socket.assigns.current_page,
      socket.assigns.roles_per_page,
      socket.assigns.selected_operator_id,
      sort_key_atom,
      new_sort_dir
    )

    {:noreply,
     assign(socket,
       sort_key: sort_key_atom,
       sort_dir: new_sort_dir,
       roles: roles
     )}
  end

  def handle_event("close_add_modal_by_click", _, socket) do
    Modal.close("add_role_modal")
    {:noreply, assign(socket, add_role_modal_active: false)}
  end

  def handle_event("modal_open_delete", _params, socket) do
    Modal.open("modal_delete")

    {:noreply,
     assign(socket,
       role_id: socket.assigns.selected,
       selected: socket.assigns.role.name
     )}
  end

  def handle_event("confirm_delete", _, socket) do
    role = socket.assigns.role

    case CasinosAdmins.delete_role(role) do
      {:ok, _role} ->
        Modal.close("modal_delete")

        {:noreply,
         socket
         |> put_flash(:info, "Role deleted!")
         |> assign(
           roles:
           CasinosAdmins.get_roles(
               socket.assigns.current_page,
               socket.assigns.roles_per_page,
               socket.assigns.selected_operator_id
             ),
           total_pages:
             ceil(
              CasinosAdmins.count_roles(socket.assigns.selected_operator_id) / socket.assigns.roles_per_page
             ),
           selected: nil,
           delete_modal_active: false
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("set_close_delete_modal", _, socket) do
    Modal.close("modal_delete")

    {:noreply, socket}
  end

  def handle_event("close_add_role_modal", _, socket) do
    {:noreply, assign(socket, form: to_form(Role.changeset(%Role{}, %{})))}
  end

  def handle_event("row_click", %{"selected" => selected}, socket) do
    role = CasinosAdmins.get_role!(selected)
    {:noreply, assign(socket, selected: selected, role: role)}
  end

  def handle_event("update_role", %{"role" => role_params}, socket) do
    role_params = Map.put(role_params, "operator_id", socket.assigns.operator_id)

    case CasinosAdmins.update_role(socket.assigns.selected, role_params) do
      {:ok, _role} ->
        {:noreply,
         socket
         |> put_flash(:info, "Role updated!")
         |> assign(
           roles:
           CasinosAdmins.get_roles(
               socket.assigns.current_page,
               socket.assigns.roles_per_page,
               socket.assigns.selected_operator_id
             ),
           selected: nil
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("edit_validate", %{"role" => params}, socket) do
    form =
      socket.assigns.role
      |> Role.changeset(params)
      |> Map.put(:action, :update)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("close_update_drawer_by_click", _, socket) do
    Drawer.close("update_role")
    {:noreply, assign(socket, selected: nil)}
  end

  def handle_event("handle_paging_click", %{"value" => page}, socket) do
    page = String.to_integer(page)
    roles = CasinosAdmins.get_roles(page, socket.assigns.roles_per_page, socket.assigns.selected_operator_id)
    total_roles = CasinosAdmins.count_roles(socket.assigns.selected_operator_id)

    {:noreply,
     assign(socket,
       current_page: page,
       roles: roles,
       total_pages: ceil(total_roles / socket.assigns.roles_per_page)
     )}
  end

  def handle_event("operator_changed", %{"operator" => operator_id}, socket) do
    operator_id = if operator_id == "", do: nil, else: String.to_integer(operator_id)

    new_roles = CasinosAdmins.get_roles(1, socket.assigns.roles_per_page, operator_id)
    total_roles_count = CasinosAdmins.count_roles(operator_id)

    {:noreply,
     assign(socket,
       selected_operator_id: operator_id,
       roles: new_roles,
       current_page: 1,
       total_pages: ceil(total_roles_count / socket.assigns.roles_per_page)
     )}
  end

  def handle_event("roles_per_page_changed", %{"roles_per_page" => roles_per_page}, socket) do
    roles_per_page = String.to_integer(roles_per_page)

    roles =
      CasinosAdmins.get_roles(socket.assigns.current_page, roles_per_page, socket.assigns.selected_operator_id)

    total_roles = CasinosAdmins.count_roles(socket.assigns.selected_operator_id)

    {:noreply,
     assign(socket,
       current_page: 1,
       roles_per_page: roles_per_page,
       roles: roles,
       total_pages: ceil(total_roles / roles_per_page)
     )}
  end

  defp should_disable_buttons?(role_name) do
    role_name in ["super_admin", "user "]
  end
end
