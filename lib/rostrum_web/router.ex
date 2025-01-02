defmodule RostrumWeb.Router do
  use RostrumWeb, :router

  import RostrumWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RostrumWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RostrumWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", RostrumWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:rostrum, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RostrumWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", RostrumWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{RostrumWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", RostrumWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{RostrumWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", RostrumWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{RostrumWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  scope "/", RostrumWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/units", UnitLive.Index, :index
    live "/units/new", UnitLive.Index, :new
    live "/units/:id/edit", UnitLive.Index, :edit
    live "/units/:id", UnitLive.Show, :show
    live "/units/:id/show/edit", UnitLive.Show, :edit
  end

  scope "/", RostrumWeb do
    pipe_through [:browser, :require_authenticated_user, :require_unit_user]

    live "/meetings", MeetingLive.Index, :index
    live "/meetings/new", MeetingLive.Index, :new
    live "/meetings/:id/edit", MeetingLive.Index, :edit
    live "/meetings/:id", MeetingLive.Show, :show
    live "/meetings/:id/show/edit", MeetingLive.Show, :edit
    live "/meetings/:id/show/event/new", MeetingLive.Show, :new_event
    live "/meetings/:id/show/event/new/after/:after_event_id", MeetingLive.Show, :new_event
    live "/meetings/:id/show/event/:event_id", MeetingLive.Show, :edit_event

    live "/calendar_events", CalendarEventLive.Index, :index
    live "/calendar_events/new", CalendarEventLive.Index, :new
    live "/calendar_events/:id/edit", CalendarEventLive.Index, :edit
    live "/calendar_events/:id", CalendarEventLive.Show, :show
    live "/calendar_events/:id/show/edit", CalendarEventLive.Show, :edit

    live "/announcements", AnnouncementLive.Index, :index
    live "/announcements/new", AnnouncementLive.Index, :new
    live "/announcements/:id/edit", AnnouncementLive.Index, :edit
    live "/announcements/:id", AnnouncementLive.Show, :show
    live "/announcements/:id/show/edit", AnnouncementLive.Show, :edit
  end
end
