defmodule Rostrum.Repo.Migrations.AddUserRoll do
  use Ecto.Migration

  def change do
    alter table(:users_units) do
      add :role, :string, default: "owner"
    end
  end
end
