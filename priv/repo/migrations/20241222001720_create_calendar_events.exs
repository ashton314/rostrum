defmodule Rostrum.Repo.Migrations.CreateCalendarEvents do
  use Ecto.Migration

  def change do
    create table(:calendar_events) do
      add :start_display, :date
      add :event_date, :utc_datetime
      add :time_description, :string
      add :title, :string
      add :description, :text
      add :unit_id, references(:units, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:calendar_events, [:unit_id])
  end
end
