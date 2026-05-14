# frozen_string_literal: true

require "json"
require_relative "../test_helper"
require "cleo_quality_review/formatters/agent"
require "cleo_quality_review/result"
require "cleo_quality_review/run"
require "cleo_quality_review/run_artifacts"

module CleoQualityReview
  module Formatters
    class AgentTest < Minitest::Test
      def test_prints_single_json_document
        in_tmpdir do
          artifacts = RunArtifacts.new(
            timestamp: 123,
            target_files: ["app/example.rb"],
            command_runner: StubGitCommandRunner.new,
          ).prepare!
          FileUtils.mkdir_p("tmp/quality_checks/123/reek")
          File.write("tmp/quality_checks/123/reek/raw_output.json", "[{\"smell\":\"Utility Function\"}]")

          run = Run.new(
            timestamp: 123,
            format: "agent",
            checks: ["reek"],
            target_files: ["app/example.rb"],
            ruby_files: ["app/example.rb"],
            run_directory: "tmp/quality_checks/123",
            results: [
              Result.new(
                tool: "reek",
                check: "Utility Function",
                timestamp: 123,
                result: "Example has the smell",
                filepath: "app/example.rb",
                line: 2,
              ),
            ],
            artifacts: artifacts,
          )

          json = JSON.parse(Agent.new(run: run).format)

          assert_equal 123, json.fetch("timestamp")
          assert_equal ["reek"], json.fetch("checks")
          assert_includes json.fetch("instructions"), "coding agent"
          output = json.fetch("check_outputs").first
          assert_equal "reek", output.fetch("check")
          assert_equal "[{\"smell\":\"Utility Function\"}]", output.fetch("raw_output")
          assert_equal "reek", json.fetch("findings").first.fetch("tool")
        end
      end
    end
  end
end
