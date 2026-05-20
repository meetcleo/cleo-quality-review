# frozen_string_literal: true

require_relative "configuration"

module CleoQualityReview
  ##
  # Resolves target files for quality review based on git changes and configuration
  class TargetResolver
    BASE_REF = "origin/main"

    ##
    # Value object containing resolved file lists
    #
    # @!attribute [r] files
    #   @return [Array<String>] all target file paths
    # @!attribute [r] ruby_files
    #   @return [Array<String>] Ruby file paths
    Target = Struct.new(:files, :ruby_files, keyword_init: true)

    ##
    # @param [CommandRunner] command_runner for executing git commands
    # @param [Configuration] configuration file filtering configuration
    def initialize(command_runner:, configuration: Configuration.load)
      @command_runner = command_runner
      @configuration = configuration
    end

    ##
    # Resolve target files for quality review
    # @param [Array<String>] files explicit file paths
    # @param [Boolean] changed when true, filter to git-changed files only
    # @return [Target]
    def resolve(files, changed: false)
      target_files = resolve_target_files(files, changed: changed)

      Target.new(
        files: target_files,
        ruby_files: target_files,
      )
    end

    private

    attr_reader :command_runner, :configuration

    def resolve_target_files(files, changed:)
      candidates = if files.empty?
        changed_files
      else
        expanded_paths = expand_target_paths(files)
        changed ? filter_to_changed(expanded_paths) : expanded_paths
      end

      candidates.select do |path|
        File.file?(path) && configuration.target_file?(path)
      end
    end

    def filter_to_changed(paths)
      git_changed = changed_files
      paths.select { |path| git_changed.include?(path) }
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
      files, directories, missing = classify_paths(cleaned_paths)
      raise ArgumentError, "Path not found: #{missing.join(', ')}" unless missing.empty?

      (files + directories.flat_map { |path| directory_files(path) }).uniq
    end

    def classify_paths(paths)
      paths.group_by { |path| path_type(path) }.values_at(:file, :directory, :missing).map { |v| v || [] }
    end

    def path_type(path)
      return :file if File.file?(path)
      return :directory if File.directory?(path)

      :missing
    end

    def directory_files(path)
      Dir.glob(File.join(path, "**", "*"), File::FNM_DOTMATCH).sort.select do |expanded_path|
        File.file?(expanded_path)
      end
    end
  end
end
