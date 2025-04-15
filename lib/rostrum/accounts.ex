defmodule Rostrum.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Rostrum.Meetings
  alias Rostrum.Repo

  alias Rostrum.Accounts.{User, UserToken, UserNotifier, Unit, UserUnit}
  alias Rostrum.Meetings.Meeting

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  alias Rostrum.Accounts.Unit

  @doc """
  Returns the list of units.

  ## Examples

      iex> list_units()
      [%Unit{}, ...]

  """
  def list_units(%User{} = user) do
    user
    |> Repo.preload(:units)
    |> Map.get(:units)
  end

  def set_active_unit(%User{} = user, unit_id) do
    if can_see_unit?(user, unit_id) do
      user
      |> User.active_unit_changeset(%{"active_unit_id" => unit_id})
      |> Repo.update()
    else
      {:error, "No unit with that ID found"}
    end
  end

  def get_active_unit!(%User{} = user) do
    # the "can_see_unit?" bit is in case we're logged in and we get booted from a unit
    if user.active_unit_id && can_see_unit?(user, user.active_unit_id) do
      get_unit!(user.active_unit_id, user)
    else
      user
      |> Repo.preload([:units])
      |> Map.get(:units)
      |> case do
        [] -> nil
        [hd | _] -> hd
      end
    end
  end

  @doc """
  Gets a single unit.

  Raises `Ecto.NoResultsError` if the Unit does not exist.

  ## Examples

      iex> get_unit!(123)
      %Unit{}

      iex> get_unit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_unit!(id, %User{} = user) do
    assert_user_access_unit!(user, id)
    Repo.get!(Unit, id)
  end

  def get_unit_by_slug(slug) do
    from(u in Unit, where: u.slug == ^slug)
    |> Repo.one()
  end

  def can_see_unit?(%User{} = user, unit_id) do
    user
    |> Repo.preload(:units)
    |> Map.get(:units)
    |> Enum.any?(fn %Unit{id: id} -> to_string(id) == to_string(unit_id) end)
  end

  def assert_user_access_unit!(%User{} = user, unit_id) do
    if can_see_unit?(user, unit_id) do
      :ok
    else
      raise Ecto.NoResultsError, queryable: Unit
    end
  end

  def user_permission(_, nil), do: false

  def user_permission(%User{id: user_id}, %Unit{id: unit_id}) do
    perms =
      from(uu in UserUnit,
        where: uu.user_id == ^user_id and uu.unit_id == ^unit_id
      )
      |> Repo.one()

    perms && perms.role
  end

  def user_permission(%User{} = user, unit_slug) when is_binary(unit_slug) do
    user_permission(user, get_unit_by_slug(unit_slug))
  end

  def authorized?(_, nil, _), do: false

  def authorized?(%User{} = user, %Unit{} = unit, access_level) do
    permission = user_permission(user, unit)

    case {permission, access_level} do
      {nil, _} -> false
      {:music, :music} -> true
      {:music, _} -> false
      {:editor, :music} -> true
      {:editor, :editor} -> true
      {:editor, :owner} -> false
      {:owner, _} -> true
    end
  end

  def authorized?(%User{} = user, unit_slug, access_level) when is_binary(unit_slug) do
    authorized?(user, get_unit_by_slug(unit_slug), access_level)
  end

  @doc """
  Set authorization level for a user, assuming the user already has
  access to the unit. This is a "safer" version of
  `set_authorization_level!`, which does no checks.
  """
  @spec set_authorization_level(User.t(), Unit.t(), String.t() | :music | :editor | :owner, User.t()) :: :ok | {:error, atom()}
  def set_authorization_level(%User{} = user, %Unit{} = unit, level, %User{} = setter) do
    level =
      if is_atom(level) do
        level
      else
        case level do
          "music" -> :music
          "editor" -> :editor
          "owner" -> :owner
          _ -> nil
        end
      end

    if Enum.member?([:owner, :editor, :music], level) do
      if authorized?(setter, unit, level) do
        if can_see_unit?(user, unit.id) do
          set_authorization_level!(user, unit, level)
          :ok
        else
          {:error, :user_not_in_unit}
        end
      else
        {:error, :insufficient_permissions}
      end
    else
      {:error, :illegal_authorization_level}
    end
  end

  def set_authorization_level!(%User{} = user, %Unit{} = unit, level) do
    Repo.transaction(fn ->
      remove_user_from_unit(unit, user)
      add_user_to_unit(user.id, unit.id, level)
    end)
  end

  @doc """
  Creates a unit.

  ## Examples

      iex> create_unit(%{field: value})
      {:ok, %Unit{}}

      iex> create_unit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_unit(attrs \\ %{}) do
    %Unit{}
    |> Unit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a unit.

  ## Examples

      iex> update_unit(unit, %{field: new_value})
      {:ok, %Unit{}}

      iex> update_unit(unit, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_unit(%Unit{} = unit, %User{} = user, attrs) do
    assert_user_access_unit!(user, unit.id)

    unit
    |> Unit.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a unit.

  ## Examples

      iex> delete_unit(unit)
      {:ok, %Unit{}}

      iex> delete_unit(unit)
      {:error, %Ecto.Changeset{}}

  """
  def delete_unit(%Unit{} = unit, %User{} = user) do
    assert_user_access_unit!(user, unit.id)
    Repo.delete(unit)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking unit changes.

  ## Examples

      iex> change_unit(unit)
      %Ecto.Changeset{data: %Unit{}}

  """
  def change_unit(%Unit{} = unit, attrs \\ %{}) do
    Unit.changeset(unit, attrs)
  end

  # Users and Units
  def get_units_for_user(user_id) do
    User
    |> Repo.get(user_id)
    |> Repo.preload(:units)
    |> Map.get(:units)
  end

  def load_units(%User{} = user) do
    user |> Repo.preload(:units)
  end

  def get_users_for_unit(unit_id) do
    Unit
    |> Repo.get(unit_id)
    |> Repo.preload(:users)
    |> Map.get(:users)
  end

  def load_users(%Unit{} = unit) do
    unit |> Repo.preload(:users)
  end

  def add_user_to_unit(user_id, unit_id, role \\ :editor) do
    user = Repo.get(User, user_id)
    unit = Repo.get(Unit, unit_id)

    Repo.insert(%UserUnit{user_id: user.id, unit_id: unit.id, role: role})
  end

  def add_user_to_unit_by_email(%Unit{} = unit, user_email) do
    with %User{id: user_id} <- get_user_by_email(user_email) do
      add_user_to_unit(user_id, unit.id)
    end
  end

  def remove_user_from_unit(%Unit{} = unit, %User{} = user) do
    from(a in UserUnit,
      where: a.user_id == ^user.id and a.unit_id == ^unit.id
    )
    |> Repo.delete_all()

    User.active_unit_changeset(user, %{active_unit_id: nil})
    |> Repo.update!()
  end

  def get_active_meeting(%Unit{} = unit) do
    {past, active, future} = Meetings.get_partitioned_meetings(unit)

    case {past, active, future} do
      {_, %Meeting{} = a, _} -> a
      {_, nil, [a | _]} -> a
      {[a | _], nil, []} -> a
    end
  end

  def find_meeting_by_slug(slug) do
    with %Unit{} = unit <- get_unit_by_slug(slug) do
      get_active_meeting(unit)
    end
  end
end
