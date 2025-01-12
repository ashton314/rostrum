defmodule Rostrum.Repo.Migrations.AddUnitTimezone do
  use Ecto.Migration

  def change do
    alter table(:units) do
      add :timezone, :text, default: "America/Denver"
    end
  end
end
