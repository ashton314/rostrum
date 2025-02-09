defmodule RostrumWeb.UnitLive.ModifyUserComponent do
  use RostrumWeb, :live_component

  alias Rostrum.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Modify user access to <span class="font-semibold">{@unit.name}</span>.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="permissions-form"
        phx-target={@myself}
        phx-submit="save"
      >
        <.input
          field={@form[:role]}
          type="select"
          value={@form[:role].value}
          options={[
            {"Owner", "owner"},
            {"Editor", "editor"},
            {"Music", "music"}
            ]}
          />
        <:actions>
          <.button phx-disable-with="Saving...">Set permissions</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{unit: unit, modifying_user: mod_user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(%{"role" => Accounts.user_permission(mod_user, unit)}, as: "role")
     end)}
  end

  @impl true
  def handle_event("save", %{"role" => params}, socket) do
    dbg(params)
    role = params["role"]
    unit = socket.assigns.unit
    user = socket.assigns.current_user
    target_user = socket.assigns.modifying_user

    {kind, msg} =
      case Accounts.set_authorization_level(target_user, unit, role, user) do
        :ok ->
          {:info, "User permissions updated to #{role}"}

        {:error, :user_not_in_unit} ->
          {:error, "Target user is not associated with this unit"}

        {:error, :insufficient_permissions} ->
          {:error, "You do not have permission to elevate a user to role #{role}"}

        {:error, :illegal_authorization_level} ->
          {:error, "Not a valid role"}
      end

    {:noreply,
     socket
     |> put_flash(kind, msg)
     |> push_patch(to: socket.assigns.patch)}
  end
end
