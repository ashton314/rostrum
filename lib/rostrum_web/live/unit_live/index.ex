defmodule RostrumWeb.UnitLive.Index do
  use RostrumWeb, :live_view

  alias Rostrum.Accounts
  alias Rostrum.Accounts.Unit

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :units, Accounts.list_units(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Unit")
    |> assign(:unit, Accounts.get_unit!(id, socket.asigns.current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Unit")
    |> assign(:unit, %Unit{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Units")
    |> assign(:unit, nil)
  end

  @impl true
  def handle_info({RostrumWeb.UnitLive.FormComponent, {:saved, unit}}, socket) do
    {:noreply, stream_insert(socket, :units, unit)}
  end

  def handle_info({RostrumWeb.UnitLive.FormComponent, {:saved_new, unit}}, socket) do
    Accounts.add_user_to_unit(socket.assigns.current_user.id, unit.id)
    {:noreply, stream_insert(socket, :units, unit)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    unit = Accounts.get_unit!(id, socket.assigns.current_user)
    {:ok, _} = Accounts.delete_unit(unit, socket.assigns.current_user)

    {:noreply, stream_delete(socket, :units, unit)}
  end
end
