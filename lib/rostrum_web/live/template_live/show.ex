defmodule RostrumWeb.TemplateLive.Show do
  use RostrumWeb, :live_view

  alias Rostrum.Meetings
  alias Meetings.Event

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:template, Meetings.get_template!(id))
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("event-up", %{"event" => event}, socket) do
    template = socket.assigns.template
    params = Meetings.Template.move_event_up(template, event["id"])
    update_events(socket, params)
  end

  def handle_event("event-down", %{"event" => event}, socket) do
    template = socket.assigns.template
    params = Meetings.Template.move_event_down(template, event["id"])
    update_events(socket, params)
  end

  def handle_event("event-delete", %{"event" => event}, socket) do
    template = socket.assigns.template
    params = Meetings.Template.delete_event(template, event["id"])
    update_events(socket, params)
  end

  def handle_event("delete", _, socket) do
    template = socket.assigns.template
    {:ok, _} = Meetings.delete_template(template)
    {:noreply,
     socket
     |> put_flash(:info, "Template deleted successfully")
     |> push_navigate(to: ~p"/templates/") }
  end

  defp page_title(:show), do: "Show Template"
  defp page_title(:edit), do: "Edit Template"
  defp page_title(:new_event), do: "New Event"
  defp page_title(:edit_event), do: "New Event"

  defp update_events(socket, %{events: new_events}) do
    case Meetings.update_template(socket.assigns.template, %{events: %{"events" => new_events}}) do
      {:ok, template} ->
        {:noreply, assign(socket |> put_flash(:info, "Updated"), :template, template)}

      {:error, _cs} ->
        {:noreply, put_flash(socket, :error, "Unable to update template")}
    end
  end

  defp update_events(socket, %{}), do: {:noreply, socket}

  defp apply_action(socket, :edit_event, %{"event_id" => event_id}) do
    template = socket.assigns.template
    {:ok, event} = Meetings.Template.fetch_event(template, event_id) |> Event.from_map()

    socket
    |> assign(:page_title, "Edit Event")
    |> assign(:event, event)
  end

  defp apply_action(socket, :new_event, params) do
    id = UUID.uuid4()

    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Event{id: id, type: "opening-hymn"})
    |> assign(:after_event_id, Map.get(params, "after_event_id", nil))
  end

  defp apply_action(socket, _, _params), do: socket

  def events_editor(assigns) do
    es = Map.get(assigns.template, :events, %{"events" => []}) || %{"events" => []}

    assigns =
      assigns
      |> assign(:es, es["events"] || [])

    template = assigns.template

    ~H"""
    <.table
      id="events"
      rows={@es}
      row_click={fn e -> JS.navigate(~p|/templates/#{template}/show/event/#{e["id"]}|) end}
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
            patch={~p"/templates/#{@template}/show/event/new/after/#{event["id"]}"}
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

    <.link patch={~p"/templates/#{@template}/show/event/new"} phx-click={JS.push_focus()}>
      <.button class="mt-8">+ Event</.button>
    </.link>
    """
  end
end
