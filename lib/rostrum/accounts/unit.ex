defmodule Rostrum.Accounts.Unit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "units" do
    field :name, :string
    field :slug, :string
    many_to_many :users, Rostrum.Accounts.User, join_through: "users_units"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unsafe_validate_unique(:slug, Rostrum.Repo)
    |> unique_constraint(:slug)
  end
end
