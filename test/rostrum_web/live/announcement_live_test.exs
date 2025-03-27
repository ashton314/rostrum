defmodule RostrumWeb.AnnouncementLiveTest do
  use RostrumWeb.ConnCase

  import Phoenix.LiveViewTest
  import Rostrum.AnnouncementsFixtures

  @create_attrs %{description: "some description", title: "some title", start_display: "2024-12-21", end_display: "2024-12-21"}
  @update_attrs %{description: "some updated description", title: "some updated title", start_display: "2024-12-22", end_display: "2024-12-22"}
  @invalid_attrs %{description: nil, title: nil, start_display: nil, end_display: nil}

  defp create_announcement(_) do
    {announcement, unit, user} = announcement_fixture()
    %{announcement: announcement, user: user, unit: unit}
  end

  describe "Index" do
    setup [:create_announcement, :setup_login]

    test "lists all announcements", %{conn: conn, announcement: announcement} do
      {:ok, _index_live, html} = live(conn, ~p"/announcements")

      assert html =~ "Listing Announcements"
      assert html =~ announcement.description
    end

    test "saves new announcement", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/announcements")

      assert index_live |> element("a", "New Announcement") |> render_click() =~
               "New Announcement"

      assert_patch(index_live, ~p"/announcements/new")

      assert index_live
             |> form("#announcement-form", announcement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#announcement-form", announcement: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/announcements")

      html = render(index_live)
      assert html =~ "Announcement created successfully"
      assert html =~ "some description"
    end

    test "updates announcement in listing", %{conn: conn, announcement: announcement} do
      {:ok, index_live, _html} = live(conn, ~p"/announcements")

      assert index_live |> element("#announcements-#{announcement.id} a", "Edit") |> render_click() =~
               "Edit Announcement"

      assert_patch(index_live, ~p"/announcements/#{announcement}/edit")

      assert index_live
             |> form("#announcement-form", announcement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#announcement-form", announcement: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/announcements")

      html = render(index_live)
      assert html =~ "Announcement updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes announcement in listing", %{conn: conn, announcement: announcement} do
      {:ok, index_live, _html} = live(conn, ~p"/announcements")

      assert index_live |> element("#announcements-#{announcement.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#announcements-#{announcement.id}")
    end
  end

  describe "Show" do
    setup [:create_announcement, :setup_login]

    test "displays announcement", %{conn: conn, announcement: announcement} do
      {:ok, _show_live, html} = live(conn, ~p"/announcements/#{announcement}")

      assert html =~ "Show Announcement"
      assert html =~ announcement.description
    end

    test "updates announcement within modal", %{conn: conn, announcement: announcement} do
      {:ok, show_live, _html} = live(conn, ~p"/announcements/#{announcement}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Announcement"

      assert_patch(show_live, ~p"/announcements/#{announcement}/show/edit")

      assert show_live
             |> form("#announcement-form", announcement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#announcement-form", announcement: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/announcements/#{announcement}")

      html = render(show_live)
      assert html =~ "Announcement updated successfully"
      assert html =~ "some updated description"
    end
  end
end
