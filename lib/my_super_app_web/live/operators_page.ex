defmodule MySuperAppWeb.OperatorsPage do
  @moduledoc false
  use MySuperAppWeb, :surface_live_view

  alias MySuperApp.CasinosAdmins
  alias MySuperApp.Operator
  alias Moon.Design.Drawer
  alias Moon.Design.Button
  alias Moon.Design.Table
  alias Moon.Design.Form
  alias Moon.Design.Form.Field
  alias Moon.Design.Form.Input
  alias Moon.Design.Table.Column
  alias Moon.Design.Modal

  def mount(_params, session, socket) do
    current_user = MySuperApp.Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     assign(socket,
       operators: CasinosAdmins.all_models(),
       form_operator:
         %Operator{}
         |> Operator.changeset(%{})
         |> to_form(),
       is_drawer_open: false,
       temp_operator: %{name: ""},
       selected_operator: nil,
       is_modal_open: false,
       current_user: current_user
     )}
  end

  def render(assigns) do
    ~F"""
    <div class="flex justify-center items-center h-full">
      <Button
        class="bg-blue-500 text-white py-2 px-4 rounded-lg font-semibold hover:bg-blue-600 active:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-75 transition duration-300 ease-in-out"
        on_click="on_open"
      >
        Create operator
      </Button>
    </div>
    <Table items={operator <- @operators}>
      <Column name="id" label="Id">
        {operator.id}
      </Column>
      <Column name="username" label="Username">
        {operator.name}
      </Column>
      <Column name="inserted_at" label="Created at">
        {operator.inserted_at}
      </Column>
      <Column name="actions" label="Actions">
        <Button
          class="bg-blue-500 text-white py-2 px-4 rounded-lg font-semibold hover:bg-blue-600 active:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-75 transition duration-300 ease-in-out"
          on_click="show_operator_info"
          value={operator.id}
        >Info</Button>
      </Column>
    </Table>
    <Drawer id="add_drawer" is_open={@is_drawer_open}>
      <Drawer.Panel class="fixed top-0 right-0 h-full w-80 bg-white shadow-lg border-l border-gray-200 z-50 transform transition-transform duration-300 ease-in-out">
        <div class="p-4 border-b border-gray-200 flex items-center justify-between">
          <h2 class="text-gray-700" >Add a new operator</h2> <button class="gray-500 hover:text-gray-700" on_click="on_close">
          </button>
        </div>
        <div class="p-4">
          <Form for={@form_operator} change="validate" submit="save_operator">
            <Field field={:name} class="pb-3">
              <Input
                placeholder="Name"
                value={@temp_operator.name}
                class="text-gray-700 w-full border-gray-900 rounded-md shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-500 focus:ring-opacity-50"
              />
            </Field>
            <div class="flex gap-3 mt-4">
              <Button
                type="submit"
                class="bg-blue-500 text-white py-2 px-4 rounded-lg font-semibold hover:bg-blue-600 active:bg-blue-700 transition duration-300 ease-in-out"
              >
                Create
              </Button>
              <Button
                on_click="on_close"
                class="bg-gray-500 text-white py-2 px-4 rounded-lg font-semibold hover:bg-gray-600 active:bg-gray-700 transition duration-300 ease-in-out"
              >
                Cancel
              </Button>
            </div>
          </Form>
        </div>
      </Drawer.Panel>
    </Drawer>
    <Modal id="modal open" is_open={@is_modal_open} on_close="close_modal">
      <Modal.Backdrop class="inset-0 bg-gray-900 bg-opacity-50 z-40" /> <Modal.Panel class="inset-0 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-lg shadow-lg w-full max-w-md mx-auto p-6">
          <h2 class="text-gray-700 text-lg font-semibold mb-4">Operator Info</h2> {#if @selected_operator}
            <p class="text-gray-700 mb-2"><strong>Name:</strong> {@selected_operator.name}</p>
            <p class="text-gray-700 mb-2"><strong>Users Count:</strong> {length(@selected_operator.users)}</p>
            <p class="text-gray-700 mb-4"><strong>Sites Count:</strong> {length(@selected_operator.sites)}</p>
          {/if}
          <div class="flex justify-end">
            <Button
              class="bg-blue-500 text-white py-2 px-4 rounded-lg font-semibold hover:bg-blue-600 active:bg-blue-700 transition duration-300 ease-in-out"
              on_click="close_modal"
            >
              Close
            </Button>
          </div>
        </div>
      </Modal.Panel>
    </Modal>
    """
  end

  def handle_event("on_open", _params, socket) do
    Drawer.open("add_drawer")

    {:noreply,
     assign(socket,
       is_drawer_open: true
     )}
  end

  def handle_event("on_close", _params, socket) do
    Drawer.close("add_drawer")
    {:noreply, assign(socket, is_drawer_open: false, temp_operator: %{name: ""})}
  end

  def handle_event("validate", %{"operator" => operator_attrs}, socket) do
    {:noreply,
     assign(socket,
       temp_operator: %{name: operator_attrs["name"]},
       form_operator:
         %Operator{}
         |> Operator.changeset(operator_attrs)
         |> Map.put(:action, :insert)
         |> to_form()
     )}
  end

  def handle_event("save_operator", %{"operator" => operator_params}, socket) do
    Drawer.close("add_drawer")

    case CasinosAdmins.create_operator(operator_params) do
      {:ok, _operator} ->
        {:noreply,
         assign(socket,
           operators: CasinosAdmins.all_models(),
           is_drawer_open: false,
           form_operator:
             %Operator{}
             |> Operator.changeset(%{})
             |> to_form()
         )
         |> put_flash(:info, "The operator has been created")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset), is_drawer_open: false)}
    end
  end

  def handle_event("show_operator_info", %{"value" => operator_id}, socket) do
    operator = CasinosAdmins.get_operator_with_associations(operator_id)

    {:noreply,
     assign(socket,
       selected_operator: operator,
       is_modal_open: true
     )}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, is_modal_open: false, selected_operator: nil)}
  end
end
