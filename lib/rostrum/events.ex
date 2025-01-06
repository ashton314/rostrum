defmodule Rostrum.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias Rostrum.Repo

  alias Rostrum.Events.CalendarEvent
  alias Rostrum.Accounts.Unit

  @doc """
  Returns the list of calendar_events.

  ## Examples

      iex> list_calendar_events()
      [%CalendarEvent{}, ...]

  """
  def list_calendar_events(%Unit{} = unit) do
    (from c in CalendarEvent,
          where: c.unit_id == ^unit.id)
    |> Repo.all()
  end

  def get_active_calendar_events(%Unit{} = unit) do
    today = Timex.now("America/Denver")
    (from a in CalendarEvent,
         where: a.unit_id == ^unit.id and a.start_display <= ^today and (a.event_date >= ^today))
    |> Repo.all()
  end

  @doc """
  Gets a single calendar_event.

  Raises `Ecto.NoResultsError` if the Calendar event does not exist.

  ## Examples

      iex> get_calendar_event!(123)
      %CalendarEvent{}

      iex> get_calendar_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_calendar_event!(id, %Unit{} = unit) do
    (from a in CalendarEvent,
          where: a.unit_id == ^unit.id and a.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a calendar_event.

  ## Examples

      iex> create_calendar_event(%{field: value})
      {:ok, %CalendarEvent{}}

      iex> create_calendar_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_calendar_event(attrs \\ %{}) do
    %CalendarEvent{}
    |> CalendarEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a calendar_event.

  ## Examples

      iex> update_calendar_event(calendar_event, %{field: new_value})
      {:ok, %CalendarEvent{}}

      iex> update_calendar_event(calendar_event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_calendar_event(%CalendarEvent{} = calendar_event, attrs) do
    calendar_event
    |> CalendarEvent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a calendar_event.

  ## Examples

      iex> delete_calendar_event(calendar_event)
      {:ok, %CalendarEvent{}}

      iex> delete_calendar_event(calendar_event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_calendar_event(%CalendarEvent{} = calendar_event) do
    Repo.delete(calendar_event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking calendar_event changes.

  ## Examples

      iex> change_calendar_event(calendar_event)
      %Ecto.Changeset{data: %CalendarEvent{}}

  """
  def change_calendar_event(%CalendarEvent{} = calendar_event, attrs \\ %{}) do
    CalendarEvent.changeset(calendar_event, attrs)
  end
end
