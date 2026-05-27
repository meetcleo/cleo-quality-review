# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/checks/quality_check"
require "cleo_quality_review/run_artifacts"

module CleoQualityReview
  class RunArtifactsTest < Minitest::Test
    def test_uses_review_id_directory_and_writes_changes_diff
      in_tmpdir do
        artifacts = RunArtifacts.new(
          review_id: "review-id",
          timestamp: 123,
          target_files: [],
          changes_diff: "diff content",
        ).prepare!

        artifacts_path = artifacts.to_s
        assert_equal "tmp/quality_checks/review-id", artifacts_path
        assert_path_exists File.join(artifacts_path, "changes.diff")
        assert_equal "diff content", artifacts.changes_diff
      end
    end

    def test_reconstructs_run_from_completed_artifacts
      in_tmpdir do
        assert_reconstructed_run(load_completed_run)
      end
    end

    def test_reconstructs_legacy_manifest_without_base_ref
      in_tmpdir do
        artifacts = prepared_artifacts
        write_legacy_manifest_without_base_ref(artifacts)

        run = RunArtifacts.load(review_id: "review-id").to_run(format: "github")

        assert_equal "origin/main", run.base_ref
      end
    end

    def test_result_serializes_tool_name_and_tool_type
      result = Result.new(
        tool_name: "reek",
        tool_type: "smell_detection",
        check: "DuplicateMethodCall",
        timestamp: 123,
        result: "call repeated",
        filepath: "app/example.rb",
        line: 2,
      ).to_h

      assert_equal "reek", result.fetch(:tool_name)
      assert_equal "smell_detection", result.fetch(:tool_type)
      refute_includes result.keys, :tool
    end

    def test_writes_check_output_under_tool_type_directory
      in_tmpdir do
        artifacts = prepared_artifacts(target_files: [])
        artifacts.write_check_output(reek_check_output)

        assert_typed_reek_output(artifacts)
      end
    end

    def test_prefers_typed_check_output_over_legacy_duplicate
      in_tmpdir do
        artifacts = prepared_artifacts(target_files: [])
        write_legacy_reek_output("stale")
        artifacts.write_check_output(reek_check_output(raw_output: "fresh"))

        assert_equal 1, artifacts.raw_check_output_records.length
        assert_typed_reek_output(artifacts, raw_output: "fresh")
      end
    end

    def test_reads_legacy_one_level_check_output_directories
      in_tmpdir do
        artifacts = RunArtifacts.new(
          review_id: "review-id",
          timestamp: 123,
          target_files: [],
          changes_diff: "diff",
        ).prepare!
        FileUtils.mkdir_p("tmp/quality_checks/review-id/reek")
        File.write("tmp/quality_checks/review-id/reek/raw_output.json", "[]")

        record = artifacts.raw_check_output_records.first

        assert_equal "reek", record.check_name
        assert_equal "reek", record.tool_name
        assert_nil record.tool_type
        assert_equal "json", record.extension
        assert_equal "[]", record.raw_output
      end
    end

    private

    def load_completed_run
      artifacts = prepared_artifacts
      run = completed_run(artifacts)
      artifacts.write_run(run)

      RunArtifacts.load(review_id: "review-id").to_run(format: "github")
    end

    def assert_reconstructed_run(run)
      review_id, base_ref, format, target_files = run.to_h.values_at(:review_id, :base_ref, :format, :target_files)

      assert_equal "review-id", review_id
      assert_equal "origin/feature-branch", base_ref
      assert_equal "github", format
      assert_equal ["app/example.rb"], target_files
      assert_reconstructed_result(run.results.first)
    end

    def assert_reconstructed_result(result)
      tool_name, tool_type, message = result.to_h.values_at(:tool_name, :tool_type, :result)

      assert_equal "fake", tool_name
      assert_equal "custom", tool_type
      assert_equal "message", message
    end

    def prepared_artifacts(target_files: ["app/example.rb"], changes_diff: "diff")
      RunArtifacts.new(
        review_id: "review-id",
        timestamp: 123,
        target_files: target_files,
        changes_diff: changes_diff,
      ).prepare!
    end

    def reek_check_output(raw_output: "[]")
      Checks::CheckOutput.new(
        check_name: "reek",
        tool_name: "reek",
        tool_type: "smell_detection",
        extension: "json",
        raw_output: raw_output,
        results: [],
      )
    end

    def write_legacy_reek_output(raw_output)
      FileUtils.mkdir_p("tmp/quality_checks/review-id/reek")
      File.write("tmp/quality_checks/review-id/reek/raw_output.json", raw_output)
    end

    def assert_typed_reek_output(artifacts, raw_output: "[]")
      expected_path = "tmp/quality_checks/review-id/smell_detection/reek/raw_output.json"

      assert_path_exists expected_path
      assert_raw_check_output_record(artifacts.raw_check_output_records.first, expected_path, raw_output)
      assert_equal({ "reek" => raw_output }, artifacts.raw_check_outputs)
    end

    def assert_raw_check_output_record(record, expected_path, raw_output)
      assert_equal(
        {
          check_name: "reek",
          tool_name: "reek",
          tool_type: "smell_detection",
          extension: "json",
          path: expected_path,
          raw_output: raw_output,
        },
        record.to_h,
      )
    end

    def completed_run(artifacts)
      Run.new(
        timestamp: 123,
        review_id: "review-id",
        base_ref: "origin/feature-branch",
        format: "agent",
        checks: ["fake"],
        target_files: ["app/example.rb"],
        ruby_files: ["app/example.rb"],
        run_directory: artifacts.to_s,
        results: [sample_result],
        artifacts: artifacts,
      )
    end

    def sample_result
      Result.new(
        tool_name: "fake",
        tool_type: "custom",
        check: "Fake",
        timestamp: 123,
        result: "message",
        filepath: "app/example.rb",
        line: 1,
      )
    end

    def write_legacy_manifest_without_base_ref(artifacts)
      File.write(
        File.join(artifacts.to_s, "manifest.json"),
        JSON.pretty_generate(
          review_id: "review-id",
          timestamp: 123,
          checks: ["fake"],
          target_files: ["app/example.rb"],
          ruby_files: ["app/example.rb"],
        ),
      )
      File.write(File.join(artifacts.to_s, "results.json"), JSON.pretty_generate([]))
      File.write(File.join(artifacts.to_s, "complete.json"), JSON.pretty_generate({ review_id: "review-id", completed: true }))
    end
  end
end
