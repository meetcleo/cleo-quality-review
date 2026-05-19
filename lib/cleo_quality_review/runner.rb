# frozen_string_literal: true

require_relative "changes_diff"
require_relative "check_registry"
require_relative "command_runner"
require_relative "run"
require_relative "run_artifacts"
require_relative "target_resolver"

module CleoQualityReview
  ##
  # Orchestrates a complete quality review run
  class Runner
    ##
    # @param [Options::ParseResult] options parsed command-line options
    # @param [CommandRunner] command_runner for executing shell commands
    # @param [#now] clock time source for timestamps
    # @param [CheckRegistry] check_registry registry for resolving check names
    def initialize(options:, command_runner: CommandRunner.new, clock: Time, check_registry: CheckRegistry.new)
      @options = options
      @command_runner = command_runner
      @clock = clock
      @check_registry = check_registry
    end

    ##
    # Execute the quality review
    # @return [Run] results of the quality review
    def run
      timestamp = epoch_milliseconds
      changed = options.changed || options.files.empty?
      target = TargetResolver.new(command_runner: command_runner).resolve(options.files, changed: changed)
      changes = ChangesDiff.new(target_files: target.files, command_runner: command_runner)
      artifacts = RunArtifacts.new(
        timestamp: timestamp,
        review_id: changes.review_id,
        target_files: target.files,
        changes_diff: changes.to_s,
      ).prepare!
      return artifacts.to_run(format: options.format, log: options.log) if artifacts.complete?

      check_classes = resolve_checks
      check_outputs = run_checks(check_classes, target.ruby_files, timestamp)

      check_outputs.each do |output|
        artifacts.write_check_output(
          check_name: output.check_name,
          extension: output.extension,
          output: output.raw_output,
        )
      end

      run = Run.new(
        timestamp: timestamp,
        review_id: changes.review_id,
        format: options.format,
        checks: check_classes.map(&:check_name),
        target_files: target.files,
        ruby_files: target.ruby_files,
        run_directory: artifacts.to_s,
        results: check_outputs.flat_map(&:results),
        artifacts: artifacts,
        log: options.log,
      )

      artifacts.write_results(run.results)
      artifacts.write_manifest(run)
      artifacts.mark_complete!
      run
    end

    private

    attr_reader :options, :command_runner, :clock, :check_registry

    def epoch_milliseconds
      (clock.now.to_r * 1_000).to_i
    end

    def resolve_checks
      all_checks = check_registry.resolve(options.checks)
      return all_checks if options.exclude.empty?

      excluded_names = options.exclude.map(&:downcase)
      all_checks.reject { |check_class| excluded_names.include?(check_class.check_name.downcase) }
    end

    def run_checks(check_classes, ruby_files, timestamp)
      check_classes.map do |check_class|
        check_class.new(command_runner: command_runner, timestamp: timestamp).run(ruby_files)
      end
    end
  end
end
