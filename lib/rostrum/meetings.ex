defmodule Rostrum.Meetings do
  @moduledoc """
  The Meetings context.
  """

  import Ecto.Query, warn: false
  alias Phoenix.Template
  alias Rostrum.Repo

  alias Rostrum.Meetings.Meeting
  alias Rostrum.Accounts.Unit

  @doc """
  Returns the list of meetings associated with a Unit.

  ## Examples

      iex> list_meetings(%Unit{})
      [%Meeting{}, ...]

  """
  def list_meetings(%Unit{} = unit) do
    (from m in Meeting,
          where: m.unit_id == ^unit.id,
          order_by: [desc: :date])
    |> Repo.all()
  end

  @doc """
  Return {past, active, future} meetings in a tuple.
  """
  def get_partitioned_meetings(%Unit{} = unit) do
    today = Timex.now(unit.timezone)
    all = list_meetings(unit) |> Enum.group_by(&Timex.before?(&1.date, today))

    past = Map.get(all, true, [])
    future_present = Map.get(all, false, []) |> Enum.reverse()

    {current, future} =
      case future_present do
        [c | f] -> {c, f}
        [] -> {nil, []}
      end

    {past, current, future}
  end

  @doc """
  Gets a single meeting.

  Raises `Ecto.NoResultsError` if the Meeting does not exist.

  ## Examples

      iex> get_meeting!(123)
      %Meeting{}

      iex> get_meeting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_meeting!(id, %Unit{} = unit) do
    (from m in Meeting,
          where: m.unit_id == ^unit.id and m.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a meeting.

  ## Examples

      iex> create_meeting(%{field: value})
      {:ok, %Meeting{}}

      iex> create_meeting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_meeting(attrs \\ %{})

  def create_meeting(%Ecto.Changeset{} = cs) do
    cs |> Repo.insert()
  end

  def create_meeting(attrs) do
    %Meeting{}
    |> Meeting.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a meeting.

  ## Examples

      iex> update_meeting(meeting, %{field: new_value})
      {:ok, %Meeting{}}

      iex> update_meeting(meeting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_meeting(%Meeting{} = meeting, attrs) do
    meeting
    |> Meeting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a meeting.

  ## Examples

      iex> delete_meeting(meeting)
      {:ok, %Meeting{}}

      iex> delete_meeting(meeting)
      {:error, %Ecto.Changeset{}}

  """
  def delete_meeting(%Meeting{} = meeting) do
    Repo.delete(meeting)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking meeting changes.

  ## Examples

      iex> change_meeting(meeting)
      %Ecto.Changeset{data: %Meeting{}}

  """
  def change_meeting(%Meeting{} = meeting, attrs \\ %{}) do
    Meeting.changeset(meeting, attrs)
  end

  def clone_skeleton(%Meeting{} = meeting) do
    %{meeting |
      id: nil,
      date: Date.add(meeting.date, 7),
      business: "",
      topic: "",
      events: scrub_events(meeting.events)}
  end

  defp scrub_events(%{"events" => es}), do: %{"events" => Enum.map(es, &scrub_event/1)}
  defp scrub_event(%{"type" => t} = e)
       when t in ["opening-hymn", "closing-hymn", "sacrament-hymn", "rest-hymn", "hymn"],
       do: %{e | "number" => nil, "verses" => nil, "id" => UUID.uuid4()}
  defp scrub_event(%{"type" => t} = e)
       when t in ["speaker", "opening-prayer", "closing-prayer"],
       do: %{e | "name" => nil, "id" => UUID.uuid4()}
  defp scrub_event(e), do: %{e | "id" => UUID.uuid4()}

  alias Rostrum.Meetings.Template

  @doc """
  Returns the list of templates.

  ## Examples

      iex> list_templates()
      [%Template{}, ...]

  """
  def list_templates(%Unit{} = unit) do
    (from t in Template,
          where: t.unit_id == ^unit.id)
    |> Repo.all()
  end

  @doc """
  Gets a single template.

  Raises `Ecto.NoResultsError` if the Template does not exist.

  ## Examples

      iex> get_template!(123)
      %Template{}

      iex> get_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_template!(id, %Unit{} = unit) do
    (from t in Template,
          where: t.unit_id == ^unit.id and t.id == ^id)
    |> Repo.one!()
  end

  @doc """
  Creates a template.

  ## Examples

      iex> create_template(%{field: value})
      {:ok, %Template{}}

      iex> create_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_template(attrs \\ %{}) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template.

  ## Examples

      iex> update_template(template, %{field: new_value})
      {:ok, %Template{}}

      iex> update_template(template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_template(%Template{} = template, attrs) do
    template
    |> Template.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a template.

  ## Examples

      iex> delete_template(template)
      {:ok, %Template{}}

      iex> delete_template(template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_template(%Template{} = template) do
    Repo.delete(template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template changes.

  ## Examples

      iex> change_template(template)
      %Ecto.Changeset{data: %Template{}}

  """
  def change_template(%Template{} = template, attrs \\ %{}) do
    Template.changeset(template, attrs)
  end
end
