defmodule Rostrum.Repo.Migrations.CreateUnits do
  use Ecto.Migration

  def change do
    create table(:units) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
