defmodule RostrumWeb.MeetingLive.Show do
  use RostrumWeb, :live_view

  alias Rostrum.Meetings
  alias Rostrum.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    {id, _} = Integer.parse(id)
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:meeting, Meetings.get_meeting!(id, socket.assigns.current_unit))
     |> apply_action(socket.assigns.live_action, params)}
  end

  def edit_all(assigns) do
    es = Map.get(assigns.meeting, :events, %{"events" => []}) || %{"events" => []}

    assigns =
      assigns
      |> assign(:es, es["events"] || [])

    meeting = assigns.meeting

    ~H"""
    <.table
      id="events"
      rows={@es}
      row_click={fn e -> JS.navigate(~p|/meetings/#{meeting}/show/event/#{e["id"]}|) end}
    >
      <:col :let={event}>
        <div class="flex flex-col">
          <.button
            class="leading-3 py-2 px-1 mb-1 mt-2"
            phx-click={JS.push("event-up", value: %{event: event})}
          >
            ↑
          </.button>
          <.button
            class="leading-3 py-2 px-1 mt-1"
            phx-click={JS.push("event-down", value: %{event: event})}
          >
            ↓
          </.button>

          <.link
            class="mt-2 p-1 border-2 rounded-lg border-green-800 bg-white hover:bg-green-100 text-green-800 text-center"
            style="margin-bottom: -33px; z-index:1"
            patch={~p"/meetings/#{@meeting}/show/event/new/after/#{event["id"]}"}
            phx-click={JS.push_focus()}>+</.link>
        </div>
      </:col>
      <:col :let={event}><.render_event event={event} show_private={true} /></:col>
      <:action :let={event}>
        <.link
          class="p-3 rounded-lg text-red-800 bg-zinc-50 hover:bg-red-100 border-red-700 border-2"
          phx-click={JS.push("event-delete", value: %{event: event})}
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.link patch={~p"/meetings/#{@meeting}/show/event/new"} phx-click={JS.push_focus()}>
      <.button class="mt-8">+ Event</.button>
    </.link>
    """
  end

  def edit_music(assigns) do
    es = Map.get(assigns.meeting,
                 :events,
                 %{"events" => []}) || %{"events" => []}
    es =
      (es["events"] || [])
      |> Enum.filter(fn x -> x["type"] in ["opening-hymn", "closing-hymn", "sacrament-hymn", "rest-hymn", "hymn", "musical-number"] end)
# es["events"] || [])

    assigns =
      assigns
      |> assign(:es, es)

    meeting = assigns.meeting

    ~H"""
    <.table
      id="events"
      rows={@es}
      row_click={fn e -> JS.navigate(~p|/meetings/#{meeting}/show/event/#{e["id"]}|) end}
    >
      <:col></:col>
      <:col :let={event}><.render_event event={event} show_private={false} /></:col>
    </.table>
    """
  end

  def events_editor(assigns) do
    unit = assigns.current_unit
    user = assigns.current_user

    if Accounts.authorized?(user, unit, :editor) do
      edit_all(assigns)
    else
      edit_music(assigns)
    end
  end

  @impl true
  def handle_event("event-up", %{"event" => event}, socket) do
    meeting = socket.assigns.meeting
    params = Meetings.Meeting.move_event_up(meeting, event["id"])
    update_events(socket, params)
  end

  def handle_event("event-down", %{"event" => event}, socket) do
    meeting = socket.assigns.meeting
    params = Meetings.Meeting.move_event_down(meeting, event["id"])
    update_events(socket, params)
  end

  def handle_event("event-delete", %{"event" => event}, socket) do
    meeting = socket.assigns.meeting
    params = Meetings.Meeting.delete_event(meeting, event["id"])
    update_events(socket, params)
  end

  def handle_event("delete", _, socket) do
    meeting = socket.assigns.meeting
    {:ok, _} = Meetings.delete_meeting(meeting)
    {:noreply,
     socket
     |> put_flash(:info, "Meeting deleted successfully")
     |> push_navigate(to: ~p"/meetings/") }
  end

  @impl true
  def handle_info({RostrumWeb.MeetingLive.NewEventForm, {:saved, meeting}}, socket) do
    {:noreply, assign(socket, :meeting, meeting)}
  end

  def handle_info({RostrumWeb.MeetingLive.FormComponent, {:saved, meeting}}, socket) do
    {:noreply, assign(socket, :meeting, meeting)}
  end

  defp update_events(socket, %{events: new_events}) do
    case Meetings.update_meeting(socket.assigns.meeting, %{events: %{"events" => new_events}}) do
      {:ok, meeting} ->
        {:noreply, assign(socket |> put_flash(:info, "Updated"), :meeting, meeting)}

      {:error, _cs} ->
        {:noreply, put_flash(socket, :error, "Unable to update meeting")}
    end
  end

  defp update_events(socket, %{}), do: {:noreply, socket}

  defp apply_action(socket, :edit_event, %{"event_id" => event_id}) do
    meeting = socket.assigns.meeting
    {:ok, event} = Meetings.Meeting.fetch_event(meeting, event_id) |> Meetings.Event.from_map()

    socket
    |> assign(:page_title, "Edit Event")
    |> assign(:event, event)
  end

  defp apply_action(socket, :new_event, params) do
    id = UUID.uuid4()

    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Meetings.Event{id: id, type: "opening-hymn"})
    |> assign(:after_event_id, Map.get(params, "after_event_id", nil))
  end

  defp apply_action(socket, _, _params), do: socket

  defp page_title(:show), do: "Show Meeting"
  defp page_title(:edit), do: "Edit Meeting"
  defp page_title(:new_event), do: "New Event"
  defp page_title(:edit_event), do: "New Event"
end
