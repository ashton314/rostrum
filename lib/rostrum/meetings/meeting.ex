defmodule Rostrum.Meetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meetings" do
    field :date, :date
    field :events, :map
    field :metadata, :map
    field :unit_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [:date, :metadata, :events])
    |> validate_required([:date])
  end
end
