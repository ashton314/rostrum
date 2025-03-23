defmodule Rostrum.EventsTest do
  use Rostrum.DataCase

  alias Rostrum.Events

  describe "calendar_events" do
    alias Rostrum.Events.CalendarEvent

    import Rostrum.EventsFixtures
    import Rostrum.AccountsFixtures

    @invalid_attrs %{
      description: nil,
      title: nil,
      start_display: nil,
      event_date: nil,
      time_description: nil
    }

    test "list_calendar_events/1 returns all calendar_events" do
      {calendar_event, unit, _user} = calendar_event_fixture()
      assert Events.list_calendar_events(unit) == [calendar_event]
    end

    test "get_calendar_event!/2 returns the calendar_event with given id" do
      {calendar_event, unit, _user} = calendar_event_fixture()
      assert Events.get_calendar_event!(calendar_event.id, unit) == calendar_event
    end

    test "create_calendar_event/1 with valid data creates a calendar_event" do
      unit = unit_fixture()

      valid_attrs = %{
        description: "some description",
        title: "some title",
        start_display: ~D[2024-12-21],
        event_date: ~U[2024-12-21 00:17:00Z],
        time_description: "some time_description",
        unit_id: unit.id
      }

      assert {:ok, %CalendarEvent{} = calendar_event} = Events.create_calendar_event(valid_attrs)
      assert calendar_event.description == "some description"
      assert calendar_event.title == "some title"
      assert calendar_event.start_display == ~D[2024-12-21]
      assert calendar_event.event_date == ~U[2024-12-21 00:17:00Z]
      assert calendar_event.time_description == "some time_description"
    end

    test "create_calendar_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_calendar_event(@invalid_attrs)
    end

    test "update_calendar_event/2 with valid data updates the calendar_event" do
      {calendar_event, _unit, _user} = calendar_event_fixture()

      update_attrs = %{
        description: "some updated description",
        title: "some updated title",
        start_display: ~D[2024-12-22],
        event_date: ~U[2024-12-22 00:17:00Z],
        time_description: "some updated time_description"
      }

      assert {:ok, %CalendarEvent{} = calendar_event} =
               Events.update_calendar_event(calendar_event, update_attrs)

      assert calendar_event.description == "some updated description"
      assert calendar_event.title == "some updated title"
      assert calendar_event.start_display == ~D[2024-12-22]
      assert calendar_event.event_date == ~U[2024-12-22 00:17:00Z]
      assert calendar_event.time_description == "some updated time_description"
    end

    test "update_calendar_event/2 with invalid data returns error changeset" do
      {calendar_event, unit, _user} = calendar_event_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Events.update_calendar_event(calendar_event, @invalid_attrs)

      assert calendar_event == Events.get_calendar_event!(calendar_event.id, unit)
    end

    test "delete_calendar_event/1 deletes the calendar_event" do
      {calendar_event, unit, _user} = calendar_event_fixture()
      assert {:ok, %CalendarEvent{}} = Events.delete_calendar_event(calendar_event)

      assert_raise Ecto.NoResultsError, fn ->
        Events.get_calendar_event!(calendar_event.id, unit)
      end
    end

    test "change_calendar_event/1 returns a calendar_event changeset" do
      {calendar_event, _unit, _user} = calendar_event_fixture()
      assert %Ecto.Changeset{} = Events.change_calendar_event(calendar_event)
    end
  end
end
