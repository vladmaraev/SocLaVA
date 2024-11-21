defmodule Oeuvre.Assessments do
  @moduledoc """
  The Assessments context.
  """

  import Ecto.Query, warn: false
  alias Oeuvre.Repo

  alias Oeuvre.Assessments.Assessment

  @doc """
  Returns the list of assessments.

  ## Examples

      iex> list_assessments()
      [%Assessment{}, ...]

  """
  def list_assessments do
    Repo.all(Assessment)
  end

  @doc """
  Gets a single assessment.

  Raises `Ecto.NoResultsError` if the Assessment does not exist.

  ## Examples

      iex> get_assessment!(123)
      %Assessment{}

      iex> get_assessment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assessment!(id), do: Repo.get!(Assessment, id)

  @doc """
  Creates a assessment.

  ## Examples

      iex> create_assessment(%{field: value})
      {:ok, %Assessment{}}

      iex> create_assessment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment(attrs \\ %{}) do
    %Assessment{}
    |> Assessment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a assessment.

  ## Examples

      iex> update_assessment(assessment, %{field: new_value})
      {:ok, %Assessment{}}

      iex> update_assessment(assessment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assessment(%Assessment{} = assessment, attrs) do
    assessment
    |> Assessment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a assessment.

  ## Examples

      iex> delete_assessment(assessment)
      {:ok, %Assessment{}}

      iex> delete_assessment(assessment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assessment(%Assessment{} = assessment) do
    Repo.delete(assessment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assessment changes.

  ## Examples

      iex> change_assessment(assessment)
      %Ecto.Changeset{data: %Assessment{}}

  """
  def change_assessment(%Assessment{} = assessment, attrs \\ %{}) do
    trial = Oeuvre.Trials.get_trial!(attrs["trial"])

    assessment
    |> Repo.preload(:trials)
    |> Assessment.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:trial, trial)
  end
end
