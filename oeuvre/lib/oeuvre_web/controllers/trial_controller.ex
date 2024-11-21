defmodule OeuvreWeb.TrialController do
  use OeuvreWeb, :controller

  alias Oeuvre.Trials
  alias Oeuvre.Trials.Trial

  def new(conn, _params) do
    changeset = Trials.change_trial(%Trial{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"trial" => trial_params}) do
    case Trials.create_trial(trial_params) do
      {:ok, trial} ->
        conn
        |> put_flash(:info, "Trial started successfully.")
        |> redirect(to: ~p"/a/new?#{trial_params}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    trial = Trials.get_trial!(id)
    render(conn, :show, trial: trial)
  end
end
