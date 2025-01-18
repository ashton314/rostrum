defmodule RostrumWeb.CalendarEventLive.FormComponent do
  use RostrumWeb, :live_component

  alias Rostrum.Events
  alias Rostrum.DateUtils

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage calendar events.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="calendar_event-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:start_display]} type="date" label="Start display" />
        <.input
          field={@form[:event_date]}
          type="datetime-local"
          help="Use this for specific non-repeating events, e.g. a game night."
          label="Event date"
        />
        <.input
          field={@form[:time_description]}
          type="text"
          help="Use this to describe repeating events."
          label="Time description"
        />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <.info>
          You can use
          <.link
            class="underline text-sky-800"
            href="https://daringfireball.net/projects/markdown/basics"
          >
            Markdown↗
          </.link>
          to format text and add links to the description of
          announcements. The short of it: use one star for
          *<em>italics</em>*, two stars for **<strong>bold</strong>**, and format links [like this](https://example.com).
        </.info>

        <.label>Preview</.label>
        <div class="calendar-event program-event">
          <div class="event-metadata">
            <span class="event-title">{@form[:title].value}</span>
            <span class="event-datetime">{@td_desc}</span>
          </div>
          <div class="event-description">
            {raw(@preview)}
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Calendar event</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{calendar_event: calendar_event} = assigns, socket) do
    preview =
      case Earmark.as_html(calendar_event.description || "") do
        {:ok, html_doc, _} ->
          html_doc

        {:error, html_doc, error_messages} ->
          dbg(error_messages)
          html_doc
      end

    desc = calendar_event.time_description
    dt = calendar_event.event_date &&
      calendar_event.event_date
      |> DateTime.shift_zone!(assigns.current_unit.timezone)

    td_desc =
      if is_binary(desc) && desc != "" do
        desc
      else
        if dt,
           do: Timex.format!(dt, "%A, %B %d, %Y at %l:%M %p", :strftime),
           else: ""
      end

    calendar_event =
      case calendar_event.event_date do
        %DateTime{} = d -> %{calendar_event | event_date: DateTime.shift_zone!(d, assigns.current_unit.timezone)}
        _ -> calendar_event
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:preview, preview)
     |> assign(:td_desc, td_desc)
     |> assign_new(:form, fn ->
       to_form(Events.change_calendar_event(calendar_event))
     end)}
  end

  @impl true
  def handle_event("validate", %{"calendar_event" => calendar_event_params}, socket) do
    changeset = Events.change_calendar_event(socket.assigns.calendar_event, calendar_event_params)

    preview =
      case Earmark.as_html(calendar_event_params["description"]) do
        {:ok, html_doc, _} ->
          html_doc

        {:error, html_doc, error_messages} ->
          dbg(error_messages)
          html_doc
      end

    desc = calendar_event_params["time_description"]
    dt = calendar_event_params["event_date"] |> dbg()

    td_desc =
      if is_binary(desc) && desc != "" do
        desc
      else
        if dt && dt != "",
          do: Timex.format!(Timex.parse!(dt, "%FT%H:%M", :strftime), "%A, %B %d, %Y", :strftime),
          else: ""
      end

    {:noreply,
     socket
     |> assign(:preview, preview)
     |> assign(:td_desc, td_desc)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"calendar_event" => calendar_event_params}, socket) do
    save_calendar_event(socket, socket.assigns.action, calendar_event_params)
  end

  defp save_calendar_event(socket, :edit, calendar_event_params) do
    unit = socket.assigns.current_unit
    calendar_event_params =
      calendar_event_params
      |> Map.put("unit_id", unit.id)
      |> DateUtils.params_to_utc(["event_date"], unit.timezone)

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
    unit = socket.assigns.current_unit
    calendar_event_params =
      calendar_event_params
      |> dbg()
      |> Map.put("unit_id", unit.id)
      |> DateUtils.params_to_utc(["event_date"], unit.timezone)

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
