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
            class="leading-3 py-2 px-1 mb-1"
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
            class="mt-1"
            style="margin-bottom: -30px; z-index:1"
            patch={~p"/meetings/#{@meeting}/show/event/new/after/#{event["id"]}"}
            phx-click={JS.push_focus()}
          >
            <.button class="leading-3 py-2 px-3 bg-neutral-50 hover:bg-lime-400 hover:border-lime-900 text-zinc-900 border-zinc-900 border-2">
              +
            </.button>
          </.link>
        </div>
      </:col>
      <:col :let={event}><.render_event event={event} /></:col>
      <:action :let={event}>
        <.button
          class="text-red-700 bg-neutral-50 hover:bg-red-200 border-red-700 border-2"
          phx-click={JS.push("event-delete", value: %{event: event})}
        >
          Delete
        </.button>
      </:action>
    </.table>

    <.link patch={~p"/meetings/#{@meeting}/show/event/new"} phx-click={JS.push_focus()}>
      <.button class="mt-8">+ Event</.button>
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
      "ward-business" => "Ward Business",
      "stake-business" => "Stake Business",
      "ward-stake-business" => "Ward & Stake Business",
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

      {:error, cs} ->
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
