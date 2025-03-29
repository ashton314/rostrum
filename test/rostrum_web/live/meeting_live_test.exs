defmodule RostrumWeb.MeetingLiveTest do
  use RostrumWeb.ConnCase

  import Phoenix.LiveViewTest
  import Rostrum.MeetingsFixtures
  import Rostrum.AccountsFixtures

  @create_attrs %{date: "2024-12-21", metadata: %{}}
  @invalid_attrs %{date: nil}

  defp create_meeting(_) do
    {user, unit} = user_unit_fixture()
    meeting = meeting_fixture(unit)
    %{meeting: meeting, user: user, unit: unit}
  end

  describe "Index" do
    setup [:create_meeting, :setup_login]

    test "lists all meetings", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/meetings")

      assert html =~ "Listing Meetings"
    end

    test "saves new meeting", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")

      assert index_live |> element("a", "New Blank Meeting") |> render_click() =~
               "New Meeting"

      assert_patch(index_live, ~p"/meetings/new")

      assert index_live
             |> form("#meeting-form", meeting: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#meeting-form", meeting: @create_attrs)
             |> render_submit()

      {new_path, flash} = assert_redirect(index_live)
      assert new_path =~ ~r/meetings\/[0-9]+/
      assert flash["info"] =~ "Meeting created successfully"
    end

    # test "updates meeting in listing", %{conn: conn, meeting: meeting} do
    #   {:ok, index_live, _html} = live(conn, ~p"/meetings")

    #   assert index_live |> element("#meetings-#{meeting.id} a", "Edit") |> render_click() =~
    #            "Edit Meeting"

    #   assert_patch(index_live, ~p"/meetings/#{meeting}/edit")

    #   assert index_live
    #          |> form("#meeting-form", meeting: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   assert index_live
    #          |> form("#meeting-form", meeting: @update_attrs)
    #          |> render_submit()

    #   assert_patch(index_live, ~p"/meetings")

    #   html = render(index_live)
    #   assert html =~ "Meeting updated successfully"
    # end

    test "deletes meeting in listing", %{conn: conn, meeting: meeting} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")

      assert index_live |> element("#past-#{meeting.id} a", "Delete") |> render_click()
      {:ok, index_live, _html} = live(conn, ~p"/meetings") # reload page? shouldn't have to...
      refute has_element?(index_live, "#past-#{meeting.id}")
    end
  end

  describe "Show and edit" do
    setup [:create_meeting, :setup_login]

    test "displays meeting", %{conn: conn, meeting: meeting} do
      {:ok, _show_live, html} = live(conn, ~p"/meetings/#{meeting}")

      assert html =~ "Show Meeting"
    end

    test "can add every kind of event to list"

    # test "displays meeting", %{conn: conn, meeting: meeting} do
    #   {:ok, _show_live, html} = live(conn, ~p"/meetings/#{meeting}")

    #   assert html =~ "Show Meeting"
    # end

    # test "updates meeting within modal", %{conn: conn, meeting: meeting} do
    #   {:ok, show_live, _html} = live(conn, ~p"/meetings/#{meeting}")

    #   assert show_live |> element("a", "Edit") |> render_click() =~
    #            "Edit Meeting"

    #   assert_patch(show_live, ~p"/meetings/#{meeting}/show/edit")

    #   assert show_live
    #          |> form("#meeting-form", meeting: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   assert show_live
    #          |> form("#meeting-form", meeting: @update_attrs)
    #          |> render_submit()

    #   assert_patch(show_live, ~p"/meetings/#{meeting}")

    #   html = render(show_live)
    #   assert html =~ "Meeting updated successfully"
    # end
  end
end
