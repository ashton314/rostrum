defmodule Rostrum.Accounts.Unit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "units" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
