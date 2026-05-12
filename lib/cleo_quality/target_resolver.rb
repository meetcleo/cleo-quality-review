# frozen_string_literal: true

module CleoQuality
  class TargetResolver
    BASE_REF = "origin/main"
    RUBY_EXTENSION = ".rb"

    Target = Struct.new(:files, :ruby_files, keyword_init: true)

    def initialize(command_runner:)
      @command_runner = command_runner
    end

    def resolve(files)
      target_files = files.empty? ? changed_ruby_files : expand_target_paths(files)

      Target.new(
        files: target_files,
        ruby_files: target_files.select { |path| ruby_file?(path) },
      )
    end

    private

    attr_reader :command_runner

    def changed_ruby_files
      (tracked_changed_files + untracked_files).uniq.select do |path|
        ruby_file?(path) && File.file?(path)
      end
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

    def ruby_file?(path)
      File.extname(path) == RUBY_EXTENSION
    end
  end
end
