defmodule RostrumWeb.UnitLive.AddUserComponent do
  use RostrumWeb, :live_component

  alias Rostrum.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Grant another user access to <span class="font-semibold">{@unit.name}</span>.</:subtitle>
      </.header>

      <.warning>
        <p>
        Adding an email here grants an account with that email
        <strong>full</strong> access to this unit. This will allow them to
          modify meetings, add other users, and even delete the unit.
        </p>

        <p class="mt-2">
        Rostrum does not have finer-grained access controls at the
        moment. This is in development.
        </p>
      </.warning>

      <.info>
        <p>
          If the person with an email here does not have an account
          already, they will be automatically associated with this
          unit when the make one.
        </p>
      </.info>

      <.simple_form
        for={@form}
        id="unit-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:email]} type="email" label="Email" autocomplete="off" />
        <:actions>
          <.button phx-disable-with="Saving...">Add to unit</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{unit: _unit} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(%{"email" => ""}, as: "email")
     end)}
  end

  @impl true
  def handle_event("validate", %{"email" => params}, socket) do
    unit = socket.assigns.unit |> Rostrum.Repo.preload([:users])
    import Ecto.Changeset
    types = %{email: :string}
    changeset =
      {%{}, types}
      |> cast(params, [:email])
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
      |> validate_length(:email, max: 160)
      |> validate_change(:email, fn :email, email ->
        if Enum.any?(unit.users, fn %{email: e} -> e == email end) do
          [email: {"email is already associated with this unit", additional: "info"}]
        else
          []
        end
      end)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "email"))}
  end

  def handle_event("save", %{"email" => params}, socket) do
    email = params["email"]
    if Accounts.add_user_to_unit_by_email(socket.assigns.unit, email) do
      notify_parent({:new_email, email})

      {:noreply,
       socket
       |> put_flash(:info, "User added to unit successfully")
       |> push_patch(to: socket.assigns.patch)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Unable to add user with email address #{email}")
       |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
