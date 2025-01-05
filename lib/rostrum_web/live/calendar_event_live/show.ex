defmodule RostrumWeb.CalendarEventLive.Show do
  use RostrumWeb, :live_view

  alias Rostrum.Events

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:calendar_event, Events.get_calendar_event!(id, socket.assigns.current_unit))}
  end

  defp page_title(:show), do: "Show Calendar event"
  defp page_title(:edit), do: "Edit Calendar event"
end
