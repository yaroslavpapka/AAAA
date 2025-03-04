defmodule MySuperAppWeb.MenuPage do
  @moduledoc false
  use MySuperAppWeb, :surface_live_view

  alias Moon.Design.MenuItem
  alias Moon.Autolayouts.TopToDown
  alias Moon.Components.Heading
  alias Moon.Lego

  alias MySuperApp.{Repo, LeftMenu}
  data(expanded0, :boolean, default: false)
  data(expanded1, :boolean, default: true)
  data(expanded2, :boolean, default: false)
  data(left_menu, :any, default: [])

  def mount(_params, _session, socket) do
    {:ok, assign(socket, left_menu: LeftMenu |> Repo.all())}
  end

  def render(assigns) do
    ~F"""
    <div>
      <TopToDown class="max-w-sm p-4 m-auto gap-4">
        <Heading size={24} class="text-center" is_regular>Menu!</Heading> <div class="flex w-full">
          <div class="w-56 bg-goku flex flex-col gap-2 rounded-moon-s-lg">
            {#for menu <- @left_menu}
              {#if menu.title == "Tailwind"}
                <MenuItem role="switch" is_selected={@expanded0} title={menu.title} on_click="on_expand0" />
              {#else}
                <MenuItem>{menu.title}</MenuItem>
              {/if}
            {/for} {#if @expanded0}
              <MenuItem>
                <span class="w-6" /> <Lego.Title>
                  Accordion
                </Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-6" /> <Lego.Title>
                  Avatar
                </Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-6" /> <Lego.Title>
                  Breadcrumb
                </Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-6" /> <Lego.Title>
                  Button
                </Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-6" /> <Lego.Title>
                  Checkbox
                </Lego.Title>
              </MenuItem>
            {/if}
          </div>
          <div class="w-56 bg-goku flex flex-col gap-2 rounded-moon-s-lg">
            <MenuItem>
              <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                <p class="leading-4 font-semibold text-moon-10">B</p>
              </span>
              <Lego.Title>
                <p class="leading-6 text-moon-14 font-semibold">Bitcasino</p>
              </Lego.Title>
            </MenuItem>
            <MenuItem>
              <span class="w-3" :on-click="on_expand1" :values={is_selected: !@expanded1}>
                <Lego.ChevronUpDown is_selected={@expanded1} />
              </span>
              <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                <p class="leading-4 font-semibold text-moon-10">CX</p>
              </span>
              <Lego.Title>
                Customer...</Lego.Title>
            </MenuItem>
            {#if @expanded1}
              <MenuItem>
                <span class="w-6" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">S</p>
                </span>
                <Lego.Title>Sub nested item</Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-6" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">S</p>
                </span>
                <Lego.Title>Sub nested item</Lego.Title>
              </MenuItem>
            {/if}
            <MenuItem>
              <span class="w-3" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                <p class="leading-4 font-semibold text-moon-10">CX</p>
              </span>
              <Lego.Title>Quality...</Lego.Title>
            </MenuItem>
            <MenuItem>
              <span class="w-3" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                <p class="leading-4 font-semibold text-moon-10">RG</p>
              </span>
              <Lego.Title>Responsible...</Lego.Title>
            </MenuItem>
            <MenuItem>
              <span class="w-3" :on-click="on_expand2" :values={is_selected: !@expanded2}>
                <Lego.ChevronUpDown is_selected={@expanded2} />
              </span>
              <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                <p class="leading-4 font-semibold text-moon-10">RG</p>
              </span>
              <Lego.Title>Responsible...</Lego.Title>
            </MenuItem>
            {#if @expanded2}
              <MenuItem>
                <span class="w-6" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">S</p>
                </span>
                <Lego.Title>Sub nested item</Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-6" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">S</p>
                </span>
                <Lego.Title>Sub nested item</Lego.Title>
              </MenuItem>
            {/if}
            <div class="flex flex-col gap-2 rounded-moon-s-lg">
              <MenuItem>
                <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">S</p>
                </span>
                <Lego.Title>
                  <p class="leading-6 text-moon-14 font-semibold">Sportsbet</p>
                </Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-3" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">RG</p>
                </span>
                <Lego.Title>Customer...</Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-3" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">CX</p>
                </span>
                <Lego.Title>Quality...</Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-3" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">RG</p>
                </span>
                <Lego.Title>Responsible...</Lego.Title>
              </MenuItem>
            </div>
            <div class="flex flex-col gap-2 rounded-moon-s-lg">
              <MenuItem>
                <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">L</p>
                </span>
                <Lego.Title>
                  <p class="leading-6 text-moon-14 font-semibold">Livecasino</p>
                </Lego.Title>
              </MenuItem>
              <MenuItem>
                <span class="w-3" /> <span class="bg-gohan w-6 h-6 top-2 left-2 rounded-full flex justify-center items-center">
                  <p class="leading-4 font-semibold text-moon-10">RG</p>
                </span>
                <Lego.Title>Customer...</Lego.Title>
              </MenuItem>
            </div>
          </div>
        </div>
      </TopToDown>
    </div>
    """
  end

  def handle_event("on_expand" <> number, params, socket) do
    {:noreply, assign(socket, :"expanded#{number}", params["is-selected"] |> convert!)}
  end

  defp convert!("true"), do: true
  defp convert!("false"), do: false
end
