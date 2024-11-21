defmodule Oeuvre.Trials do
  @moduledoc """
  The Trials context.
  """

  import Ecto.Query, warn: false
  alias Oeuvre.Repo

  alias Oeuvre.Trials.Trial

  @doc """
  Returns the list of trials.

  ## Examples

      iex> list_trials()
      [%Trial{}, ...]

  """
  def list_trials do
    Repo.all(Trial)
  end

  @doc """
  Gets a single trial.

  Raises `Ecto.NoResultsError` if the Trial does not exist.

  ## Examples

      iex> get_trial!(123)
      %Trial{}

      iex> get_trial!(456)
      ** (Ecto.NoResultsError)

  """
  def get_trial!(id), do: Repo.get!(Trial, id)

  @doc """
  Creates a trial.

  ## Examples

      iex> create_trial(%{field: value})
      {:ok, %Trial{}}

      iex> create_trial(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_trial(attrs \\ %{}) do
    %Trial{}
    |> Trial.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a trial.

  ## Examples

      iex> update_trial(trial, %{field: new_value})
      {:ok, %Trial{}}

      iex> update_trial(trial, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_trial(%Trial{} = trial, attrs) do
    trial
    |> Trial.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a trial.

  ## Examples

      iex> delete_trial(trial)
      {:ok, %Trial{}}

      iex> delete_trial(trial)
      {:error, %Ecto.Changeset{}}

  """
  def delete_trial(%Trial{} = trial) do
    Repo.delete(trial)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking trial changes.

  ## Examples

      iex> change_trial(trial)
      %Ecto.Changeset{data: %Trial{}}

  """
  def change_trial(%Trial{} = trial, attrs \\ %{}) do
    Trial.changeset(trial, attrs)
  end
end
