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
    dbg(es)
    ~H"""
    <%= for e <- es["events"] do %>
    <.render_event event={e} />
    <% end %>

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
      "custom" => "Custom" }

    ~H"""
    <div class="py-2">
      <span>{@event["term"] || type_to_name[@event["type"]]}</span>
      <%= if @event["type"] in ["opening-hymn", "closing-hymn", "rest-hymn", "hymn"] do %>
      {@event["number"]} <%= Meetings.Event.hymn_name(@event["number"]) %>
      {@event["verses"]}
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

  @impl true
  def handle_info({RostrumWeb.MeetingLive.NewEventForm, {:saved, meeting}}, socket) do
    {:noreply, assign(socket, :meeting, meeting)}
  end

  defp apply_action(socket, :new_event, _params) do
    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Meetings.Event{type: "opening-hymn"})
  end

  defp apply_action(socket, _, _params), do: socket

  defp page_title(:show), do: "Show Meeting"
  defp page_title(:edit), do: "Edit Meeting"
  defp page_title(:new_event), do: "New Event"
end
