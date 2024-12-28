defmodule Rostrum.MeetingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rostrum.Meetings` context.
  """

  @doc """
  Generate a meeting.
  """
  def meeting_fixture(attrs \\ %{}) do
    {:ok, meeting} =
      attrs
      |> Enum.into(%{
        date: ~D[2024-12-21],
        events: %{},
        metadata: %{}
      })
      |> Rostrum.Meetings.create_meeting()

    meeting
  end
end
