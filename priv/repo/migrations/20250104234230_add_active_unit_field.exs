defmodule Rostrum.Repo.Migrations.AddActiveUnitField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :active_unit_id, :integer
    end
  end
end
