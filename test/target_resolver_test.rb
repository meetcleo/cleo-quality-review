# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/target_resolver"

module CleoQualityReview
  class TargetResolverTest < Minitest::Test
    FakeCommandRunner = Struct.new(:results, keyword_init: true) do
      def run(*command)
        results.fetch(command)
      end
    end

    def test_defaults_to_changed_ruby_files
      in_tmpdir do
        FileUtils.mkdir_p("app/models")
        File.write("app/models/user.rb", "# frozen_string_literal: true\n")
        File.write("README.md", "# README\n")

        resolver = TargetResolver.new(
          command_runner: FakeCommandRunner.new(
            results: {
              ["git", "merge-base", "origin/main", "HEAD"] => command_result(stdout: "base-sha\n"),
              ["git", "diff", "--name-only", "--diff-filter=ACMRT", "base-sha"] => command_result(stdout: "app/models/user.rb\nREADME.md\nmissing.rb\n"),
              ["git", "ls-files", "--others", "--exclude-standard"] => command_result(stdout: "app/models/untracked.rb\n"),
            },
          ),
        )

        target = resolver.resolve([])

        assert_equal ["app/models/user.rb"], target.files
        assert_equal ["app/models/user.rb"], target.ruby_files
      end
    end

    def test_includes_existing_untracked_ruby_files_by_default
      in_tmpdir do
        FileUtils.mkdir_p("app/models")
        File.write("app/models/untracked.rb", "# frozen_string_literal: true\n")

        resolver = TargetResolver.new(
          command_runner: FakeCommandRunner.new(
            results: {
              ["git", "merge-base", "origin/main", "HEAD"] => command_result(stdout: "base-sha\n"),
              ["git", "diff", "--name-only", "--diff-filter=ACMRT", "base-sha"] => command_result(stdout: ""),
              ["git", "ls-files", "--others", "--exclude-standard"] => command_result(stdout: "app/models/untracked.rb\nREADME.md\n"),
            },
          ),
        )

        target = resolver.resolve([])

        assert_equal ["app/models/untracked.rb"], target.files
      end
    end

    def test_explicit_files_can_include_non_ruby_prompt_context
      in_tmpdir do
        FileUtils.mkdir_p("app/models")
        File.write("app/models/user.rb", "# frozen_string_literal: true\n")
        File.write("README.md", "# README\n")

        target = TargetResolver.new(command_runner: FakeCommandRunner.new).resolve(["app/models/user.rb", "README.md"])

        assert_equal ["app/models/user.rb", "README.md"], target.files
        assert_equal ["app/models/user.rb"], target.ruby_files
      end
    end

    def test_explicit_directories_expand_recursively
      in_tmpdir do
        FileUtils.mkdir_p("app/models/nested")
        File.write("app/models/user.rb", "# frozen_string_literal: true\n")
        File.write("app/models/nested/account.rb", "# frozen_string_literal: true\n")
        File.write("app/models/README.md", "# README\n")

        target = TargetResolver.new(command_runner: FakeCommandRunner.new).resolve(["app/models"])

        assert_equal ["app/models/README.md", "app/models/nested/account.rb", "app/models/user.rb"], target.files
        assert_equal ["app/models/nested/account.rb", "app/models/user.rb"], target.ruby_files
      end
    end

    def test_explicit_missing_path_fails
      error = assert_raises(ArgumentError) do
        TargetResolver.new(command_runner: FakeCommandRunner.new).resolve(["missing.rb"])
      end

      assert_includes error.message, "Path not found"
    end
  end
end
