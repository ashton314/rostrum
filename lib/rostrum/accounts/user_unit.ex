defmodule Rostrum.Accounts.UserUnit do
  use Ecto.Schema

  schema "users_units" do
    belongs_to :user, Rostrum.Accounts.User
    belongs_to :unit, Rostrum.Accounts.Unit
    timestamps()
  end
end
