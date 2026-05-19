# frozen_string_literal: true

require_relative "../../test_helper"
require "json"
require "cleo_quality_review/github_review_builder"
require "cleo_quality_review/run"
require "cleo_quality_review/run_artifacts"

module CleoQualityReview
  class GitHubReviewBuilderTest < Minitest::Test
    def test_builds_inline_comments_for_findings_on_diff_lines
      in_tmpdir do
        artifacts = RunArtifacts.new(
          review_id: "review-id",
          changes_diff: <<~DIFF,
            diff --git a/app/example.rb b/app/example.rb
            --- a/app/example.rb
            +++ b/app/example.rb
            @@ -1,2 +1,2 @@
             class Example
            +  def perform = true
          DIFF
        ).prepare!
        run = Run.new(
          review_id: "review-id",
          timestamp: 123,
          checks: ["reek"],
          target_files: ["app/example.rb"],
          results: [
            Result.new(tool: "reek", check: "DuplicateMethodCall", timestamp: 123, result: "call repeated", filepath: "app/example.rb", line: 2),
            Result.new(tool: "flog", check: "Complexity", timestamp: 123, result: "too complex", filepath: "app/other.rb", line: 1),
          ],
          artifacts: artifacts,
        )

        rendered_review = JSON.generate(
          {
            body: "Review body",
            comments: [
              { path: "app/example.rb", line: 2, body: "Inline comment" },
              { path: "app/other.rb", line: 1, body: "Ignored comment" },
            ],
          },
        )

        payload = GitHubReviewBuilder.new(run: run, rendered_review: rendered_review).payload(commit_id: "head-sha")

        assert_equal "COMMENT", payload.fetch(:event)
        assert_equal "head-sha", payload.fetch(:commit_id)
        assert_includes payload.fetch(:body), "cleo-quality-review:review-id"
        assert_includes payload.fetch(:body), "Review body"
        assert_equal 1, payload.fetch(:comments).length
        assert_equal "app/example.rb", payload.fetch(:comments).first.fetch(:path)
        assert_equal 2, payload.fetch(:comments).first.fetch(:line)
      end
    end
  end
end
