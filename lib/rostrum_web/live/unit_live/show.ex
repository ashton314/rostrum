defmodule RostrumWeb.UnitLive.Show do
  use RostrumWeb, :live_view

  alias Rostrum.Accounts
  alias Rostrum.Accounts.Unit

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id, "user_id" => user_id}, _, socket) do
    user = socket.assigns.current_user
    modifying = Accounts.get_user!(user_id)
    unit = Accounts.get_unit!(id, user)
    users = get_users(unit)
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:unit, unit)
     |> assign(:modifying_user, modifying)
     |> assign(:users, users)}
  end

  def handle_params(%{"id" => id}, _, socket) do
    user = socket.assigns.current_user
    unit = Accounts.get_unit!(id, user)
    users = get_users(unit)
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:unit, unit)
     |> assign(:users, users)}
  end

  @impl true
  def handle_event("boot_user", %{"user" => user_id}, socket) do
    user = Accounts.get_user!(user_id)
    unit = socket.assigns.unit

    Accounts.remove_user_from_unit(unit, user)
    if user_id == socket.assigns.current_user.id do
      {:noreply,
       socket
       |> redirect(to: ~p"/units/")
       |> put_flash(:info, "You removed yourself from #{unit.name}")}
    else
      {:noreply,
       socket
       |> assign(:users, get_users(unit))
       |> put_flash(:info, "User removed successfully")}
    end
  end

  @impl true
  def handle_info({RostrumWeb.UnitLive.AddUserComponent, {:new_email, _email}}, socket) do
    {:noreply, assign(socket, :users, get_users(socket.assigns.unit))}
  end

  def handle_info({RostrumWeb.UnitLive.FormComponent, {:saved, fresh_unit}}, socket) do
    {:noreply, socket |> assign(:unit, fresh_unit) |> assign(:users, get_users(fresh_unit))}
  end

  defp page_title(:show), do: "Show Unit"
  defp page_title(:edit), do: "Edit Unit"
  defp page_title(:add_user), do: "Add User to Unit"
  defp page_title(:modify_user), do: "Change User Permissions"

  defp get_users(%Unit{} = u) do
    u.id
    |> Accounts.get_users_for_unit()
    |> Enum.map(fn usr ->
      role = Accounts.user_permission(usr, u)
      Map.put(usr, :role, role)
    end)
  end
end
