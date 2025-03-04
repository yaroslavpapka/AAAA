# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :my_super_app,
  ecto_repos: [MySuperApp.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :my_super_app, MySuperAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MySuperAppWeb.ErrorHTML, json: MySuperAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MySuperApp.PubSub,
  live_view: [signing_salt: "nVMd5wKt"]

moon_config_path = "#{File.cwd!()}/deps/moon/config/surface.exs"

if File.exists?("#{moon_config_path}") do
  import_config(moon_config_path)
end

config :surface, :components, [
  # put here your app configs for surface
]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :my_super_app, MySuperApp.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.16.4",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  my_super_app: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import Config

config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID") || "default_access_key",
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY") || "default_secret_key",
  region: System.get_env("AWS_REGION") || "us-west-2"

config :ex_aws, :s3,
  region: System.get_env("AWS_REGION") || "us-west-2",
  host: System.get_env("AWS_S3_HOST") || "default_host"

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  my_super_app: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, []}
  ]

config :my_super_app, :aws,
  bucket: System.get_env("S3_BUCKET")
  s3_region: System.get_env("S3_REGION")
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID")
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY")

config :exw3,
  url: "http://127.0.0.1:7545",
  gas_limit: "6721975",
  gas_price: "20000000000"
