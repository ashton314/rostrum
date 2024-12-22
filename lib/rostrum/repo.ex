defmodule Rostrum.Repo do
  use Ecto.Repo,
    otp_app: :rostrum,
    adapter: Ecto.Adapters.Postgres
end
