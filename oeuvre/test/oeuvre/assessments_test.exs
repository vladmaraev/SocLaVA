defmodule Oeuvre.AssessmentsTest do
  use Oeuvre.DataCase

  alias Oeuvre.Assessments

  describe "assessments" do
    alias Oeuvre.Assessments.Assessment

    import Oeuvre.AssessmentsFixtures

    @invalid_attrs %{
      image: nil,
      q1: nil,
      q2a: nil,
      q2b: nil,
      q2c: nil,
      q2d: nil,
      q2e: nil,
      q2f: nil,
      q3: nil,
      q4: nil,
      q5: nil
    }

    test "list_assessments/0 returns all assessments" do
      assessment = assessment_fixture()
      assert Assessments.list_assessments() == [assessment]
    end

    test "get_assessment!/1 returns the assessment with given id" do
      assessment = assessment_fixture()
      assert Assessments.get_assessment!(assessment.id) == assessment
    end

    test "create_assessment/1 with valid data creates a assessment" do
      valid_attrs = %{
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
      }

      assert {:ok, %Assessment{} = assessment} = Assessments.create_assessment(valid_attrs)
      assert assessment.image == "some image"
      assert assessment.q1 == "some q1"
      assert assessment.q2a == "some q2a"
      assert assessment.q2b == "some q2b"
      assert assessment.q2c == "some q2c"
      assert assessment.q2d == "some q2d"
      assert assessment.q2e == "some q2e"
      assert assessment.q2f == "some q2f"
      assert assessment.q3 == "some q3"
      assert assessment.q4 == "some q4"
      assert assessment.q5 == "some q5"
    end

    test "create_assessment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assessments.create_assessment(@invalid_attrs)
    end

    test "update_assessment/2 with valid data updates the assessment" do
      assessment = assessment_fixture()

      update_attrs = %{
        image: "some updated image",
        q1: "some updated q1",
        q2a: "some updated q2a",
        q2b: "some updated q2b",
        q2c: "some updated q2c",
        q2d: "some updated q2d",
        q2e: "some updated q2e",
        q2f: "some updated q2f",
        q3: "some updated q3",
        q4: "some updated q4",
        q5: "some updated q5"
      }

      assert {:ok, %Assessment{} = assessment} =
               Assessments.update_assessment(assessment, update_attrs)

      assert assessment.image == "some updated image"
      assert assessment.q1 == "some updated q1"
      assert assessment.q2a == "some updated q2a"
      assert assessment.q2b == "some updated q2b"
      assert assessment.q2c == "some updated q2c"
      assert assessment.q2d == "some updated q2d"
      assert assessment.q2e == "some updated q2e"
      assert assessment.q2f == "some updated q2f"
      assert assessment.q3 == "some updated q3"
      assert assessment.q4 == "some updated q4"
      assert assessment.q5 == "some updated q5"
    end

    test "update_assessment/2 with invalid data returns error changeset" do
      assessment = assessment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Assessments.update_assessment(assessment, @invalid_attrs)

      assert assessment == Assessments.get_assessment!(assessment.id)
    end

    test "delete_assessment/1 deletes the assessment" do
      assessment = assessment_fixture()
      assert {:ok, %Assessment{}} = Assessments.delete_assessment(assessment)
      assert_raise Ecto.NoResultsError, fn -> Assessments.get_assessment!(assessment.id) end
    end

    test "change_assessment/1 returns a assessment changeset" do
      assessment = assessment_fixture()
      assert %Ecto.Changeset{} = Assessments.change_assessment(assessment)
    end
  end
end
