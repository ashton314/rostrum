defmodule RostrumWeb.MeetingLive.NewEventForm do
  use RostrumWeb, :live_component

  alias Rostrum.Meetings
  alias Rostrum.Meetings.Event

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="event-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <.input field={@form[:type]} type="select" label="Type"
          value={@form[:type].value}
          options={[
            "Music": [{"Opening Hymn", "opening-hymn"}, {"Closing Hymn", "closing-hymn"},
                      {"Rest Hymn", "rest-hymn"}, {"Hymn", "hymn"},
                      {"Musical number", "musical-number"}],
            "Speaker": [{"Speaker", "speaker"}],
            "Prayer": [{"Invocation", "opening-prayer"}, {"Benediction", "closing-prayer"}],
            "Ordinance": [{"Sacrament", "sacrament"}, {"Baby blessing", "baby-blessing"}],
            "Other": [{"Announcements", "announcements"}, {"Custom", "custom"}]
            ]} />
        <%= if @form[:type].value in ["opening-hymn", "closing-hymn", "rest-hymn", "hymn"] do %>
        <.input field={@form[:number]} type="number" label="Hymn number" />
        <%= Meetings.Event.hymn_name(@form[:number].value) %>
        <.input field={@form[:verses]} type="text" label="Verses (optional)" placeholder="e.g. 1, 2, 3" />
        <.input field={@form[:term]} type="text" label="Custom term (optional)" />
        <% end %>
        <%= if @form[:type].value in ["musical-number"] do %>
        <.input field={@form[:name]} type="text" label="Song name" />
        <.input field={@form[:performer]} type="text" label="Performer" />
        <.input field={@form[:term]} type="text" label="Custom term (optional)" />
        <% end %>
        <%= if @form[:type].value in ["opening-prayer", "closing-prayer", "speaker"] do %>
        <.input field={@form[:name]} type="text" label="Name of person" />
        <.input field={@form[:term]} type="text" label="Custom term (optional)" />
        <% end %>
        <%= if @form[:type].value in ["custom"] do %>
        <.input field={@form[:name]} type="text" label="Event title" />
        <% end %>

        <:actions>
          <.button phx-disable-with="Saving...">Save Event</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{event: event} = assigns, socket) do
    {:ok, socket
    |> assign(assigns)
    |> assign_new(:form, fn ->
      to_form(Meetings.Event.changeset(event, %{}))
    end)}
  end

  def update(assigns, socket) do
    id = UUID.uuid4()
    fresh_event = %Meetings.Event{id: id, type: "opening-hymn"}
    {:ok, socket
    |> assign(assigns)
    |> assign(:event, fresh_event)
    |> assign_new(:form, fn ->
      to_form(Meetings.Event.changeset(fresh_event, %{}))
    end)}
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset = Meetings.Event.changeset(socket.assigns.event, event_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"event" => event_params}, socket) do
    save_event(socket, socket.assigns.action, event_params)
  end

  defp save_event(socket, :new_event, event_params) do
    cs = Event.changeset(socket.assigns.event, event_params)
    if cs.valid? do
      {:ok, e} = Ecto.Changeset.apply_action(cs, :edit)
      e = e
      |> Map.from_struct
      |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
      |> Enum.into(%{})

      es = Map.get(socket.assigns.meeting, :events, %{"events" => []}) || %{"events" => []}
      save_meeting(socket, :edit, %{events: %{"events" => es["events"] ++ [e]}})
    else
      {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  defp save_meeting(socket, :edit, meeting_params) do
    case dbg(Meetings.update_meeting(socket.assigns.meeting, meeting_params)) do
      {:ok, meeting} ->
        notify_parent({:saved, meeting})

        {:noreply,
         socket
         |> put_flash(:info, "Event added successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
