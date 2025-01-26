defmodule RostrumWeb.MeetingLive.FormComponent do
  use RostrumWeb, :live_component

  alias Rostrum.Meetings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Meeting for {@current_unit.name}</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="meeting-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Meeting title" placeholder="e.g. Fast and Testimony Meeting"/>
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:topic]} type="text" label="Meeting topic" />
        <.input field={@form[:welcome_blurb]} type="text" label="Welcome blurb" placeholder="e.g. Welcome to the Church of Jesus Christ of Latter-day Saints"/>
        <.input field={@form[:presiding]} type="text" label="Presiding" />
        <.input field={@form[:conducting]} type="text" label="Conducting" />
        <.input field={@form[:chorister]} type="text" label="Chorister" />
        <.input field={@form[:business]} type="textarea" label="Business"
          placeholder="e.g.
Release
- Brother Bennet as teacher
- Mary Bennet as organist
- etc.

Call
- Brother Fitzwilliam as greeter
- etc."
          help="This information will only be visible to logged-in users. Markdown supported." />
        <.input
          field={@form[:accompanist_term]}
          type="select"
          label="Accompanist Term"
          options={["Organist", "Pianist", "Accompanist"]}
        />
        <.input field={@form[:accompanist]} type="text" label={@form[:accompanist_term].value} />

        <:actions>
          <.button phx-disable-with="Saving...">Save and edit events</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{meeting: meeting} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Meetings.change_meeting(meeting))
     end)}
  end

  @impl true
  def handle_event("validate", %{"meeting" => meeting_params}, socket) do
    changeset = Meetings.change_meeting(socket.assigns.meeting, meeting_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"meeting" => meeting_params}, socket) do
    save_meeting(socket, socket.assigns.action, meeting_params)
  end

  defp save_meeting(socket, :edit, meeting_params) do
    case Meetings.update_meeting(socket.assigns.meeting, meeting_params) do
      {:ok, meeting} ->
        notify_parent({:saved, meeting})

        {:noreply,
         socket
         |> put_flash(:info, "Meeting updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_meeting(socket, :new, meeting_params) do
    unit = socket.assigns.current_unit
    meeting_params =
      meeting_params
      |> Map.put("unit_id", unit.id)
      |> Map.put("events", socket.assigns.meeting.events)
    case Meetings.create_meeting(meeting_params) do
      {:ok, meeting} ->
        notify_parent({:saved, meeting})

        {:noreply,
         socket
         |> put_flash(:info, "Meeting created successfully")
         |> push_navigate(to: ~p"/meetings/#{meeting}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
