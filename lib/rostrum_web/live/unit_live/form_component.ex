defmodule RostrumWeb.UnitLive.FormComponent do
  use RostrumWeb, :live_component

  alias Rostrum.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage unit records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="unit-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Unit</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{unit: unit} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_unit(unit))
     end)}
  end

  @impl true
  def handle_event("validate", %{"unit" => unit_params}, socket) do
    changeset = Accounts.change_unit(socket.assigns.unit, unit_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"unit" => unit_params}, socket) do
    save_unit(socket, socket.assigns.action, unit_params)
  end

  defp save_unit(socket, :edit, unit_params) do
    case Accounts.update_unit(socket.assigns.unit, unit_params) do
      {:ok, unit} ->
        notify_parent({:saved, unit})

        {:noreply,
         socket
         |> put_flash(:info, "Unit updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_unit(socket, :new, unit_params) do
    case Accounts.create_unit(unit_params) do
      {:ok, unit} ->
        notify_parent({:saved, unit})

        {:noreply,
         socket
         |> put_flash(:info, "Unit created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
