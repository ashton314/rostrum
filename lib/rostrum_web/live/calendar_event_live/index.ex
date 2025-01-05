defmodule RostrumWeb.CalendarEventLive.Index do
  use RostrumWeb, :live_view

  alias Rostrum.Events
  alias Rostrum.Events.CalendarEvent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :calendar_events, Events.list_calendar_events(socket.assigns.current_unit))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Calendar event")
    |> assign(:calendar_event, Events.get_calendar_event!(id, socket.assigns.current_unit))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Calendar event")
    |> assign(:calendar_event, %CalendarEvent{start_display: Timex.today("America/Denver")})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Calendar events")
    |> assign(:calendar_event, nil)
  end

  @impl true
  def handle_info({RostrumWeb.CalendarEventLive.FormComponent, {:saved, calendar_event}}, socket) do
    {:noreply, stream_insert(socket, :calendar_events, calendar_event)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    calendar_event = Events.get_calendar_event!(id, socket.assigns.current_unit)
    {:ok, _} = Events.delete_calendar_event(calendar_event)

    {:noreply, stream_delete(socket, :calendar_events, calendar_event)}
  end
end
