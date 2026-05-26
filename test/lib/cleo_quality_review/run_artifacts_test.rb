# frozen_string_literal: true

require_relative "../../test_helper"
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
        artifacts = RunArtifacts.new(
          review_id: "review-id",
          timestamp: 123,
          target_files: ["app/example.rb"],
          changes_diff: "diff",
        ).prepare!

        run = Run.new(
          timestamp: 123,
          review_id: "review-id",
          format: "agent",
          checks: ["fake"],
          target_files: ["app/example.rb"],
          ruby_files: ["app/example.rb"],
          run_directory: artifacts.to_s,
          results: [Result.new(tool_name: "fake", tool_type: "custom", check: "Fake", timestamp: 123, result: "message", filepath: "app/example.rb", line: 1)],
          artifacts: artifacts,
        )
        artifacts.write_results(run.results)
        artifacts.write_manifest(run)
        artifacts.mark_complete!

        loaded = RunArtifacts.load(review_id: "review-id").to_run(format: "github")

        assert_equal "review-id", loaded.review_id
        assert_equal "github", loaded.format
        assert_equal ["app/example.rb"], loaded.target_files
        assert_equal "fake", loaded.results.first.tool_name
        assert_equal "custom", loaded.results.first.tool_type
        assert_equal "message", loaded.results.first.result
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

        artifacts.write_check_output(
          check_name: "reek",
          tool_name: "reek",
          tool_type: "smell_detection",
          extension: "json",
          output: "[]",
        )

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
  end
end
