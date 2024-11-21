defmodule Oeuvre.Trials.Trial do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trials" do
    field :recording, :string
    field :trial, :string

    has_many :assessments, Oeuvre.Assessments.Assessment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trial, attrs) do
    trial
    |> cast(attrs, [:trial, :recording])
    |> validate_required([:trial])
  end
end
