defmodule Rostrum.AnnouncementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rostrum.Announcements` context.
  """

  @doc """
  Generate a announcement.
  """
  def announcement_fixture(attrs \\ %{}) do
    {:ok, announcement} =
      attrs
      |> Enum.into(%{
        description: "some description",
        end_display: ~D[2024-12-21],
        start_display: ~D[2024-12-21],
        title: "some title"
      })
      |> Rostrum.Announcements.create_announcement()

    announcement
  end
end
