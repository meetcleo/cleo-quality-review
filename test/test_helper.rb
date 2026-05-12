# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "tmpdir"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "cleo_quality"
require "cleo_quality/command_result"

module CleoQualityTestHelpers
  Status = Struct.new(:success) do
    def success?
      success
    end

    def exitstatus
      success ? 0 : 1
    end
  end

  def command_result(stdout: "", stderr: "", success: true)
    CleoQuality::CommandResult.new(
      stdout: stdout,
      stderr: stderr,
      status: Status.new(success),
    )
  end

  def in_tmpdir
    Dir.mktmpdir do |dir|
      original_dir = Dir.pwd
      Dir.chdir(dir)
      yield dir
    ensure
      Dir.chdir(original_dir)
    end
  end
end

Minitest::Test.include(CleoQualityTestHelpers)

class StubGitCommandRunner
  def run(*command, env: {})
    case command
    when ["git", "merge-base", "origin/main", "HEAD"]
      result(stdout: "base-sha\n")
    when ["git", "diff", "base-sha", "--", "app/example.rb", "README.md"]
      result(stdout: "diff --git a/app/example.rb b/app/example.rb\n")
    when ["git", "ls-files", "--others", "--exclude-standard", "--", "app/example.rb", "README.md"]
      result(stdout: "")
    else
      result(stdout: "")
    end
  end

  private

  def result(stdout:, stderr: "", success: true)
    CleoQuality::CommandResult.new(
      stdout: stdout,
      stderr: stderr,
      status: CleoQualityTestHelpers::Status.new(success),
    )
  end
end
