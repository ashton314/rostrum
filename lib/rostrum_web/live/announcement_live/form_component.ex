defmodule RostrumWeb.AnnouncementLive.FormComponent do
alias Rostrum.DateUtils
  use RostrumWeb, :live_component

  alias Rostrum.Announcements

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage announcements.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="announcement-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:start_display]} type="date" help="The announcement won't display until this day." label="Start display" />
        <.input field={@form[:end_display]} type="date" help="This event will be archived automatically after this day." label="End display" />
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <.info>
          You can use <.link class="underline text-sky-800" href="https://daringfireball.net/projects/markdown/basics">Markdown↗</.link>

          to format text and add links to the description of
          announcements. The short of it: use one star for
          *<em>italics</em>*, two stars for **<strong>bold</strong>**, and format links [like this](https://example.com).

        </.info>

        <.label>Preview</.label>
        <div class="announcement program-event">
          <div class="announcement-header">{@form[:title].value}</div>
          <div class="announcement-description">
            {raw(@rendered_description)}
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Announcement</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{announcement: announcement} = assigns, socket) do
    preview =
      case Earmark.as_html(announcement.description || "") do
        {:ok, html_doc, _} ->
          html_doc
        {:error, html_doc, error_messages} ->
          dbg(error_messages)
          html_doc
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rendered_description, preview)
     |> assign_new(:form, fn ->
       to_form(Announcements.change_announcement(announcement))
     end)}
  end

  @impl true
  def handle_event("validate", %{"announcement" => announcement_params}, socket) do
    changeset = Announcements.change_announcement(socket.assigns.announcement, announcement_params)
    preview =
      case Earmark.as_html(announcement_params["description"]) do
        {:ok, html_doc, _} ->
          html_doc
        {:error, html_doc, error_messages} ->
          dbg(error_messages)
          html_doc
      end

    {:noreply,
     socket
     |> assign(:rendered_description, preview)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"announcement" => announcement_params}, socket) do
    save_announcement(socket, socket.assigns.action, announcement_params)
  end

  defp save_announcement(socket, :edit, announcement_params) do
    unit = socket.assigns.current_unit
    announcement_params =
      announcement_params
      |> Map.put("unit_id", unit.id)

    case Announcements.update_announcement(socket.assigns.announcement, announcement_params) do
      {:ok, announcement} ->
        notify_parent({:saved, announcement})

        {:noreply,
         socket
         |> put_flash(:info, "Announcement updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_announcement(socket, :new, announcement_params) do
    unit = socket.assigns.current_unit
    announcement_params =
      announcement_params
      |> Map.put("unit_id", unit.id)

    case Announcements.create_announcement(announcement_params) do
      {:ok, announcement} ->
        notify_parent({:saved, announcement})

        {:noreply,
         socket
         |> put_flash(:info, "Announcement created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
