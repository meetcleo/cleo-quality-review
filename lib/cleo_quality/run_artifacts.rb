# frozen_string_literal: true

require "fileutils"

require_relative "target_resolver"

module CleoQuality
  class RunArtifacts
    ROOT = "tmp/quality_checks"

    attr_reader :timestamp, :target_files

    def initialize(timestamp:, target_files:, command_runner:)
      @timestamp = timestamp
      @target_files = target_files
      @command_runner = command_runner
      @path = File.join(ROOT, timestamp.to_s)
    end

    def prepare!
      reserve_path
      write_changes_diff
      self
    end

    def write_check_output(check_name:, extension:, output:)
      check_path = File.join(path, check_name)
      FileUtils.mkdir_p(check_path)
      File.write(File.join(check_path, "raw_output.#{extension}"), output)
    end

    def changes_diff
      File.read(changes_diff_path)
    end

    def raw_check_outputs
      Dir.glob(File.join(path, "*", "raw_output.*")).sort.to_h do |filepath|
        check_name = File.basename(File.dirname(filepath))
        [check_name, File.read(filepath, invalid: :replace, undef: :replace)]
      end
    end

    def to_s
      path
    end

    private

    attr_reader :command_runner, :path

    def reserve_path
      FileUtils.mkdir_p(ROOT)

      path_candidates.each do |candidate|
        Dir.mkdir(candidate)
        @path = candidate
        return
      rescue Errno::EEXIST
        next
      end
    end

    def path_candidates
      base_path = File.join(ROOT, timestamp.to_s)

      Enumerator.new do |candidates|
        candidates << base_path
        counter = 1
        loop do
          candidates << "#{base_path}-#{Process.pid}-#{counter}"
          counter += 1
        end
      end
    end

    def changes_diff_path
      File.join(path, "changes.diff")
    end

    def write_changes_diff
      File.write(changes_diff_path, [tracked_changes_diff, untracked_changes_diff].reject(&:empty?).join("\n"))
    end

    def tracked_changes_diff
      command = ["git", "diff", diff_base]
      command.concat(["--", *target_files]) unless target_files.empty?

      command_runner.run(*command).stdout
    end

    def untracked_changes_diff
      untracked_target_files.map do |filepath|
        command_runner.run("git", "diff", "--no-index", "--", "/dev/null", filepath).stdout
      end.reject(&:empty?).join("\n")
    end

    def untracked_target_files
      command = ["git", "ls-files", "--others", "--exclude-standard"]
      command.concat(["--", *target_files]) unless target_files.empty?

      command_runner.run(*command).stdout.lines.map(&:strip).select do |path|
        target_files.empty? || target_files.include?(path)
      end
    end

    def diff_base
      @diff_base ||= begin
        result = command_runner.run("git", "merge-base", TargetResolver::BASE_REF, "HEAD")
        base = result.stdout.strip

        result.success? && !base.empty? ? base : TargetResolver::BASE_REF
      end
    end
  end
end
