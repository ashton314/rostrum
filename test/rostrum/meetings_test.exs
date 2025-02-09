defmodule Rostrum.MeetingsTest do
  use Rostrum.DataCase

  alias Rostrum.Meetings

  describe "meetings" do
    alias Rostrum.Meetings.Meeting

    import Rostrum.MeetingsFixtures

    @invalid_attrs %{date: nil, events: nil, metadata: nil}

    test "list_meetings/0 returns all meetings" do
      meeting = meeting_fixture()
      assert Meetings.list_meetings() == [meeting]
    end

    test "get_meeting!/1 returns the meeting with given id" do
      meeting = meeting_fixture()
      assert Meetings.get_meeting!(meeting.id) == meeting
    end

    test "create_meeting/1 with valid data creates a meeting" do
      valid_attrs = %{date: ~D[2024-12-21], events: %{}, metadata: %{}}

      assert {:ok, %Meeting{} = meeting} = Meetings.create_meeting(valid_attrs)
      assert meeting.date == ~D[2024-12-21]
      assert meeting.events == %{}
      assert meeting.metadata == %{}
    end

    test "create_meeting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Meetings.create_meeting(@invalid_attrs)
    end

    test "update_meeting/2 with valid data updates the meeting" do
      meeting = meeting_fixture()
      update_attrs = %{date: ~D[2024-12-22], events: %{}, metadata: %{}}

      assert {:ok, %Meeting{} = meeting} = Meetings.update_meeting(meeting, update_attrs)
      assert meeting.date == ~D[2024-12-22]
      assert meeting.events == %{}
      assert meeting.metadata == %{}
    end

    test "update_meeting/2 with invalid data returns error changeset" do
      meeting = meeting_fixture()
      assert {:error, %Ecto.Changeset{}} = Meetings.update_meeting(meeting, @invalid_attrs)
      assert meeting == Meetings.get_meeting!(meeting.id)
    end

    test "delete_meeting/1 deletes the meeting" do
      meeting = meeting_fixture()
      assert {:ok, %Meeting{}} = Meetings.delete_meeting(meeting)
      assert_raise Ecto.NoResultsError, fn -> Meetings.get_meeting!(meeting.id) end
    end

    test "change_meeting/1 returns a meeting changeset" do
      meeting = meeting_fixture()
      assert %Ecto.Changeset{} = Meetings.change_meeting(meeting)
    end
  end

  describe "templates" do
    alias Rostrum.Meetings.Template

    import Rostrum.MeetingsFixtures

    @invalid_attrs %{events: nil, title: nil, welcome_blurb: nil}

    test "list_templates/0 returns all templates" do
      template = template_fixture()
      assert Meetings.list_templates() == [template]
    end

    test "get_template!/1 returns the template with given id" do
      template = template_fixture()
      assert Meetings.get_template!(template.id) == template
    end

    test "create_template/1 with valid data creates a template" do
      valid_attrs = %{events: %{}, title: "some title", welcome_blurb: "some welcome_blurb"}

      assert {:ok, %Template{} = template} = Meetings.create_template(valid_attrs)
      assert template.events == %{}
      assert template.title == "some title"
      assert template.welcome_blurb == "some welcome_blurb"
    end

    test "create_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Meetings.create_template(@invalid_attrs)
    end

    test "update_template/2 with valid data updates the template" do
      template = template_fixture()
      update_attrs = %{events: %{}, title: "some updated title", welcome_blurb: "some updated welcome_blurb"}

      assert {:ok, %Template{} = template} = Meetings.update_template(template, update_attrs)
      assert template.events == %{}
      assert template.title == "some updated title"
      assert template.welcome_blurb == "some updated welcome_blurb"
    end

    test "update_template/2 with invalid data returns error changeset" do
      template = template_fixture()
      assert {:error, %Ecto.Changeset{}} = Meetings.update_template(template, @invalid_attrs)
      assert template == Meetings.get_template!(template.id)
    end

    test "delete_template/1 deletes the template" do
      template = template_fixture()
      assert {:ok, %Template{}} = Meetings.delete_template(template)
      assert_raise Ecto.NoResultsError, fn -> Meetings.get_template!(template.id) end
    end

    test "change_template/1 returns a template changeset" do
      template = template_fixture()
      assert %Ecto.Changeset{} = Meetings.change_template(template)
    end
  end
end
