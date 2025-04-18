defmodule Rostrum.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rostrum.Events` context.
  """

  import Rostrum.AccountsFixtures

  @doc """
  Generate a calendar_event.
  """
  def calendar_event_fixture(attrs \\ %{}, unit \\ nil) do
    {user, unit} = if unit, do: {nil, unit}, else: user_unit_fixture()

    {:ok, calendar_event} =
      attrs
      |> Enum.into(%{
        description: "some description",
        event_date: ~U[2024-12-21 00:17:00Z],
        start_display: ~D[2024-12-21],
        time_description: "some time_description",
        title: "some title",
        unit_id: unit.id
      })
      |> Rostrum.Events.create_calendar_event()

    {calendar_event, unit, user}
  end
end
