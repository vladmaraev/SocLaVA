defmodule Oeuvre.TrialsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Oeuvre.Trials` context.
  """

  @doc """
  Generate a trial.
  """
  def trial_fixture(attrs \\ %{}) do
    {:ok, trial} =
      attrs
      |> Enum.into(%{
        recording: "some recording",
        trial: "some trial"
      })
      |> Oeuvre.Trials.create_trial()

    trial
  end
end
