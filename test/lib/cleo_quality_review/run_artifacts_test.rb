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

        assert_equal "tmp/quality_checks/review-id", artifacts.to_s
        assert_path_exists File.join(artifacts.to_s, "changes.diff")
        assert_equal "diff content", artifacts.changes_diff
      end
    end

    def test_reconstructs_run_from_completed_artifacts
      in_tmpdir do
        assert_reconstructed_run(load_completed_run)
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
        artifacts = RunArtifacts.new(
          review_id: "review-id",
          timestamp: 123,
          target_files: [],
          changes_diff: "diff",
        ).prepare!

        check_output = Checks::CheckOutput.new(
          check_name: "reek",
          tool_name: "reek",
          tool_type: "smell_detection",
          extension: "json",
          raw_output: "[]",
          results: [],
        )
        artifacts.write_check_output(check_output)

        expected_path = "tmp/quality_checks/review-id/smell_detection/reek/raw_output.json"
        record = artifacts.raw_check_output_records.first

        assert_path_exists expected_path
        assert_equal "reek", record.check_name
        assert_equal "reek", record.tool_name
        assert_equal "smell_detection", record.tool_type
        assert_equal "json", record.extension
        assert_equal expected_path, record.path
        assert_equal "[]", record.raw_output
        assert_equal({ "reek" => "[]" }, artifacts.raw_check_outputs)
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
      artifacts.write_results(run.results)
      artifacts.write_manifest(run)
      artifacts.mark_complete!

      RunArtifacts.load(review_id: "review-id").to_run(format: "github")
    end

    def assert_reconstructed_run(run)
      review_id, format, target_files = run.to_h.values_at(:review_id, :format, :target_files)

      assert_equal "review-id", review_id
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

    def prepared_artifacts
      RunArtifacts.new(
        review_id: "review-id",
        timestamp: 123,
        target_files: ["app/example.rb"],
        changes_diff: "diff",
      ).prepare!
    end

    def completed_run(artifacts)
      Run.new(
        timestamp: 123,
        review_id: "review-id",
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
  end
end
