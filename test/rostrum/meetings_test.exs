defmodule Rostrum.MeetingsTest do
  use Rostrum.DataCase

  alias Rostrum.Meetings

  def unnilify(%Meetings.Meeting{} = m) do
    for k <- Map.keys(m) do
      {k, if(Map.get(m, k) == nil, do: "", else: Map.get(m, k))}
    end
    |> Enum.into(%{})
  end

  describe "meetings" do
    alias Rostrum.Meetings.Meeting

    import Rostrum.MeetingsFixtures
    import Rostrum.AccountsFixtures

    @invalid_attrs %{date: nil, events: nil, metadata: nil}

    test "list_meetings/0 returns all meetings" do
      {_user, unit} = user_unit_fixture()
      meeting = meeting_fixture(unit)
      assert Meetings.list_meetings(unit) == [unnilify(meeting)]
    end

    test "get_meeting!/1 returns the meeting with given id" do
      {_user, unit} = user_unit_fixture()
      meeting = meeting_fixture(unit)
      assert Meetings.get_meeting!(meeting.id, unit) == unnilify(meeting)
    end

    test "create_meeting/1 with valid data creates a meeting" do
      {_user, unit} = user_unit_fixture()
      valid_attrs = %{date: ~D[2024-12-21], events: %{}, metadata: %{}, unit_id: unit.id}

      assert {:ok, %Meeting{} = meeting} = Meetings.create_meeting(valid_attrs)
      assert meeting.date == ~D[2024-12-21]
      assert meeting.events == %{}
      assert meeting.metadata == %{}
    end

    test "create_meeting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Meetings.create_meeting(@invalid_attrs)
    end

    test "update_meeting/2 with valid data updates the meeting" do
      {_user, unit} = user_unit_fixture()
      meeting = meeting_fixture(unit)
      update_attrs = %{date: ~D[2024-12-22], events: %{}, metadata: %{}}

      assert {:ok, %Meeting{} = meeting} = Meetings.update_meeting(meeting, update_attrs)
      assert meeting.date == ~D[2024-12-22]
      assert meeting.events == %{}
      assert meeting.metadata == %{}
    end

    test "update_meeting/2 with invalid data returns error changeset" do
      {_user, unit} = user_unit_fixture()
      meeting = meeting_fixture(unit)
      assert {:error, %Ecto.Changeset{}} = Meetings.update_meeting(meeting, @invalid_attrs)
      assert unnilify(meeting) == Meetings.get_meeting!(meeting.id, unit)
    end

    test "delete_meeting/1 deletes the meeting" do
      {_user, unit} = user_unit_fixture()
      meeting = meeting_fixture(unit)
      assert {:ok, %Meeting{}} = Meetings.delete_meeting(meeting)
      assert_raise Ecto.NoResultsError, fn -> Meetings.get_meeting!(meeting.id, unit) end
    end

    test "change_meeting/1 returns a meeting changeset" do
      {_user, unit} = user_unit_fixture()
      meeting = meeting_fixture(unit)
      assert %Ecto.Changeset{} = Meetings.change_meeting(meeting)
    end
  end

  describe "templates" do
    alias Rostrum.Meetings.Template

    import Rostrum.AccountsFixtures
    import Rostrum.MeetingsFixtures

    @invalid_attrs %{events: nil, title: nil, welcome_blurb: nil}

    test "list_templates/0 returns all templates" do
      {_user, unit} = user_unit_fixture()
      template = template_fixture(unit)
      assert Meetings.list_templates(unit) == [template]
    end

    test "get_template!/1 returns the template with given id" do
      {_user, unit} = user_unit_fixture()
      template = template_fixture(unit)
      assert Meetings.get_template!(template.id, unit) == template
    end

    test "create_template/1 with valid data creates a template" do
      unit = unit_fixture()

      valid_attrs = %{
        events: %{},
        title: "some title",
        welcome_blurb: "some welcome_blurb",
        unit_id: unit.id
      }

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

      update_attrs = %{
        events: %{},
        title: "some updated title",
        welcome_blurb: "some updated welcome_blurb"
      }

      assert {:ok, %Template{} = template} = Meetings.update_template(template, update_attrs)
      assert template.events == %{}
      assert template.title == "some updated title"
      assert template.welcome_blurb == "some updated welcome_blurb"
    end

    test "update_template/2 with invalid data returns error changeset" do
      {_user, unit} = user_unit_fixture()
      template = template_fixture(unit)
      assert {:error, %Ecto.Changeset{}} = Meetings.update_template(template, @invalid_attrs)
      assert template == Meetings.get_template!(template.id, unit)
    end

    test "delete_template/1 deletes the template" do
      {_user, unit} = user_unit_fixture()
      template = template_fixture(unit)
      assert {:ok, %Template{}} = Meetings.delete_template(template)
      assert_raise Ecto.NoResultsError, fn -> Meetings.get_template!(template.id, unit) end
    end

    test "change_template/1 returns a template changeset" do
      template = template_fixture()
      assert %Ecto.Changeset{} = Meetings.change_template(template)
    end

    # From o3-mini
    @valid_template_attrs %{
      title: "Sacrament Meeting Program",
      welcome_blurb: "Welcome, dear brothers and sisters",
      events: %{"events" => [%{"id" => "evt1", "type" => "opening-hymn"}]}
    }

    @meeting_data %{
      date: ~D[2024-12-21],
      presiding: "Bishop Smith",
      conducting: "Elder Doe"
    }

    test "converts a template to a meeting changeset with merged fields" do
      # Build a Template struct as if loaded from DB.
      unit = unit_fixture()
      template = template_fixture(unit, @valid_template_attrs)

      changeset = Template.to_meeting(template, @meeting_data)

      # Assert that the changeset is valid.
      assert changeset.valid?

      # Extract the changes for inspection.
      meeting = apply_changes(changeset)

      # Fields from template should be merged in
      assert meeting.title == @valid_template_attrs.title
      assert meeting.welcome_blurb == @valid_template_attrs.welcome_blurb
      assert meeting.events == @valid_template_attrs.events

      # Fields passed in meeting_data are also present.
      assert meeting.date == ~D[2024-12-21]
      assert meeting.presiding == "Bishop Smith"
      assert meeting.conducting == "Elder Doe"
    end

    test "returns an invalid changeset when required meeting_data are missing" do
      # Remove required :date and :unit_id from meeting_data
      template = struct(Template, @valid_template_attrs)
      changeset = Template.to_meeting(template, %{})
      refute changeset.valid?
      assert %{date: ["can't be blank"], unit_id: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
