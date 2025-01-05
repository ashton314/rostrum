defmodule RostrumWeb.AnnouncementLive.Show do
  use RostrumWeb, :live_view

  alias Rostrum.Announcements

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    announcement = Announcements.get_announcement!(id, socket.assigns.current_unit)

    preview =
      case Earmark.as_html(announcement.description || "") do
        {:ok, html_doc, _} ->
          html_doc
        {:error, html_doc, error_messages} ->
          dbg(error_messages)
          html_doc
      end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:preview, preview)
     |> assign(:announcement, announcement)}
  end

  defp page_title(:show), do: "Show Announcement"
  defp page_title(:edit), do: "Edit Announcement"
end
