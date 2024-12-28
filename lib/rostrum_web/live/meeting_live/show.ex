defmodule RostrumWeb.MeetingLive.Show do
  use RostrumWeb, :live_view

  alias Rostrum.Meetings

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:meeting, Meetings.get_meeting!(id))
     |> apply_action(socket.assigns.live_action, params)}
  end

  def events_editor(assigns) do
    ~H"""
    <.label>Events</.label>

    <.link patch={~p"/meetings/#{@data}/show/new_event"} phx-click={JS.push_focus()}>
      <.button>+ Event</.button>
    </.link>
    """
  end

  @impl true
  def handle_event("add_event", data, socket) do
    IO.inspect(data, label: "data")
    {:noreply, socket}
  end


  defp apply_action(socket, :new_event, _params) do
    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Meetings.Event{type: "opening-hymn"})
    |> dbg()
  end

  defp apply_action(socket, _, _params), do: socket

  defp page_title(:show), do: "Show Meeting"
  defp page_title(:edit), do: "Edit Meeting"
  defp page_title(:new_event), do: "New Event"
end
