defmodule RostrumWeb.AnnouncementLive.Index do
  use RostrumWeb, :live_view

  alias Rostrum.Announcements
  alias Rostrum.Announcements.Announcement

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :announcements, Announcements.list_announcements(socket.assigns.current_unit))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Announcement")
    |> assign(:announcement, Announcements.get_announcement!(id, socket.assigns.current_unit))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Announcement")
    |> assign(:announcement, %Announcement{start_display: Timex.today()})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Announcements")
    |> assign(:announcement, nil)
  end

  @impl true
  def handle_info({RostrumWeb.AnnouncementLive.FormComponent, {:saved, announcement}}, socket) do
    {:noreply, stream_insert(socket, :announcements, announcement)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    announcement = Announcements.get_announcement!(id, socket.assigns.current_unit)
    {:ok, _} = Announcements.delete_announcement(announcement)

    {:noreply, stream_delete(socket, :announcements, announcement)}
  end

  def preview(announcement) do
    Earmark.as_html!(announcement.description || "")
  end
end
