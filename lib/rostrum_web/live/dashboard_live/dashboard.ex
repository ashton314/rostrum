defmodule RostrumWeb.DashboardLive.Dashboard do
  use RostrumWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
