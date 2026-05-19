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
          results: [Result.new(tool: "fake", check: "Fake", timestamp: 123, result: "message", filepath: "app/example.rb", line: 1)],
          artifacts: artifacts,
        )
        artifacts.write_results(run.results)
        artifacts.write_manifest(run)
        artifacts.mark_complete!

        loaded = RunArtifacts.load(review_id: "review-id").to_run(format: "github")

        assert_equal "review-id", loaded.review_id
        assert_equal "github", loaded.format
        assert_equal ["app/example.rb"], loaded.target_files
        assert_equal "message", loaded.results.first.result
      end
    end
  end
end
