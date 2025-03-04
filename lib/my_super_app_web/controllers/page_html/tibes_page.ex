defmodule MySuperAppWeb.TabsPage do
  @moduledoc false
  use MySuperAppWeb, :surface_live_view
  alias Moon.Design.Tabs
  alias Moon.Design.Accordion
  alias Moon.Design.Table
  alias Moon.Design.Table.Column

  import MoonWeb.Helpers.Lorem

  prop(selected, :list, default: [])

  data(rooms_with_phones, :any, default: [])
  data(rooms_without_phones, :any, default: [])
  data(phones_no_rooms, :any, default: [])

  @spec mount(any(), any(), map()) :: {:ok, any()}
  def mount(_params, _session, socket) do
    {
      :ok,
      assign(
        socket,
        rooms_with_phones: MySuperApp.DbQueries.rooms_with_phones(),
        rooms_without_phones: MySuperApp.DbQueries.rooms_without_phones(),
        phones_no_rooms: MySuperApp.DbQueries.phones_without_rooms(),
        selected: []
      )
    }
  end

  def render(assigns) do
    ~F"""
    <Tabs id="tabs-ex-1">
      <Tabs.List>
        <Tabs.Tab>Кімнати з телефонами</Tabs.Tab> <Tabs.Tab>Кімнати без телефонів</Tabs.Tab> <Tabs.Tab>Телефони не прив'язані до кімнат</Tabs.Tab>
      </Tabs.List>
      <Tabs.Panels>
        <Tabs.Panel>
          <Table items={room <- @rooms_with_phones} row_click="single_row_click" {=@selected}>
            <Column label="Room Number">
              {room.room_number}
            </Column>
            <Column label="Phones">
              {#for {phone, index} <- room.phones |> Enum.with_index(1)}
                {#if index < room.phones |> Enum.count()}
                  {"#{phone.phone_number}, "}
                {#else}
                  {phone.phone_number}
                {/if}
              {/for}
            </Column>
          </Table>
        </Tabs.Panel>
        <Tabs.Panel>
          <Table items={room <- @rooms_without_phones}>
            <Column label="Room Number">
              {room.room_number}
            </Column>
          </Table>
        </Tabs.Panel>
        <Tabs.Panel>
          <Table items={phone <- @phones_no_rooms}>
            <Column label="Phone">
              {phone.phone_number}
            </Column>
          </Table>
        </Tabs.Panel>
      </Tabs.Panels>
    </Tabs>
    <div class="flex p-4 bg-gohan rounded-moon-s-sm text-moon-14 w-full">
      <Tabs id="tabs-with-pills" class="background-color:trunks">
        <Tabs.List tab_titles={["First pill", "Second pill", "Third pill"]} tab_module={Tabs.Pill} /> <Tabs.Panels>
          <Tabs.Panel>{lorem()}</Tabs.Panel> <Tabs.Panel>{ipsum()}</Tabs.Panel> <Tabs.Panel>{dolor()}</Tabs.Panel>
        </Tabs.Panels>
      </Tabs>
    </div>
    <Tabs id="tabs-with-segments">
      <Tabs.List tab_titles={["First pill", "Second pill", "Third pill"]} tab_module={Tabs.Segment} /> <Tabs.Panels>
        <Tabs.Panel>{lorem()}</Tabs.Panel> <Tabs.Panel>{ipsum()}</Tabs.Panel> <Tabs.Panel>{dolor()}</Tabs.Panel>
      </Tabs.Panels>
    </Tabs>
    <br> <Accordion id="simple-accordion">
      <Accordion.Item>
        <Accordion.Header title="Lorem" /> <Accordion.Content>{lorem()}</Accordion.Content>
      </Accordion.Item>
      <Accordion.Item>
        <Accordion.Header class="bg-beerus">Beerus bg</Accordion.Header> <Accordion.Content class="bg-beerus">{ipsum()}</Accordion.Content>
      </Accordion.Item>
      <Accordion.Item>
        <Accordion.Header>Dolor</Accordion.Header> <Accordion.Content>{dolor()}</Accordion.Content>
      </Accordion.Item>
    </Accordion>
    """
  end

  def handle_event("single_row_click", %{"selected" => selected}, socket) do
    {:noreply, assign(socket, selected: [selected])}
  end
end
