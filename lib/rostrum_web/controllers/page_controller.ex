defmodule RostrumWeb.PageController do
  use RostrumWeb, :controller

  alias Rostrum.Accounts
  alias Rostrum.Announcements
  alias Rostrum.Events

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def privacy(conn, _params), do: render(conn, :privacy)
  def about(conn, _params), do: render(conn, :about)
  def donate(conn, _params), do: render(conn, :donate)

  def meeting_render(conn, %{"unit_slug" => unit_slug} = _params) do
    case Accounts.find_meeting_by_slug(unit_slug) do
      nil ->
        conn
        |> put_layout(html: :meeting)
        |> render(:no_meeting)

      %Rostrum.Meetings.Meeting{} = m ->
        m = m |> Rostrum.Repo.preload([:unit])

        business =
          if conn.assigns.current_user && Accounts.can_see_unit?(conn.assigns.current_user, m.unit_id) do
            m.business
          else
            nil
          end

        conn
        |> assign(:meeting, m)
        |> assign(:business, business)
        |> assign(:announcements, Announcements.get_active_annoucements(m.unit))
        |> assign(:calendar_events, Events.get_active_calendar_events(m.unit))
        |> put_root_layout(html: :meeting_root)
        |> put_layout(html: :meeting)
        |> render(:meeting)
    end
  end

  def qrcode_render(conn, %{"unit_slug" => unit_slug} = params) do
    case Accounts.find_meeting_by_slug(unit_slug) do
      nil ->
        conn
        |> put_layout(html: :meeting)
        |> render(:no_meeting)

      %Rostrum.Meetings.Meeting{} = m ->
        m = m |> Rostrum.Repo.preload([:unit])

        url = "#{conn.scheme}://#{conn.host}/meeting/#{unit_slug}"
        {fmt, content_type} =
          case Map.fetch(params, "fmt") do
            {:ok, "png"} -> {&EQRCode.png(&1, width: 600), "image/png"}
            _ -> {&EQRCode.svg/1, "image/svg+xml"}
          end

        code =
          url
          |> EQRCode.encode()
          |> fmt.()

        conn
        |> assign(:meeting, m)
        |> assign(:slug, url)
        |> assign(:code, code)
        |> put_root_layout(html: false)
        |> put_layout(html: false)
        |> put_resp_content_type(content_type)
        |> render(:qrcode)
    end
  end
end
