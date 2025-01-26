defmodule Rostrum.Repo.Migrations.AddMeetingTopicBusiness do
  use Ecto.Migration

  def change do
    alter table(:meetings) do
      add :topic, :text, default: ""
      add :business, :text, default: ""
    end
  end
end
