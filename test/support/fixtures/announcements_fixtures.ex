defmodule Rostrum.AnnouncementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rostrum.Announcements` context.
  """

  import Rostrum.AccountsFixtures

  @doc """
  Generate a announcement.
  """
  def announcement_fixture(attrs \\ %{}, unit \\ nil) do
    {user, unit} = if unit, do: {nil, unit}, else: user_unit_fixture()

    {:ok, announcement} =
      attrs
      |> Enum.into(%{
        description: "some description",
        end_display: ~D[2024-12-21],
        start_display: ~D[2024-12-21],
        title: "some title",
        unit_id: unit.id
      })
      |> Rostrum.Announcements.create_announcement()

    {announcement, unit, user}
  end
end
