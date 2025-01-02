defmodule RostrumWeb.PageController do
  use RostrumWeb, :controller

  alias Rostrum.Accounts

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def meeting_render(conn, %{"unit_slug" => unit_slug} = _params) do
    case Accounts.find_meeting_by_slug(unit_slug) do
      nil ->
        conn
        |> put_layout(html: :meeting)
        |> render(:no_meeting)

      %Rostrum.Meetings.Meeting{} = m ->
        m = m |> Rostrum.Repo.preload([:unit])
        conn
        |> assign(:meeting, dbg(m))
        |> put_root_layout(html: :meeting_root)
        |> put_layout(html: :meeting)
        |> render(:meeting)
    end
  end
end
