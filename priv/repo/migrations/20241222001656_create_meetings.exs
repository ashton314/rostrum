defmodule Rostrum.Repo.Migrations.CreateMeetings do
  use Ecto.Migration

  def change do
    create table(:meetings) do
      add :date, :date
      add :metadata, :map
      add :events, :map
      add :unit_id, references(:units, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:meetings, [:unit_id])
  end
end
