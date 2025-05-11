defmodule RostrumWeb.MeetingLive.Index do
  alias Rostrum.DateUtils
  use RostrumWeb, :live_view

  alias Rostrum.Meetings
  alias Rostrum.Meetings.Template
  alias Rostrum.Meetings.Meeting

  @impl true
  def mount(_params, _session, socket) do
    {past, current, future} = Meetings.get_partitioned_meetings(socket.assigns.current_unit)
    socket =
      socket
      |> stream(:past, past)
      |> assign(:current, current)
      |> stream(:templates, [])
      |> stream(:future, future)

    {:ok, socket}
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

  defp apply_action(socket, :from_template, _params) do
    unit = socket.assigns.current_unit
    templates = Meetings.list_templates(unit)
    socket
    |> assign(:page_title, "New Meeting from Template")
    |> stream(:templates, templates)
    |> assign(:meeting, %Meeting{})
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
    {:noreply, stream_insert(socket, :future, meeting)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting = Meetings.get_meeting!(id, socket.assigns.current_unit)
    {:ok, _} = Meetings.delete_meeting(meeting)

    {:noreply, stream_delete(socket, :future, meeting)}
  end

  def handle_event("instantiate", %{"id" => template_id}, socket) do
    template = Meetings.get_template!(template_id, socket.assigns.current_unit)
    {:ok, meeting} =
      template
      |> Template.to_meeting(%{date: DateUtils.next_sunday()})
      |> Meetings.create_meeting()

    {:noreply,
     socket
     |> assign(:meeting, meeting)
     |> redirect(to: ~p"/meetings/#{meeting}/show/edit")}
  end

  def list_hymns(%Meeting{} = meeting) do
    for event <- meeting.events["events"] || [],
        event["type"] in ["opening-hymn", "closing-hymn", "sacrament-hymn", "rest-hymn", "hymn"] do
      if event["number"], do: event["number"], else: "TBD"
    end
    |> Enum.join(", ")
  end
end
