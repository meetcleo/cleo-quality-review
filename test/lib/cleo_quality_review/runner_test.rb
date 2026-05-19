# frozen_string_literal: true

require_relative "../../test_helper"
require "digest"
require "cleo_quality_review/checks/quality_check"
require "cleo_quality_review/options"
require "cleo_quality_review/runner"

module CleoQualityReview
  class RunnerTest < Minitest::Test
    FakeClock = Struct.new(:now, keyword_init: true)

    FakeCommandRunner = Struct.new(:calls, keyword_init: true) do
      def run(*command, env: {})
        calls << command
        case command
        when ["git", "merge-base", "origin/main", "HEAD"]
          CleoQualityReview::CommandResult.new(stdout: "base-sha\n", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
        when ["git", "diff", "--name-only", "--diff-filter=ACMRT", "base-sha"]
          CleoQualityReview::CommandResult.new(stdout: "app/example.rb\n", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
        when ["git", "ls-files", "--others", "--exclude-standard"]
          CleoQualityReview::CommandResult.new(stdout: "", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
        when ["git", "diff", "base-sha", "--", "app/example.rb"]
          CleoQualityReview::CommandResult.new(stdout: "diff --git a/app/example.rb b/app/example.rb\n", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
        when ["git", "ls-files", "--others", "--exclude-standard", "--", "app/example.rb"]
          CleoQualityReview::CommandResult.new(stdout: "", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
        else
          CleoQualityReview::CommandResult.new(stdout: "", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
        end
      end
    end

    FakeCheckRegistry = Struct.new(:received_checks, keyword_init: true) do
      def resolve(checks)
        self.received_checks = checks
        [FakeCheck]
      end
    end

    FakeCheck = Class.new(Checks::QualityCheck) do
      self.check_name = "fake"
      self.tool = "fake"

      private

      def command(files)
        ["fake", *files]
      end

      def parse(_stdout, _stderr)
        [
          result(
            check: "Fake",
            message: "fake result",
            filepath: "app/example.rb",
            line: 1,
          ),
        ]
      end
    end

    def test_runs_checks_and_writes_artifacts
      in_tmpdir do
        FileUtils.mkdir_p("app")
        File.write("app/example.rb", "# frozen_string_literal: true\n")

        command_runner = FakeCommandRunner.new(calls: [])
        check_registry = FakeCheckRegistry.new
        runner = Runner.new(
          options: Options::ParseResult.new(format: "agent", checks: ["fake"], files: [], exclude: [], changed: false),
          command_runner: command_runner,
          clock: FakeClock.new(now: Time.at(123)),
          check_registry: check_registry,
        )

        run = runner.run

        assert_equal 123000, run.timestamp
        assert_equal ["app/example.rb"], run.target_files
        assert_equal ["fake"], run.checks
        assert_equal ["fake"], check_registry.received_checks
        assert_equal "fake result", run.results.first.result
        review_id = Digest::SHA256.hexdigest("diff --git a/app/example.rb b/app/example.rb\n")
        assert_equal review_id, run.review_id
        assert_equal "diff --git a/app/example.rb b/app/example.rb\n", File.read("tmp/quality_checks/#{review_id}/changes.diff")
        assert_equal "", File.read("tmp/quality_checks/#{review_id}/fake/raw_output.txt")
        assert_path_exists "tmp/quality_checks/#{review_id}/complete.json"
        assert_path_exists "tmp/quality_checks/#{review_id}/manifest.json"
        assert_path_exists "tmp/quality_checks/#{review_id}/results.json"
        assert_equal "", run.artifacts.raw_check_outputs.fetch("fake")
      end
    end

    def test_defaults_to_changed_mode_when_no_files_provided
      in_tmpdir do
        FileUtils.mkdir_p("app")
        File.write("app/example.rb", "# frozen_string_literal: true\n")

        command_runner = FakeCommandRunner.new(calls: [])
        runner = Runner.new(
          options: Options::ParseResult.new(format: "agent", checks: ["fake"], files: [], exclude: [], changed: false),
          command_runner: command_runner,
          clock: FakeClock.new(now: Time.at(123)),
          check_registry: FakeCheckRegistry.new,
        )

        runner.run

        git_commands = command_runner.calls.select { |cmd| cmd.first == "git" }
        assert git_commands.any? { |cmd| cmd.include?("merge-base") }, "Should call git merge-base when no files provided"
      end
    end

    def test_exclude_removes_specified_checks
      in_tmpdir do
        FileUtils.mkdir_p("app")
        File.write("app/example.rb", "# frozen_string_literal: true\n")

        check_registry = FakeCheckRegistry.new
        runner = Runner.new(
          options: Options::ParseResult.new(format: "agent", checks: ["all"], files: [], exclude: ["fake"], changed: false),
          command_runner: FakeCommandRunner.new(calls: []),
          clock: FakeClock.new(now: Time.at(123)),
          check_registry: check_registry,
        )

        run = runner.run

        assert_equal [], run.checks
      end
    end

    def test_only_and_exclude_combined_exclude_takes_precedence
      in_tmpdir do
        FileUtils.mkdir_p("app")
        File.write("app/example.rb", "# frozen_string_literal: true\n")

        check_registry = FakeCheckRegistry.new
        runner = Runner.new(
          options: Options::ParseResult.new(format: "agent", checks: ["fake"], files: [], exclude: ["fake"], changed: false),
          command_runner: FakeCommandRunner.new(calls: []),
          clock: FakeClock.new(now: Time.at(123)),
          check_registry: check_registry,
        )

        run = runner.run

        assert_equal [], run.checks
      end
    end

    def test_changed_with_no_git_changes_returns_empty_target_files
      in_tmpdir do
        FileUtils.mkdir_p("app")
        File.write("app/example.rb", "# frozen_string_literal: true\n")

        command_runner = FakeCommandRunner.new(calls: [])
        command_runner.define_singleton_method(:run) do |*command, env: {}|
          calls << command
          case command
          when ["git", "merge-base", "origin/main", "HEAD"]
            CleoQualityReview::CommandResult.new(stdout: "base-sha\n", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
          when ["git", "diff", "--name-only", "--diff-filter=ACMRT", "base-sha"]
            CleoQualityReview::CommandResult.new(stdout: "", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
          when ["git", "ls-files", "--others", "--exclude-standard"]
            CleoQualityReview::CommandResult.new(stdout: "", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
          else
            CleoQualityReview::CommandResult.new(stdout: "", stderr: "", status: CleoQualityReviewTestHelpers::Status.new(true))
          end
        end

        runner = Runner.new(
          options: Options::ParseResult.new(format: "agent", checks: ["fake"], files: [], exclude: [], changed: true),
          command_runner: command_runner,
          clock: FakeClock.new(now: Time.at(123)),
          check_registry: FakeCheckRegistry.new,
        )

        run = runner.run

        assert_equal [], run.target_files
      end
    end

    def test_reuses_completed_artifacts_for_same_diff
      in_tmpdir do
        FileUtils.mkdir_p("app")
        File.write("app/example.rb", "# frozen_string_literal: true\n")

        command_runner = FakeCommandRunner.new(calls: [])
        options = Options::ParseResult.new(format: "agent", checks: ["fake"], files: [], exclude: [], changed: false)

        2.times do
          Runner.new(
            options: options,
            command_runner: command_runner,
            clock: FakeClock.new(now: Time.at(123)),
            check_registry: FakeCheckRegistry.new,
          ).run
        end

        fake_tool_calls = command_runner.calls.select { |command| command == ["fake", "app/example.rb"] }
        assert_equal 1, fake_tool_calls.length
      end
    end
  end
end
