defmodule Rostrum.Events.CalendarEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "calendar_events" do
    field :description, :string
    field :title, :string
    field :start_display, :date
    field :event_date, :utc_datetime
    field :time_description, :string
    field :unit_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(calendar_event, attrs) do
    calendar_event
    |> cast(attrs, [:start_display, :event_date, :time_description, :title, :description])
    |> validate_required([:start_display, :event_date, :time_description, :title, :description])
  end
end
