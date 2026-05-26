# frozen_string_literal: true

require_relative "../../../test_helper"
require "cleo_quality_review/checks/debride"
require "cleo_quality_review/checks/fasterer"
require "cleo_quality_review/checks/flog"
require "cleo_quality_review/checks/reek"

module CleoQualityReview
  module Checks
    class ParsersTest < Minitest::Test
      FakeCommandRunner = Struct.new(:command_result, keyword_init: true) do
        def run(*)
          command_result
        end
      end

      def test_reek_parser_normalizes_json_smells
        output = JSON.generate(
          [
            {
              "smell_type" => "UtilityFunction",
              "context" => "Example",
              "message" => "does not depend on instance state",
              "source" => "app/example.rb",
              "lines" => [4],
            },
          ],
        )

        result = Reek.new(command_runner: runner(output), timestamp: 123).run(["app/example.rb"]).results.first

        assert_equal "reek", result.tool_name
        assert_equal "smell_detection", result.tool_type
        assert_equal "UtilityFunction", result.check
        assert_equal "Example: does not depend on instance state", result.result
        assert_equal "app/example.rb", result.filepath
        assert_equal 4, result.line
      end

      def test_flog_parser_normalizes_method_scores
        output = "    12.3: Example#perform lib/tasks/import.rake:8-14\n"

        result = Flog.new(command_runner: runner(output), timestamp: 123).run(["lib/tasks/import.rake"]).results.first

        assert_equal "flog", result.tool_name
        assert_equal "complexity", result.tool_type
        assert_equal "Complexity", result.check
        assert_equal "12.3: Example#perform", result.result
        assert_equal "lib/tasks/import.rake", result.filepath
        assert_equal 8, result.line
      end

      def test_fasterer_parser_normalizes_findings
        output = "\e[31mlib/tasks/import.rake:5\e[0m Use Hash#each_key instead of Hash#keys.each.\n"

        result = Fasterer.new(command_runner: runner(output), timestamp: 123).run(["lib/tasks/import.rake"]).results.first

        assert_equal "fasterer", result.tool_name
        assert_equal "performance", result.tool_type
        assert_equal "Performance", result.check
        assert_equal "Use Hash#each_key instead of Hash#keys.each.", result.result
        assert_equal "lib/tasks/import.rake", result.filepath
        assert_equal 5, result.line
      end

      def test_debride_parser_normalizes_missing_methods
        output = JSON.generate(
          {
            "missing" => {
              "Example" => [["unused_method", "app/example.rb:17"]],
            },
          },
        )

        result = Debride.new(command_runner: runner(output), timestamp: 123).run(["app/example.rb"]).results.first

        assert_equal "debride", result.tool_name
        assert_equal "dead_code", result.tool_type
        assert_equal "PotentialDeadMethod", result.check
        assert_equal "Example#unused_method might not be called", result.result
        assert_equal "app/example.rb", result.filepath
        assert_equal 17, result.line
      end

      def test_debride_parser_ignores_empty_missing_output
        output = JSON.generate("missing" => {})

        results = Debride.new(command_runner: runner(output), timestamp: 123).run(["app/example.rb"]).results

        assert_empty results
      end

      private

      def runner(stdout)
        FakeCommandRunner.new(command_result: command_result(stdout: stdout))
      end
    end
  end
end
