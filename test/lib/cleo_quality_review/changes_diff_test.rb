# frozen_string_literal: true

require_relative "../../test_helper"
require "digest"
require "cleo_quality_review/changes_diff"

module CleoQualityReview
  class ChangesDiffTest < Minitest::Test
    Runner = Struct.new(:calls, keyword_init: true) do
      def run(*command, env: {})
        calls << command
        case command
        when ["git", "merge-base", "origin/main", "HEAD"]
          command_result(stdout: "base-sha\n")
        when ["git", "diff", "base-sha", "--", "app/example.rb"]
          command_result(stdout: "diff content")
        when ["git", "ls-files", "--others", "--exclude-standard", "--", "app/example.rb"]
          command_result(stdout: "")
        else
          command_result(stdout: "")
        end
      end

      private

      def command_result(stdout:)
        CleoQualityReview::CommandResult.new(
          stdout: stdout,
          stderr: "",
          status: CleoQualityReviewTestHelpers::Status.new(true),
        )
      end
    end

    def test_captures_diff_and_review_id
      changes = ChangesDiff.new(target_files: ["app/example.rb"], command_runner: Runner.new(calls: []))

      assert_equal "diff content", changes.to_s
      assert_equal Digest::SHA256.hexdigest("diff content"), changes.review_id
    end
  end
end
