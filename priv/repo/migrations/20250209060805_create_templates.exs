defmodule Rostrum.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :events, :map
      add :title, :string
      add :welcome_blurb, :string
      add :unit_id, references(:units, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:templates, [:unit_id])
  end
end
