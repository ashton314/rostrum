defmodule Rostrum.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RostrumWeb.Telemetry,
      Rostrum.Repo,
      {DNSCluster, query: Application.get_env(:rostrum, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Rostrum.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Rostrum.Finch},
      # Start a worker by calling: Rostrum.Worker.start_link(arg)
      # {Rostrum.Worker, arg},
      # Start to serve requests, typically the last entry
      RostrumWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rostrum.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RostrumWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
