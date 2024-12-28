defmodule Rostrum.Announcements.Announcement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "announcements" do
    field :description, :string
    field :title, :string
    field :start_display, :date
    field :end_display, :date
    field :unit_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [:start_display, :end_display, :title, :description])
    |> validate_required([:start_display, :end_display, :title, :description])
  end
end
