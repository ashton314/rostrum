defmodule Rostrum.Accounts.Unit do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "units" do
    field :name, :string
    field :slug, :string
    field :timezone, :string, default: "America/Denver"
    many_to_many :users, Rostrum.Accounts.User, join_through: "users_units"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:name, :slug, :timezone])
    |> validate_required([:name, :slug, :timezone])
    |> validate_format(:slug, ~r/[a-zA-Z0-9-]/, message: "may only contain letters, digits, and dashes")
    |> unsafe_validate_unique(:slug, Rostrum.Repo)
    |> unique_constraint(:slug)
  end
end
