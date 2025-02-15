defmodule RostrumWeb.MeetingLive.NewEventForm do
  use RostrumWeb, :live_component

  alias Rostrum.Meetings
  alias Rostrum.Meetings.Event

  @impl true
  def render(assigns) do
    dat = Meetings.Event.hymn_name(assigns.form[:number].value)

    assigns =
      assigns
      |> assign(
        :hymn_name,
        if(is_map(dat),
          do: dat.name,
          else: if(assigns.form[:number].value == nil, do: "", else: "Invalid")
        )
      )
      |> assign(
        :type_options,
        (if assigns.show_all_types,
           do: [
            Music: [
              {"Opening Hymn", "opening-hymn"},
              {"Closing Hymn", "closing-hymn"},
              {"Sacrament Hymn", "sacrament-hymn"},
              {"Rest Hymn", "rest-hymn"},
              {"Hymn", "hymn"},
              {"Musical number", "musical-number"}
            ],
            Speaker: [{"Speaker", "speaker"}],
            Prayer: [{"Invocation", "opening-prayer"}, {"Benediction", "closing-prayer"}],
            Ordinance: [{"Sacrament", "sacrament"}, {"Baby blessing", "baby-blessing"}],
            Other: [
              {"Testimonies from the Congregation", "testimonies"},
              {"Announcements", "announcements"},
              {"Ward Business", "ward-business"},
              {"Stake Business", "stake-business"},
              {"Ward & Stake Business", "ward-stake-business"},
              {"Prompt", "prompt"},
              {"Custom", "custom"}
            ]
          ],
           else: [
            Music: [
              {"Opening Hymn", "opening-hymn"},
              {"Closing Hymn", "closing-hymn"},
              {"Sacrament Hymn", "sacrament-hymn"},
              {"Rest Hymn", "rest-hymn"},
              {"Hymn", "hymn"},
              {"Musical number", "musical-number"}
            ],
          ])
      )

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
        <.input
          field={@form[:type]}
          type="select"
          label="Type"
          value={@form[:type].value}
          options={@type_options}
        />
        <%= if @form[:type].value in ["opening-hymn", "closing-hymn", "sacrament-hymn", "rest-hymn", "hymn"] do %>
          <.input field={@form[:number]} type="number" label="Hymn number" />
          {@hymn_name}
          <.input
            field={@form[:verses]}
            type="text"
            label="Verses (optional)"
            placeholder="e.g. 1, 2, 3"
          />
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
        <%= if @form[:type].value in ["ward-business", "stake-business", "ward-stake-business", "prompt"] do %>
          <.input
            field={@form[:private_notes]}
            type="textarea"
            label="Private notes"
            help="This will only be visible to meeting editors and owners. Markdown supported."
          />
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
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Meetings.Event.changeset(event, %{}))
     end)}
  end

  def update(assigns, socket) do
    id = UUID.uuid4()
    fresh_event = %Meetings.Event{id: id, type: "opening-hymn"}

    {:ok,
     socket
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

      e =
        e
        |> Map.from_struct()
        |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
        |> Enum.into(%{})

      es = Map.get(socket.assigns.meeting, :events, %{"events" => []}) || %{"events" => []}

      new_events =
        if Map.get(socket.assigns, :after_event_id, nil) do
          List.insert_at(
            es["events"],
            Meetings.Meeting.find_event_idx(socket.assigns.meeting, socket.assigns.after_event_id) +
              1,
            e
          )
        else
          es["events"] ++ [e]
        end

      save_meeting(socket, :edit, %{events: %{"events" => new_events}})
    else
      {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  defp save_event(socket, :edit_event, event_params) do
    cs = Event.changeset(socket.assigns.event, event_params)

    if cs.valid? do
      {:ok, e} = Ecto.Changeset.apply_action(cs, :edit)

      eid = e.id

      e =
        e
        |> Map.from_struct()
        |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
        |> Enum.into(%{})

      es = Map.get(socket.assigns.meeting, :events, %{"events" => []}) || %{"events" => []}

      new_events =
        es["events"]
        |> Enum.map(fn
          %{"id" => ^eid} -> e
          x -> x
        end)

      save_meeting(socket, :edit, %{events: %{"events" => new_events}})
    else
      {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  defp save_meeting(socket, :edit, meeting_params) do
    case Meetings.update_meeting(socket.assigns.meeting, meeting_params) do
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
