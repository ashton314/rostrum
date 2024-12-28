defmodule Rostrum.Repo.Migrations.CreateAnnouncements do
  use Ecto.Migration

  def change do
    create table(:announcements) do
      add :start_display, :date
      add :end_display, :date
      add :title, :string
      add :description, :text
      add :unit_id, references(:units, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:announcements, [:unit_id])
  end
end
