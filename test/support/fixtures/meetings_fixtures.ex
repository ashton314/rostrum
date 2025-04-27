defmodule Rostrum.MeetingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rostrum.Meetings` context.
  """

  alias Rostrum.Accounts.Unit

  @doc """
  Generate a meeting.
  """
  def meeting_fixture(%Unit{} = u, attrs \\ %{}) do
    {:ok, meeting} =
      Map.merge(%{
        date: ~D[2024-12-21],
        events: %{},
        unit_id: u.id,
        metadata: %{}
      }, attrs)
      |> Rostrum.Meetings.create_meeting()

    meeting
  end

  @doc """
  Generate a template.
  """
  def template_fixture(u \\ nil, attrs \\ %{}) do
    u = if u, do: u, else: Rostrum.AccountsFixtures.unit_fixture()

    {:ok, template} =
      Map.merge(%{
        events: %{},
        unit_id: u.id,
        title: "some title",
        welcome_blurb: "some welcome_blurb"
      }, attrs)
      |> Rostrum.Meetings.create_template()

    template
  end
end
