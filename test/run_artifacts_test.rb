# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/run_artifacts"

module CleoQualityReview
  class RunArtifactsTest < Minitest::Test
    def test_reserves_unique_directory_when_timestamp_directory_exists
      in_tmpdir do
        FileUtils.mkdir_p("tmp/quality_checks/123")

        artifacts = RunArtifacts.new(
          timestamp: 123,
          target_files: [],
          command_runner: StubGitCommandRunner.new,
        ).prepare!

        refute_equal "tmp/quality_checks/123", artifacts.to_s
        assert_match %r{\Atmp/quality_checks/123-\d+-1\z}, artifacts.to_s
        assert_path_exists File.join(artifacts.to_s, "changes.diff")
      end
    end
  end
end
