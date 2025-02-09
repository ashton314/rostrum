defmodule Rostrum.Meetings.Template do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "templates" do
    field :events, :map
    field :title, :string
    field :welcome_blurb, :string
    field :unit_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:events, :title, :welcome_blurb])
    |> validate_required([:title, :welcome_blurb])
  end
end
