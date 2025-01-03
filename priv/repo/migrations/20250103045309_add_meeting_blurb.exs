defmodule Rostrum.Repo.Migrations.AddMeetingBlurb do
  use Ecto.Migration

  def change do
    alter table(:meetings) do
      add :welcome_blurb, :text, default: ""
    end
  end
end
