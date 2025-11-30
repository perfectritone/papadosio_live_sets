defmodule BandcampScraperWeb.Router do
  use BandcampScraperWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BandcampScraperWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug BandcampScraperWeb.Plugs.Auth, :fetch_current_user
  end

  pipeline :require_authenticated do
    plug BandcampScraperWeb.Plugs.Auth, :require_authenticated_user
  end

  pipeline :require_admin do
    plug BandcampScraperWeb.Plugs.Auth, :require_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes
  scope "/", BandcampScraperWeb do
    pipe_through :browser

    get "/", SetController, :index
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
    get "/signup", RegistrationController, :new
    post "/signup", RegistrationController, :create

    # Read-only resources
    resources "/sets", SetController, only: [:index, :show]
    live "/songs", SongsLive, :index
    resources "/songs", SongController, only: [:show]
    resources "/set_songs", SetSongController, only: [:index, :show]
    resources "/variants", VariantController, only: [:index, :show]
  end

  # Authenticated user routes (can add/remove variants, edit songs)
  scope "/", BandcampScraperWeb do
    pipe_through [:browser, :require_authenticated]

    post "/set_songs/:id/add_variant", SetSongController, :add_variant
    post "/set_songs/:id/add_new_variant", SetSongController, :add_new_variant
    delete "/set_songs/:id/remove_variant/:variant_id", SetSongController, :remove_variant

    # Song editing and merging
    resources "/songs", SongController, only: [:edit, :update]
    post "/songs/:id/merge", SongController, :merge
  end

  # Admin-only routes
  scope "/", BandcampScraperWeb do
    pipe_through [:browser, :require_admin]

    resources "/sets", SetController, only: [:new, :create, :edit, :update, :delete]
    resources "/songs", SongController, only: [:new, :create, :delete]
    resources "/set_songs", SetSongController, only: [:new, :create, :edit, :update, :delete]
  end

  # Other scopes may use custom stacks.
  # scope "/api", BandcampScraperWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bandcamp_scraper, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BandcampScraperWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
