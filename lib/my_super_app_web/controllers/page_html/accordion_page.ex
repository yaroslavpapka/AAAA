defmodule MySuperAppWeb.AccordPage do
  @moduledoc false
  use MySuperAppWeb, :surface_live_view

  alias Moon.Design.Accordion
  import MoonWeb.Helpers.Lorem

  data(color, :string, default: "bg-goku")

  def handle_event("accordioned", %{"value" => value}, socket) do
    {:noreply, assign(socket, color: value)}
  end

  def render(assigns) do
    ~F"""
    <div class="w-full">
      <Accordion id="on-change-accordion" on_change="accordioned" value={@color}>
        <Accordion.Item value="bg-krillin">
          <Accordion.Header title="Krilin" class={@color} /> <Accordion.Content class="bg-krillin/20">{lorem()}</Accordion.Content>
        </Accordion.Item>
        <Accordion.Item value="bg-roshi">
          <Accordion.Header title="Roshi" class={@color} /> <Accordion.Content class="bg-roshi/20">{ipsum()}</Accordion.Content>
        </Accordion.Item>
        <Accordion.Item value="bg-chichi">
          <Accordion.Header title="Chichi" class={@color} /> <Accordion.Content class="bg-chichi/20">{dolor()}</Accordion.Content>
        </Accordion.Item>
      </Accordion>
    </div>
    """
  end
end
