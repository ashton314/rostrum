defmodule Rostrum.Meetings.Template do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "templates" do
    field :events, :map
    field :title, :string
    field :welcome_blurb, :string
    belongs_to :unit, Rostrum.Accounts.Unit

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:events, :title, :welcome_blurb])
    |> validate_required([:title, :welcome_blurb])
  end

  @doc """
  Creates a Meeting changeset out of a template
  """
  def to_meeting(template, data) do
    alias Rostrum.Meetings.Meeting

    start =
      template
      |> Map.from_struct()
      |> Map.merge(data)

    Meeting.changeset(%Meeting{}, start)
  end

  ########################################################
  # These functions cloned from Rostrum.Meetings.Meeting #
  ########################################################

  def patch_event(template, event_id, new_event) do
    events = if template.events, do: template.events["events"], else: []

    new_events =
      events
      |> Enum.map(fn
        %{"id" => ^event_id} -> new_event
        e -> e
      end)

    %{events: new_events}
  end

  def swap_event_idxs(template, e_idx1, e_idx2) do
    events = if template.events, do: template.events["events"], else: []

    new_events =
      events
      |> List.replace_at(e_idx1, Enum.at(events, e_idx2))
      |> List.replace_at(e_idx2, Enum.at(events, e_idx1))

    %{events: new_events}
  end

  def delete_event(template, event_id) do
    events = if template.events, do: template.events["events"], else: []

    new_events =
      events
      |> Enum.reject(fn
        %{"id" => ^event_id} -> true
        _ -> false
      end)

    %{events: new_events}
  end

  def move_event_up(template, event_id) do
    case find_event_idx(template, event_id) do
      nil -> %{}
      0 -> %{}
      n -> swap_event_idxs(template, n - 1, n)
    end
  end

  def move_event_down(template, event_id) do
    events = if template.events, do: template.events["events"], else: []
    l = length(events)

    case find_event_idx(template, event_id) do
      nil ->
        %{}

      n ->
        if n + 1 > l, do: %{}, else: swap_event_idxs(template, n, n + 1)
    end
  end

  def find_event_idx(template, event_id) do
    if(template.events, do: template.events["events"], else: [])
    |> Enum.find_index(fn
      %{"id" => ^event_id} -> true
      _ -> false
    end)
  end

  def fetch_event(template, event_id) do
    if(template.events, do: template.events["events"], else: [])
    |> Enum.find(fn
      %{"id" => ^event_id} -> true
      _ -> false
    end)
  end
end
