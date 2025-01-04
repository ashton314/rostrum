defmodule RostrumWeb.UnitLive.Show do
  use RostrumWeb, :live_view

  alias Rostrum.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user
    unit = Accounts.get_unit!(id, user)
    users = Accounts.get_users_for_unit(id)
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:unit, unit)
     |> stream(:users, users)}
  end

  @impl true
  def handle_event("boot_user", %{"user" => user_id}, socket) do
    user = Accounts.get_user!(user_id)
    unit = socket.assigns.unit
    Accounts.remove_user_from_unit(unit, user)
    {:noreply,
     socket
     |> put_flash(:info, "User removed successfully")}
  end

  @impl true
  def handle_info({RostrumWeb.UnitLive.AddUserComponent, {:new_email, email}}, socket) do
    user = Accounts.get_user_by_email(email)
    {:noreply, stream_insert(socket, :users, user)}
  end

  defp page_title(:show), do: "Show Unit"
  defp page_title(:edit), do: "Edit Unit"
  defp page_title(:add_user), do: "Add User to Unit"
end
