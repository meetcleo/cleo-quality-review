# frozen_string_literal: true

require_relative "../../test_helper"
require "json"
require "cleo_quality_review/github_review_publisher"
require "cleo_quality_review/run"
require "cleo_quality_review/run_artifacts"

module CleoQualityReview
  class GitHubReviewPublisherTest < Minitest::Test
    Response = Struct.new(:status_code, :body, keyword_init: true) do
      def success?
        (200..299).cover?(status_code)
      end
    end

    def test_skips_without_pull_request_context
      in_tmpdir do |dir|
        event_path = File.join(dir, "event.json")
        File.write(event_path, JSON.generate({ "push" => {} }))
        publisher = GitHubReviewPublisher.new(
          run: run_with_findings,
          env: {
            "GITHUB_EVENT_PATH" => event_path,
            "GITHUB_REPOSITORY" => "owner/repo",
            "GITHUB_TOKEN" => "token",
          },
        )

        assert_equal "No pull_request event found; skipping PR review publication.", publisher.publish
      end
    end

    def test_publishes_review_payload
      in_tmpdir do |dir|
        event_path = File.join(dir, "event.json")
        File.write(
          event_path,
          JSON.generate(
            {
              "number" => 42,
              "pull_request" => {
                "head" => { "sha" => "head-sha" },
              },
            },
          ),
        )
        requests = []
        publisher = GitHubReviewPublisher.new(
          run: run_with_findings,
          env: {
            "GITHUB_API_URL" => "https://api.github.test",
            "GITHUB_EVENT_PATH" => event_path,
            "GITHUB_REPOSITORY" => "owner/repo",
            "GITHUB_TOKEN" => "token",
          },
        )
        publisher.define_singleton_method(:request_json) do |method, uri, body = nil|
          requests << [method, uri.to_s, body]
          method == :get ? Response.new(status_code: 200, body: "[]") : Response.new(status_code: 201, body: "{}")
        end

        assert_equal "Published PR review for review ID review-id.", publisher.publish
        assert_equal :get, requests.first.first
        assert_equal :post, requests.last.first
        assert_equal "https://api.github.test/repos/owner/repo/pulls/42/reviews", requests.last[1]
        assert_equal "head-sha", requests.last[2].fetch(:commit_id)
      end
    end

    private

    def run_with_findings
      artifacts = RunArtifacts.new(
        review_id: "review-id",
        changes_diff: <<~DIFF,
          diff --git a/app/example.rb b/app/example.rb
          --- a/app/example.rb
          +++ b/app/example.rb
          @@ -1,1 +1,2 @@
           class Example
          +  def perform = true
        DIFF
      ).prepare!
      Run.new(
        review_id: "review-id",
        timestamp: 123,
        checks: ["reek"],
        target_files: ["app/example.rb"],
        results: [
          Result.new(tool: "reek", check: "DuplicateMethodCall", timestamp: 123, result: "call repeated", filepath: "app/example.rb", line: 2),
        ],
        artifacts: artifacts,
      )
    end
  end
end
