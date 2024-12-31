defmodule Rostrum.Repo.Migrations.CreateUsersUnits do
  use Ecto.Migration

  def change do
    create table(:users_units) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :unit_id, references(:units, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create unique_index(:users_units, [:user_id, :unit_id])
  end
end
