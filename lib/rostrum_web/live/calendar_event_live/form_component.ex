defmodule RostrumWeb.CalendarEventLive.FormComponent do
  use RostrumWeb, :live_component

  alias Rostrum.Events

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage calendar_event records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="calendar_event-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:start_display]} type="date" label="Start display" />
        <.input field={@form[:event_date]} type="datetime-local" label="Event date" />
        <.input field={@form[:time_description]} type="text" label="Time description" />
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="text" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Calendar event</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{calendar_event: calendar_event} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Events.change_calendar_event(calendar_event))
     end)}
  end

  @impl true
  def handle_event("validate", %{"calendar_event" => calendar_event_params}, socket) do
    changeset = Events.change_calendar_event(socket.assigns.calendar_event, calendar_event_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"calendar_event" => calendar_event_params}, socket) do
    save_calendar_event(socket, socket.assigns.action, calendar_event_params)
  end

  defp save_calendar_event(socket, :edit, calendar_event_params) do
    case Events.update_calendar_event(socket.assigns.calendar_event, calendar_event_params) do
      {:ok, calendar_event} ->
        notify_parent({:saved, calendar_event})

        {:noreply,
         socket
         |> put_flash(:info, "Calendar event updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_calendar_event(socket, :new, calendar_event_params) do
    case Events.create_calendar_event(calendar_event_params) do
      {:ok, calendar_event} ->
        notify_parent({:saved, calendar_event})

        {:noreply,
         socket
         |> put_flash(:info, "Calendar event created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
