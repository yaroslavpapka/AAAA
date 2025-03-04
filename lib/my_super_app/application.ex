defmodule MySuperApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    children = [
      MySuperAppWeb.Telemetry,
      MySuperApp.Repo,
      {DNSCluster, query: Application.get_env(:my_super_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MySuperApp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MySuperApp.Finch},
      MySuperApp.WithdrawalRequests,
      MySuperApp.DocumentRequests,
      MySuperApp.ApiFootball,

      # Start a worker by calling: MySuperApp.Worker.start_link(arg)
      # {MySuperApp.Worker, arg},
      # Start to serve requests, typically the last entry
      MySuperAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MySuperApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MySuperAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
