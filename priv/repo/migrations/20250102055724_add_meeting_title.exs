defmodule Rostrum.Repo.Migrations.AddMeetingTitle do
  use Ecto.Migration

  def change do
    alter table(:meetings) do
      add :title, :text, default: "Sacrament Meeting"
    end
  end
end
