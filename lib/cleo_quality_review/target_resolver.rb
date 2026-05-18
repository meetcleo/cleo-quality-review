# frozen_string_literal: true

require_relative "configuration"

module CleoQualityReview
  class TargetResolver
    BASE_REF = "origin/main"

    Target = Struct.new(:files, :ruby_files, keyword_init: true)

    def initialize(command_runner:, configuration: Configuration.load)
      @command_runner = command_runner
      @configuration = configuration
    end

    def resolve(files)
      target_files = resolve_target_files(files)

      Target.new(
        files: target_files,
        ruby_files: target_files,
      )
    end

    private

    attr_reader :command_runner, :configuration

    def resolve_target_files(files)
      candidates = files.empty? ? changed_files : expand_target_paths(files)

      candidates.select do |path|
        File.file?(path) && configuration.target_file?(path)
      end
    end

    def changed_files
      (tracked_changed_files + untracked_files).uniq
    end

    def tracked_changed_files
      result = command_runner.run(
        "git",
        "diff",
        "--name-only",
        "--diff-filter=ACMRT",
        diff_base,
      )

      result.stdout.lines.map(&:strip)
    end

    def untracked_files
      result = command_runner.run("git", "ls-files", "--others", "--exclude-standard")

      result.stdout.lines.map(&:strip)
    end

    def diff_base
      @diff_base ||= begin
        result = command_runner.run("git", "merge-base", BASE_REF, "HEAD")
        base = result.stdout.strip

        result.success? && !base.empty? ? base : BASE_REF
      end
    end

    def expand_target_paths(paths)
      cleaned_paths = paths.map(&:to_s).map(&:strip).reject(&:empty?)
      missing_paths = cleaned_paths.reject { |path| File.file?(path) || File.directory?(path) }
      raise ArgumentError, "Path not found: #{missing_paths.join(', ')}" unless missing_paths.empty?

      cleaned_paths.flat_map do |path|
        if File.directory?(path)
          directory_files(path)
        else
          path
        end
      end.uniq
    end

    def directory_files(path)
      Dir.glob(File.join(path, "**", "*"), File::FNM_DOTMATCH).sort.select do |expanded_path|
        File.file?(expanded_path)
      end
    end
  end
end
