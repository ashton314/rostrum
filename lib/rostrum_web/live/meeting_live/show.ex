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
    es = Map.get(dbg(assigns.meeting), :events, %{"events" => []}) || %{"events" => []}

    assigns =
      assigns
      |> assign(:es, es["events"] || [])

    ~H"""
    <.table
      id="events"
      rows={@es}
      row_click={fn e -> JS.push("event-edit", value: %{event: e}) end}
    >
      <:col :let={event}><.render_event event={event} /></:col>
      <:action :let={event}><.button phx-click={JS.push("event-up", value: %{event: event})}>↑</.button></:action>
      <:action :let={event}><.button phx-click={JS.push("event-down", value: %{event: event})}>↓</.button></:action>
      <:action :let={event}><.button phx-click={JS.push("event-delete", value: %{event: event})}>Delete</.button></:action>
    </.table>

    <.link patch={~p"/meetings/#{@meeting}/show/new_event"} phx-click={JS.push_focus()}>
      <.button>+ Event</.button>
    </.link>
    """
  end

  def render_event(assigns) do
    type_to_name = %{
      "opening-hymn" => "Opening Hymn",
      "closing-hymn" => "Closing Hymn",
      "rest-hymn" => "Rest Hymn",
      "hymn" => "Hymn",
      "musical-number" => "Musical number",
      "speaker" => "Speaker",
      "opening-prayer" => "Invocation",
      "closing-prayer" => "Benediction",
      "sacrament" => "Sacrament",
      "baby-blessing" => "Baby blessing",
      "announcements" => "Announcements",
      "custom" => "Custom"
    }

    assigns =
      assigns
      |> assign(:name, type_to_name[assigns.event["type"]])
      |> assign(:verses, assigns.event["verses"])

    ~H"""
    <div class="py-2 font-normal">
      <div class="text-sm capitalize font-semibold">{@event["term"] || @name}</div>
      <%= if @event["type"] in ["opening-hymn", "closing-hymn", "rest-hymn", "hymn"] do %>
        <div>
          <span class="mr-1">{@event["number"]}</span><span class="italic"><%= Meetings.Event.hymn_name(@event["number"]) %></span>
        </div>
        <%= if @verses do %>
          <span>{@verses}</span>
        <% end %>
      <% end %>
      <%= if @event["type"] in ["musical-number"] do %>
        {@event["name"]}
        {@event["Performer"]}
      <% end %>
      <%= if @event["type"] in ["opening-prayer", "closing-prayer", "speaker"] do %>
        {@event["name"]}
      <% end %>
      <%= if @event["type"] in ["custom"] do %>
        {@event["name"]}
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("add_event", _data, socket) do
    {:noreply, socket}
  end

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

  def handle_event("event-edit", %{"event" => event}, socket) do
    dbg(event)
    {:noreply, socket}
  end

  @impl true
  def handle_info({RostrumWeb.MeetingLive.NewEventForm, {:saved, meeting}}, socket) do
    {:noreply, assign(socket, :meeting, meeting)}
  end

  def handle_info({RostrumWeb.MeetingLive.FormComponent, {:saved, meeting}}, socket) do
    {:noreply, assign(socket, :meeting, meeting)}
  end

  defp update_events(socket, %{events: new_events}) do
    dbg(new_events)
    case Meetings.update_meeting(socket.assigns.meeting, %{events: %{"events" => new_events}}) do
      {:ok, meeting} ->
        dbg(meeting)
        {:noreply, assign(socket |> put_flash(:info, "Updated"), :meeting, meeting)}

      {:error, cs} ->
        dbg(cs)
        {:noreply, put_flash(socket, :error, "Unable to update meeting")}
    end
  end

  defp update_events(socket, %{}), do: {:noreply, socket}

  defp apply_action(socket, :new_event, _params) do
    id = UUID.uuid4()

    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Meetings.Event{id: id, type: "opening-hymn"})
  end

  defp apply_action(socket, _, _params), do: socket

  defp page_title(:show), do: "Show Meeting"
  defp page_title(:edit), do: "Edit Meeting"
  defp page_title(:new_event), do: "New Event"
end
