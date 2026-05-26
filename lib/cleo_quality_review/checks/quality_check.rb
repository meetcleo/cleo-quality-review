# frozen_string_literal: true

require "rbconfig"

require_relative "../result"

module CleoQualityReview
  module Checks
    ##
    # Base class for quality check implementations
    class QualityCheck
      class << self
        ##
        # @!attribute [rw] check_name
        #   @return [String] identifier for this check
        attr_accessor :check_name

        # @!attribute [rw] tool_name
        #   @return [String] tool name for result attribution
        attr_accessor :tool_name

        # @!attribute [rw] tool_type
        #   @return [String] category for this tool's findings
        attr_accessor :tool_type

        # @!attribute [rw] output_extension
        #   @return [String] file extension for raw output
        attr_accessor :output_extension

        ##
        # Set default output extension for subclasses
        # @param [Class] subclass the inheriting class
        # @return [void]
        def inherited(subclass)
          super
          subclass.output_extension = "txt"
        end
      end

      ##
      # @param [CommandRunner] command_runner for executing shell commands
      # @param [Integer] timestamp epoch milliseconds for the run
      def initialize(command_runner:, timestamp:)
        @command_runner = command_runner
        @timestamp = timestamp
      end

      ##
      # Run the quality check on the given files
      # @param [Array<String>] files file paths to analyze
      # @return [CheckOutput]
      def run(files)
        return empty_output if files.empty?

        command_result = command_runner.run(*command(files))
        build_output(
          raw_output: raw_output(command_result),
          results: parse(command_result.stdout, parseable_stderr(command_result)),
        )
      end

      private

      attr_reader :command_runner, :timestamp

      def check_metadata
        @check_metadata ||= begin
          klass = self.class
          [klass.check_name, klass.output_extension, klass.tool_name, klass.tool_type]
        end
      end

      def empty_output
        build_output(raw_output: "", results: [])
      end

      def build_output(raw_output:, results:)
        check_name, extension, tool_name, tool_type = check_metadata
        CheckOutput.new(
          check_name: check_name,
          tool_name: tool_name,
          tool_type: tool_type,
          extension: extension,
          raw_output: raw_output,
          results: results,
        )
      end

      def ruby_executable
        RbConfig.ruby
      end

      def gem_executable(gem_name, executable_name)
        Gem.bin_path(gem_name, executable_name)
      end

      def raw_output(command_result)
        stdout = command_result.stdout
        return stdout if command_result.success?

        stderr = command_result.stderr
        return stdout if stderr.empty?

        [stdout, stderr].reject(&:empty?).join("\n")
      end

      def parseable_stderr(command_result)
        command_result.success? ? "" : command_result.stderr
      end

      def result(check:, message:, filepath:, line: nil)
        _check_name, _extension, tool_name, tool_type = check_metadata
        CleoQualityReview::Result.new(
          tool_name: tool_name,
          tool_type: tool_type,
          check: check,
          timestamp: timestamp,
          result: message,
          filepath: filepath,
          line: line&.to_i,
        )
      end
    end

    ##
    # Value object containing check output and parsed results
    #
    # @!attribute [r] check_name
    #   @return [String] identifier for the check
    # @!attribute [r] tool_name
    #   @return [String] name of the concrete tool
    # @!attribute [r] tool_type
    #   @return [String] category for this tool's findings
    # @!attribute [r] extension
    #   @return [String] file extension for the raw output
    # @!attribute [r] raw_output
    #   @return [String] raw tool output
    # @!attribute [r] results
    #   @return [Array<Result>] parsed findings
    CheckOutput = Struct.new(:check_name, :tool_name, :tool_type, :extension, :raw_output, :results, keyword_init: true)
  end
end
