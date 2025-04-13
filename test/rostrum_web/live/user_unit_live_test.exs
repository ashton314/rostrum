defmodule RostrumWeb.UserUnitLiveTest do
  use RostrumWeb.ConnCase, async: true

  alias Rostrum.Accounts
  import Phoenix.LiveViewTest
  import Rostrum.AccountsFixtures

  describe "removing user from unit" do
    setup %{conn: conn} do
      {user, unit} = user_unit_fixture()
      Accounts.set_active_unit(user, unit.id)
      unit2 = unit_fixture(%{}, user)
      %{conn: log_in_user(conn, user), user: user, unit: unit, unit2: unit2}
    end

    test "fall back to other available unit", %{conn: conn, unit: unit} do
      {:ok, lv, _html} =
        conn
        |> live(~p"/units/#{unit}/")

      assert lv
      |> element("button", "Remove from unit")
      |> render_click()

      {new_path, flash} = assert_redirect(lv)
      assert new_path == "/units/"
      assert flash["info"] =~ ~r/You removed yourself/
    end

    test "no units left doesn't crash", %{conn: conn, unit: u1, unit2: u2} do
      {:ok, lv, _html} =
        conn
        |> live(~p"/units/#{u1}/")

      assert lv
      |> element("button", "Remove from unit")
      |> render_click()

      {new_path, flash} = assert_redirect(lv)
      assert new_path == "/units/"
      assert flash["info"] =~ ~r/You removed yourself/

      # remove from second unit
      {:ok, lv, _html} =
        conn
        |> live(~p"/units/#{u2}/")

      assert lv
      |> element("button", "Remove from unit")
      |> render_click()

      {new_path, flash} = assert_redirect(lv)
      assert new_path == "/units/"
      assert flash["info"] =~ ~r/You removed yourself/
    end
  end
end
