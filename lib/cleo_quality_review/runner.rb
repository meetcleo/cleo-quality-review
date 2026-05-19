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
      target = resolve_target
      changes = changes_diff(target)
      artifacts = prepare_artifacts(timestamp: timestamp, target: target, changes: changes)
      return reusable_run(artifacts) if artifacts.complete?

      check_classes = resolve_checks
      check_outputs = run_checks(check_classes, target.ruby_files, timestamp)
      write_check_outputs(artifacts, check_outputs)

      run = build_run(
        timestamp: timestamp,
        target: target,
        changes: changes,
        artifacts: artifacts,
        check_classes: check_classes,
        check_outputs: check_outputs,
      )
      persist_run(artifacts, run)
      run
    end

    private

    attr_reader :options, :command_runner, :clock, :check_registry

    def epoch_milliseconds
      (clock.now.to_r * 1_000).to_i
    end

    def resolve_target
      changed = options.changed || options.files.empty?
      TargetResolver.new(command_runner: command_runner).resolve(options.files, changed: changed)
    end

    def changes_diff(target)
      ChangesDiff.new(target_files: target.files, command_runner: command_runner)
    end

    def prepare_artifacts(timestamp:, target:, changes:)
      RunArtifacts.new(
        timestamp: timestamp,
        review_id: changes.review_id,
        target_files: target.files,
        changes_diff: changes.to_s,
      ).prepare!
    end

    def reusable_run(artifacts)
      artifacts.to_run(format: options.format, log: options.log)
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

    def write_check_outputs(artifacts, check_outputs)
      check_outputs.each do |output|
        artifacts.write_check_output(
          check_name: output.check_name,
          extension: output.extension,
          output: output.raw_output,
        )
      end
    end

    def build_run(timestamp:, target:, changes:, artifacts:, check_classes:, check_outputs:)
      Run.new(
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
    end

    def persist_run(artifacts, run)
      artifacts.write_results(run.results)
      artifacts.write_manifest(run)
      artifacts.mark_complete!
    end
  end
end
