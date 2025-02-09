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
    if nil do
      # notify_parent({:new_email, email})

      {:noreply,
       socket
       |> put_flash(:info, "User added to unit successfully")
       |> push_patch(to: socket.assigns.patch)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Unable to grant user role")
       |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
