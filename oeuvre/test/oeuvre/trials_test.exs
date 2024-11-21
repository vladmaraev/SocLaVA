defmodule Oeuvre.TrialsTest do
  use Oeuvre.DataCase

  alias Oeuvre.Trials

  describe "trials" do
    alias Oeuvre.Trials.Trial

    import Oeuvre.TrialsFixtures

    @invalid_attrs %{recording: nil, trial: nil}

    test "list_trials/0 returns all trials" do
      trial = trial_fixture()
      assert Trials.list_trials() == [trial]
    end

    test "get_trial!/1 returns the trial with given id" do
      trial = trial_fixture()
      assert Trials.get_trial!(trial.id) == trial
    end

    test "create_trial/1 with valid data creates a trial" do
      valid_attrs = %{recording: "some recording", trial: "some trial"}

      assert {:ok, %Trial{} = trial} = Trials.create_trial(valid_attrs)
      assert trial.recording == "some recording"
      assert trial.trial == "some trial"
    end

    test "create_trial/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Trials.create_trial(@invalid_attrs)
    end

    test "update_trial/2 with valid data updates the trial" do
      trial = trial_fixture()
      update_attrs = %{recording: "some updated recording", trial: "some updated trial"}

      assert {:ok, %Trial{} = trial} = Trials.update_trial(trial, update_attrs)
      assert trial.recording == "some updated recording"
      assert trial.trial == "some updated trial"
    end

    test "update_trial/2 with invalid data returns error changeset" do
      trial = trial_fixture()
      assert {:error, %Ecto.Changeset{}} = Trials.update_trial(trial, @invalid_attrs)
      assert trial == Trials.get_trial!(trial.id)
    end

    test "delete_trial/1 deletes the trial" do
      trial = trial_fixture()
      assert {:ok, %Trial{}} = Trials.delete_trial(trial)
      assert_raise Ecto.NoResultsError, fn -> Trials.get_trial!(trial.id) end
    end

    test "change_trial/1 returns a trial changeset" do
      trial = trial_fixture()
      assert %Ecto.Changeset{} = Trials.change_trial(trial)
    end
  end
end
