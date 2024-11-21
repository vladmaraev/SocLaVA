defmodule Oeuvre.Assessments.Assessment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assessments" do
    field :image, :string
    field :q1, :string
    field :q2a, :string
    field :q2b, :string
    field :q2c, :string
    field :q2d, :string
    field :q2e, :string
    field :q2f, :string
    field :q3, :string
    field :q4, :string
    field :q5, :string

    belongs_to :trial, Oeuvre.Trials.Trial

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(assessment, attrs) do
    assessment
    |> cast(attrs, [:image, :q1, :q2a, :q2b, :q2c, :q2d, :q2e, :q2f, :q3, :q4, :q5])
    |> validate_required([:image, :q1, :q2a, :q2b, :q2c, :q2d, :q2e, :q2f, :q3, :q4, :q5])
  end
end
