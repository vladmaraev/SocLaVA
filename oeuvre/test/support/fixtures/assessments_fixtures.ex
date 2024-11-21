defmodule Oeuvre.AssessmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Oeuvre.Assessments` context.
  """

  @doc """
  Generate a assessment.
  """
  def assessment_fixture(attrs \\ %{}) do
    {:ok, assessment} =
      attrs
      |> Enum.into(%{
        image: "some image",
        q1: "some q1",
        q2a: "some q2a",
        q2b: "some q2b",
        q2c: "some q2c",
        q2d: "some q2d",
        q2e: "some q2e",
        q2f: "some q2f",
        q3: "some q3",
        q4: "some q4",
        q5: "some q5"
      })
      |> Oeuvre.Assessments.create_assessment()

    assessment
  end
end
