defmodule RostrumWeb.CalendarEventLiveTest do
  use RostrumWeb.ConnCase

  import Phoenix.LiveViewTest
  import Rostrum.EventsFixtures

  @create_attrs %{description: "some description", title: "some title", start_display: "2024-12-21", event_date: "2024-12-21T00:17", time_description: "some time_description"}
  @update_attrs %{description: "some updated description", title: "some updated title", start_display: "2024-12-22", event_date: "2024-12-22T00:17", time_description: "some updated time_description"}
  @invalid_attrs %{description: nil, title: nil, start_display: nil, event_date: nil, time_description: nil}

  defp create_calendar_event(_) do
    {calendar_event, unit, user} = calendar_event_fixture()
    %{calendar_event: calendar_event, user: user, unit: unit}
  end

  describe "Index" do
    setup [:create_calendar_event, :setup_login]

    test "lists all calendar_events", %{conn: conn, calendar_event: calendar_event} do
      {:ok, _index_live, html} = live(conn, ~p"/calendar_events")

      assert html =~ "Listing Calendar events"
      assert html =~ calendar_event.description
    end

    test "saves new calendar_event", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/calendar_events")

      assert index_live |> element("a", "New Calendar event") |> render_click() =~
               "New Calendar event"

      assert_patch(index_live, ~p"/calendar_events/new")

      assert index_live
             |> form("#calendar_event-form", calendar_event: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#calendar_event-form", calendar_event: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/calendar_events")

      html = render(index_live)
      assert html =~ "Calendar event created successfully"
      assert html =~ "some description"
    end

    test "updates calendar_event in listing", %{conn: conn, calendar_event: calendar_event} do
      {:ok, index_live, _html} = live(conn, ~p"/calendar_events")

      assert index_live |> element("#calendar_events-#{calendar_event.id} a", "Edit") |> render_click() =~
               "Edit Calendar event"

      assert_patch(index_live, ~p"/calendar_events/#{calendar_event}/edit")

      assert index_live
             |> form("#calendar_event-form", calendar_event: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#calendar_event-form", calendar_event: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/calendar_events")

      html = render(index_live)
      assert html =~ "Calendar event updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes calendar_event in listing", %{conn: conn, calendar_event: calendar_event} do
      {:ok, index_live, _html} = live(conn, ~p"/calendar_events")

      assert index_live |> element("#calendar_events-#{calendar_event.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#calendar_events-#{calendar_event.id}")
    end
  end

  describe "Show" do
    setup [:create_calendar_event, :setup_login]

    test "displays calendar_event", %{conn: conn, calendar_event: calendar_event} do
      {:ok, _show_live, html} = live(conn, ~p"/calendar_events/#{calendar_event}")

      assert html =~ "Show Calendar event"
      assert html =~ calendar_event.description
    end

    test "updates calendar_event within modal", %{conn: conn, calendar_event: calendar_event} do
      {:ok, show_live, _html} = live(conn, ~p"/calendar_events/#{calendar_event}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Calendar event"

      assert_patch(show_live, ~p"/calendar_events/#{calendar_event}/show/edit")

      assert show_live
             |> form("#calendar_event-form", calendar_event: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#calendar_event-form", calendar_event: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/calendar_events/#{calendar_event}")

      html = render(show_live)
      assert html =~ "Calendar event updated successfully"
      assert html =~ "some updated description"
    end
  end
end
