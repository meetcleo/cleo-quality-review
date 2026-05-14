# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/options"

module CleoQualityReview
  class OptionsTest < Minitest::Test
    def test_defaults_to_human_format_and_all_checks
      options = Options.parse([])

      assert_equal "human", options.format
      assert_equal ["all"], options.checks
      assert_equal [], options.files
    end

    def test_parses_repeated_comma_separated_checks_and_files
      options = Options.parse(
        [
          "--format",
          "agent",
          "--checks",
          "reek,flog",
          "--checks",
          "fasterer",
          "--files",
          "app/a.rb,README.md",
          "--files",
          "app/b.rb",
        ],
      )

      assert_equal "agent", options.format
      assert_equal %w[reek flog fasterer], options.checks
      assert_equal ["app/a.rb", "README.md", "app/b.rb"], options.files
    end

    def test_rejects_unknown_format
      error = assert_raises(OptionParser::InvalidArgument) do
        Options.parse(["--format", "xml"])
      end

      assert_includes error.message, "invalid argument"
    end
  end
end
