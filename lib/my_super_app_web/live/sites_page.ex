defmodule MySuperAppWeb.SitesPage do
  @moduledoc false
  use MySuperAppWeb, :surface_live_view
  alias MySuperApp.{Site, CasinosAdmins}
  alias Moon.Design.Table
  alias Moon.Design.Table.Column
  alias Moon.Design.Button
  alias Moon.Design.Modal
  alias Moon.Design.Pagination
  alias Moon.Design.Form
  alias Moon.Design.Form.{Input, Field}
  alias Moon.Design.Dropdown
  alias Moon.Components.Chip
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  data(limit, :integer, default: 10)
  data(selected_site, :map, default: nil)

  def mount(_params, session, socket) do
    operator_id =
      MySuperApp.Accounts.get_user_by_session_token(session["user_token"]).operator_id

    total_sites = CasinosAdmins.count_sites(operator_id)
    all_operators = CasinosAdmins.all_models()

    {
      :ok,
      assign(
        socket,
        sites: CasinosAdmins.get_sites(1, 10, operator_id),
        total_pages: ceil(total_sites / 10),
        total_sites: total_sites,
        operator_id: operator_id,
        filter: "",
        sort: [name: "ASC"],
        all_operators: all_operators,
        new_site_changeset: Site.changeset(%Site{}, %{}),
        id: nil,
        current_page: 1,
        selected: nil
      )
    }
  end

  def render(assigns) do
    ~F"""
    <div class="container mx-auto p-6 text-black">
      <div class="flex justify-end mb-4">
        <form phx-change="sites_per_page_changed">
          <select
            name="sites_per_page"
            class="pe-8 bg-white border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-3.5"
          >
            <option value={3} selected={@limit == 3}>3</option> <option value={5} selected={@limit == 5}>5</option> <option value={7} selected={@limit == 7}>7</option> <option value={10} selected={@limit == 10}>10</option>
          </select>
        </form>
      </div>
      <div class="flex items-center h-full space-x-4">
        <Dropdown id="dropdown_role" on_change="change_role">
          <Dropdown.Options
            titles={[MySuperApp.CasinosAdmins.get_operator_name(@operator_id)]}
            class="bg-white border border-gray-300 rounded shadow-lg w-64 mt-2"
          /> <Dropdown.Trigger disabled :let={value: value} class="focus:outline-none">
            <Chip
              variant="ghost"
              class="w-64 px-4 py-2 border border-gray-300 rounded bg-white text-gray-700 hover:bg-gray-100 focus:ring-2 focus:ring-blue-500"
            >
              {value || MySuperApp.CasinosAdmins.get_operator_name(@operator_id)}
            </Chip>
          </Dropdown.Trigger>
        </Dropdown>
        <Button
          on_click="open_new_site_modal"
          class="bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded-lg"
        >
          Add Site Config
        </Button>
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
      <Table {=@sort} items={site <- @sites} sorting_click="handle_sorting_click" is_cell_border>
        <Table.Column name="id" label="ID" sortable>
          {site.id}
        </Table.Column>
        <Table.Column name="brand" label="Brand" sortable>
          {site.brand}
        </Table.Column>
        <Table.Column name="status" label="Status" sortable>
          {site.status}
        </Table.Column>
        <Table.Column name="operator" label="Operator" sortable>
          {CasinosAdmins.get_operator(site.operator_id).name}
        </Table.Column>
        <Column label="Actions" class="text-center">
          <div class="flex gap-2">
            <Button
              on_click={"update_operator_#{site.id}"}
              class="bg-green-500 hover:bg-green-600 text-white py-1 px-2 rounded-lg text-sm"
            >Change Status</Button> <Button
              on_click={"modal_open_delete#{site.id}"}
              class="bg-red-500 hover:bg-red-600 text-white py-1 px-2 rounded-lg text-sm"
            >Delete</Button>
          </div>
        </Column>
      </Table>
      <Modal id="modal_delete">
        <Modal.Backdrop class="bg-gray-900 bg-opacity-75" /> <Modal.Panel class="bg-white rounded-lg shadow-lg max-w-md mx-auto my-8">
          <div class="p-4 border-b-2 border-gray-300">
            <h3 class="text-xl font-semibold mb-4">Are you sure you want to delete this site?</h3> <div class="flex justify-end gap-2">
              <Button
                on_click={"delete_#{@id}"}
                class="bg-red-500 hover:bg-red-600 text-white py-2 px-4 rounded-lg"
              >Delete</Button> <Button
                on_click="close_modal"
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 py-2 px-4 rounded-lg"
              >Close</Button>
            </div>
          </div>
        </Modal.Panel>
      </Modal>
      <Modal id="modal_new_site">
        <Modal.Backdrop class="bg-gray-900 bg-opacity-75" /> <Modal.Panel class="bg-white rounded-lg shadow-lg max-w-lg mx-auto my-8">
          <Form for={@new_site_changeset} submit="create_site">
            <div class="p-4">
              <Field field={:brand} label="Input new site's name" class="text-moon-30 font-medium mb-4">
                <Input placeholder="Name" class="w-full border border-gray-300 rounded p-2" />
              </Field>
              <Field
                field={:operator_id}
                label="Input new site's operator"
                class="text-moon-30 font-medium mb-4"
              >
                <Input
                  disabled
                  value={MySuperApp.CasinosAdmins.get_operator(@operator_id).name}
                  class="w-full border border-gray-300 rounded p-2 bg-gray-100"
                />
              </Field>
            </div>
            <div class="p-4 border-t border-gray-300 flex justify-between">
              <Button type="submit" class="bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded-lg">Add new site</Button> <Button
                on_click="close_modal_new_site"
                type="button"
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 py-2 px-4 rounded-lg"
              >Close window</Button>
            </div>
          </Form>
        </Modal.Panel>
      </Modal>
    </div>
    """
  end



  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)
    sites = CasinosAdmins.get_sites(current_page, socket.assigns.limit, socket.assigns.operator_id)

    {:noreply,
     assign(socket,
       current_page: current_page,
       sites: sites
     )}
  end

  def handle_event("sites_per_page_changed", %{"sites_per_page" => sites_per_page}, socket) do
    sites_per_page = String.to_integer(sites_per_page)

    sites = CasinosAdmins.get_sites(socket.assigns.current_page, sites_per_page, socket.assigns.operator_id)
    total_pages = ceil(socket.assigns.total_sites / sites_per_page)

    {:noreply,
     assign(socket,
       limit: sites_per_page,
       sites: sites,
       total_pages: total_pages
     )}
  end

  def handle_event("open_new_site_modal", _, socket) do
    operator_name = CasinosAdmins.get_operator(socket.assigns.operator_id)
    Modal.open("modal_new_site")
    {:noreply, assign(socket, modal_new_site: true, selected: operator_name)}
  end

  def handle_event("close_modal_new_site", _, socket) do
    Modal.close("modal_new_site")
    {:noreply, assign(socket, modal_new_site: false)}
  end

  def handle_event("create_site", %{"site" => site_params}, socket) do
    Modal.close("modal_new_site")
    operator_id = socket.assigns.operator_id
    MySuperApp.CasinosAdmins.create_site(%{brand: site_params["brand"], operator_id: operator_id})
    sites = CasinosAdmins.get_sites(socket.assigns.current_page, socket.assigns.limit, operator_id)

    {:noreply,
     assign(socket,
       sites: sites,
       new_site_changeset: Site.changeset(%Site{}, %{}),
       modal_new_site: false
     )}
  end

  def handle_event("update_operator_" <> id, _, socket) do
    site = CasinosAdmins.get_site!(String.to_integer(id))
    new_status = if site.status == :ACTIVE, do: :STOPPED, else: :ACTIVE

    case CasinosAdmins.update_site(site, %{status: new_status}) do
      {:ok, _site} ->
        sites =
          CasinosAdmins.get_sites(socket.assigns.current_page, socket.assigns.limit, socket.assigns.operator_id)

        {:noreply, assign(socket, sites: sites)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("modal_open_edit" <> id, _params, socket) do
    site = CasinosAdmins.get_site!(String.to_integer(id))
    {:noreply, assign(socket, selected_site: site)}
  end

  def handle_event("modal_open_delete" <> id, _params, socket) do
    Modal.open("modal_delete")
    site = CasinosAdmins.get_site!(String.to_integer(id))
    {:noreply, assign(socket, selected_site: site, modal_delete: true, id: id)}
  end

  def handle_event("close_modal", _params, socket) do
    Modal.close("modal_delete")

    {:noreply, assign(socket, modal_delete: false)}
  end

  def handle_event("delete_" <> id, _params, socket) do
    Modal.close("modal_delete")
    CasinosAdmins.get_site!(id)
    |> CasinosAdmins.delete_site()

    sites =
      CasinosAdmins.get_sites(socket.assigns.current_page, socket.assigns.limit, socket.assigns.operator_id)

    {:noreply,
     assign(socket,
       sites: sites,
       modal_delete: false,
       selected_site: nil
     )}
  end

  def handle_event(
        "handle_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    {:noreply, socket |> assign(sort: ["#{sort_key}": sort_dir])}
  end
end
