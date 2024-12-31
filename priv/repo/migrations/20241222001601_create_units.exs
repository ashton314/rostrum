defmodule Rostrum.Repo.Migrations.CreateUnits do
  use Ecto.Migration

  def change do
    create table(:units) do
      add :name, :string
      add :slug, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:units, [:slug])
  end
end
