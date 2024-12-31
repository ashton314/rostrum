defmodule Rostrum.Meetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meetings" do
    field :date, :date
    field :events, :map
    field :metadata, :map
    field :unit_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [:date, :metadata, :events])
    |> validate_required([:date])
  end

  def patch_event(meeting, event_id, new_event) do
    events = if meeting.events, do: meeting.events["events"], else: []

    new_events =
      events
      |> Enum.map(fn
        %{"id" => ^event_id} -> new_event
        e -> e
      end)

    %{events: new_events}
  end

  def swap_event_idxs(meeting, e_idx1, e_idx2) do
    events = if meeting.events, do: meeting.events["events"], else: []

    new_events =
      events
      |> List.replace_at(e_idx1, Enum.at(events, e_idx2))
      |> List.replace_at(e_idx2, Enum.at(events, e_idx1))

    %{events: new_events}
  end

  def delete_event(meeting, event_id) do
    events = if meeting.events, do: meeting.events["events"], else: []

    new_events =
      events
      |> Enum.reject(fn %{"id" => ^event_id} -> true
                        _ -> false end)

    %{events: new_events}
  end

  def move_event_up(meeting, event_id) do
    case find_event_idx(meeting, event_id) do
      nil -> %{}
      0 -> %{}
      n -> swap_event_idxs(meeting, n - 1, n)
    end
  end

  def move_event_down(meeting, event_id) do
    events = if meeting.events, do: meeting.events["events"], else: []
    l = length(events)

    case find_event_idx(meeting, event_id) do
      nil ->
        %{}

      n ->
        if n + 1 > l, do: %{}, else: swap_event_idxs(meeting, n, n + 1)
    end
  end

  def find_event_idx(meeting, event_id) do
    if(meeting.events, do: meeting.events["events"], else: [])
    |> Enum.find_index(fn
      %{"id" => ^event_id} -> true
      _ -> false
    end)
  end

  def fetch_event(meeting, event_id) do
    if(meeting.events, do: meeting.events["events"], else: [])
    |> Enum.find(fn
      %{"id" => ^event_id} -> true
      _ -> false
    end)
  end
end
