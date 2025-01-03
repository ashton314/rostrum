defmodule Rostrum.Repo.Migrations.AddMeetingLeadershipFields do
  use Ecto.Migration

  def change do
    alter table(:meetings) do
      add :presiding, :text, default: ""
      add :conducting, :text, default: ""
      add :accompanist, :text, default: ""
      add :accompanist_term, :text, default: ""
      add :chorister, :text, default: ""
    end
  end
end
