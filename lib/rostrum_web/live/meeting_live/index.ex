defmodule RostrumWeb.MeetingLive.Index do
  use RostrumWeb, :live_view

  alias Rostrum.Accounts
  alias Rostrum.Meetings
  alias Rostrum.Meetings.Meeting

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :meetings, Meetings.list_meetings(socket.assigns.current_unit))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Meeting")
    |> assign(:meeting, Meetings.get_meeting!(id, socket.assigns.current_unit))
  end

  defp apply_action(socket, :new, %{"clone" => "1"}) do
    last_meeting = Accounts.get_active_meeting(socket.assigns.current_unit)
    socket
    |> assign(:page_title, "New Meeting")
    |> assign(:meeting, Meetings.clone_skeleton(last_meeting))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Meeting")
    |> assign(:meeting, %Meeting{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Meetings")
    |> assign(:meeting, nil)
  end

  @impl true
  def handle_info({RostrumWeb.MeetingLive.FormComponent, {:saved, meeting}}, socket) do
    {:noreply, stream_insert(socket, :meetings, meeting)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting = Meetings.get_meeting!(id, socket.assigns.current_unit)
    {:ok, _} = Meetings.delete_meeting(meeting)

    {:noreply, stream_delete(socket, :meetings, meeting)}
  end

  def list_hymns(%Meeting{} = meeting) do
    for event <- meeting.events["events"] || [],
        event["type"] in ["opening-hymn", "closing-hymn", "sacrament-hymn", "rest-hymn", "hymn"] do
      if event["number"], do: event["number"], else: "TBD"
    end
    |> Enum.join(", ")
  end
end
