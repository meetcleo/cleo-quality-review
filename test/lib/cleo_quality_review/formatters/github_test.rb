# frozen_string_literal: true

require_relative "../../../test_helper"
require "cleo_quality_review/formatters/github"
require "cleo_quality_review/result"
require "cleo_quality_review/run"

module CleoQualityReview
  module Formatters
    class GithubTest < Minitest::Test
      def test_prints_github_warning_annotations_and_summary_notice
        run = Run.new(
          results: [
            Result.new(
              tool: "reek",
              check: "Utility, Function",
              result: "Line one\nLine two 100%",
              filepath: "app/example.rb",
              line: 4,
            ),
          ],
        )

        output = Github.new(run: run).format

        assert_includes(
          output,
          "::warning file=app/example.rb,line=4,title=reek%3A Utility%2C Function::Line one%0ALine two 100%25",
        )
        assert_includes output, "::notice title=Cleo Quality Review Summary::"
        assert_includes output, "Cleo Quality Review top actionable issues."
      end

      def test_returns_empty_string_when_no_findings
        run = Run.new(results: [])

        assert_equal "", Github.new(run: run).format
      end
    end
  end
end
