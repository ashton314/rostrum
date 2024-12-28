defmodule Rostrum.AnnouncementsTest do
  use Rostrum.DataCase

  alias Rostrum.Announcements

  describe "announcements" do
    alias Rostrum.Announcements.Announcement

    import Rostrum.AnnouncementsFixtures

    @invalid_attrs %{description: nil, title: nil, start_display: nil, end_display: nil}

    test "list_announcements/0 returns all announcements" do
      announcement = announcement_fixture()
      assert Announcements.list_announcements() == [announcement]
    end

    test "get_announcement!/1 returns the announcement with given id" do
      announcement = announcement_fixture()
      assert Announcements.get_announcement!(announcement.id) == announcement
    end

    test "create_announcement/1 with valid data creates a announcement" do
      valid_attrs = %{description: "some description", title: "some title", start_display: ~D[2024-12-21], end_display: ~D[2024-12-21]}

      assert {:ok, %Announcement{} = announcement} = Announcements.create_announcement(valid_attrs)
      assert announcement.description == "some description"
      assert announcement.title == "some title"
      assert announcement.start_display == ~D[2024-12-21]
      assert announcement.end_display == ~D[2024-12-21]
    end

    test "create_announcement/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Announcements.create_announcement(@invalid_attrs)
    end

    test "update_announcement/2 with valid data updates the announcement" do
      announcement = announcement_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", start_display: ~D[2024-12-22], end_display: ~D[2024-12-22]}

      assert {:ok, %Announcement{} = announcement} = Announcements.update_announcement(announcement, update_attrs)
      assert announcement.description == "some updated description"
      assert announcement.title == "some updated title"
      assert announcement.start_display == ~D[2024-12-22]
      assert announcement.end_display == ~D[2024-12-22]
    end

    test "update_announcement/2 with invalid data returns error changeset" do
      announcement = announcement_fixture()
      assert {:error, %Ecto.Changeset{}} = Announcements.update_announcement(announcement, @invalid_attrs)
      assert announcement == Announcements.get_announcement!(announcement.id)
    end

    test "delete_announcement/1 deletes the announcement" do
      announcement = announcement_fixture()
      assert {:ok, %Announcement{}} = Announcements.delete_announcement(announcement)
      assert_raise Ecto.NoResultsError, fn -> Announcements.get_announcement!(announcement.id) end
    end

    test "change_announcement/1 returns a announcement changeset" do
      announcement = announcement_fixture()
      assert %Ecto.Changeset{} = Announcements.change_announcement(announcement)
    end
  end
end
