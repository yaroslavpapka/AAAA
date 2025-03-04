defmodule MySuperAppWeb.Router do
  use MySuperAppWeb, :router
  import MySuperAppWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MySuperAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :put_root_layout, html: {MySuperAppWeb.LayoutsAdmin, :admin}
  end

  scope "/", MySuperAppWeb do
    pipe_through [:browser]

    get "/hello/:message", HelloController, :index
    live("/multi-form", Form1Live)
    live("/", HomeLive)
    live("/menu", MenuPage)
    live("/tabs", TabsPage)
    live("/accordion", AccordPage)
    live("/form", Form)
    live("/formlive", FormLive)
    live("/users", UsersPage)
    live("/users/edit/:id", EditUser)
    live("/operators", OperatorsPage)
    live("/deposit", DepositLive)
    live("/blackjack", BlackJackLive)
    live("/roulette", RouletteLive)
    live("/cryptos", CryptoLive)
    live("/betting", MatchSelectionLive)
    live("/betting_history", BettingHistoryLive)
    live "/withdrawals", WithdrawalLive
    live "/bets", BetLive
    live "/currencies", PopularCurrenciesLive, :index
    live "/currencies/:symbol", CurrencyShowLive, :show
    live "/upload", DocumentUploadLive
    live "/review", AdminDocumentReviewLive
    live "/fantasy-football", FantasyLive
    live("/withdrawal_requests", WithdrawalRequestsLive)
    live "/auth", AuthLive
    live "/transactions", TransactionLive


    get "/auth/:provider", AuthController, :redirect_to_google
    get "/auth/:provider/callback", AuthController, :callback

    live_session :require_authenticated_user,
      on_mount: [{MySuperAppWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/admin", MySuperAppWeb do
    pipe_through [:browser, :admin, :require_authenticated_superadmin]
    live("/operators", OperatorsPage)
    live("/users", PageAdmin)
  end

  scope "/admin", MySuperAppWeb do
    pipe_through [:browser, :admin, :require_authenticated_operator]
    live("/site-configs", SitesPage)
    live("/roles", RolesPage)
  end

  scope "/admin", MySuperAppWeb do
    pipe_through [:browser, :admin, :require_authenticated_admin]

    get "/hello/:message", HelloController, :index
    live("/", HomeLive)
    live("/menu", MenuPage)
    live("/tabs", TabsPage)
    live("/accordion", AccordPage)
    live("/form", Form)
    live("/formlive", FormLive)
    live("/users/edit/:id", EditUser)
    live("/policy", GlobalPolicy)
    live("/account-managers", PhotosLive)
    live("/invited-users", InviteUserAdmin)
    live("/posts", PostAdmin)
    live("/tags", TagsLive)
    live "/pictures", PictureLive
  end

  # Other scopes may use custom stacks.
  scope "/api", MySuperAppWeb do
    pipe_through :api

    resources "/posts", PostController, except: [:new, :edit]

    get "/pictures", PictureController, :index
    post "/posts/:post_id/picture", PostController, :create
    put "/pictures", PictureController, :update
    post "/pictures/", PictureController, :create

    get "/posts/date/:date", PostController, :index_by_date
    get "/posts/period/:start_date/:end_date", PostController, :index_by_period
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:my_super_app, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MySuperAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MySuperAppWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MySuperAppWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", MySuperAppWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{MySuperAppWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
