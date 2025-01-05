defmodule Rostrum.Announcements.Announcement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "announcements" do
    field :description, :string
    field :title, :string
    field :start_display, :date
    field :end_display, :date
    belongs_to :unit, Rostrum.Accounts.Unit

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [:start_display, :end_display, :title, :description, :unit_id])
    |> validate_required([:start_display, :title, :description, :unit_id])
  end
end
