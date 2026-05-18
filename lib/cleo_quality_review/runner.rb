# frozen_string_literal: true

require_relative "check_registry"
require_relative "command_runner"
require_relative "run"
require_relative "run_artifacts"
require_relative "target_resolver"

module CleoQualityReview
  class Runner
    def initialize(options:, command_runner: CommandRunner.new, clock: Time, check_registry: CheckRegistry.new)
      @options = options
      @command_runner = command_runner
      @clock = clock
      @check_registry = check_registry
    end

    def run
      timestamp = epoch_milliseconds
      changed = options.changed || options.files.empty?
      target = TargetResolver.new(command_runner: command_runner).resolve(options.files, changed: changed)
      artifacts = RunArtifacts.new(
        timestamp: timestamp,
        target_files: target.files,
        command_runner: command_runner,
      ).prepare!

      check_classes = check_registry.resolve(options.checks)
      check_outputs = run_checks(check_classes, target.ruby_files, timestamp)

      check_outputs.each do |output|
        artifacts.write_check_output(
          check_name: output.check_name,
          extension: output.extension,
          output: output.raw_output,
        )
      end

      Run.new(
        timestamp: timestamp,
        format: options.format,
        checks: check_classes.map(&:check_name),
        target_files: target.files,
        ruby_files: target.ruby_files,
        run_directory: artifacts.to_s,
        results: check_outputs.flat_map(&:results),
        artifacts: artifacts,
      )
    end

    private

    attr_reader :options, :command_runner, :clock, :check_registry

    def epoch_milliseconds
      (clock.now.to_r * 1_000).to_i
    end

    def run_checks(check_classes, ruby_files, timestamp)
      check_classes.map do |check_class|
        check_class.new(command_runner: command_runner, timestamp: timestamp).run(ruby_files)
      end
    end
  end
end
