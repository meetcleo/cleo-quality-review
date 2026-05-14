# frozen_string_literal: true

require "rbconfig"

require_relative "../result"

module CleoQualityReview
  module Checks
    class QualityCheck
      class << self
        attr_accessor :check_name, :tool, :output_extension

        def inherited(subclass)
          super
          subclass.output_extension = "txt"
        end
      end

      def initialize(command_runner:, timestamp:)
        @command_runner = command_runner
        @timestamp = timestamp
      end

      def run(files)
        return empty_output if files.empty?

        command_result = command_runner.run(*command(files))

        CheckOutput.new(
          check_name: self.class.check_name,
          extension: self.class.output_extension,
          raw_output: raw_output(command_result),
          results: parse(command_result.stdout, parseable_stderr(command_result)),
        )
      end

      private

      attr_reader :command_runner, :timestamp

      def empty_output
        CheckOutput.new(
          check_name: self.class.check_name,
          extension: self.class.output_extension,
          raw_output: "",
          results: [],
        )
      end

      def ruby_executable
        RbConfig.ruby
      end

      def gem_executable(gem_name, executable_name)
        Gem.bin_path(gem_name, executable_name)
      end

      def raw_output(command_result)
        return command_result.stdout if command_result.success?
        return command_result.stdout if command_result.stderr.empty?

        [command_result.stdout, command_result.stderr].reject(&:empty?).join("\n")
      end

      def parseable_stderr(command_result)
        command_result.success? ? "" : command_result.stderr
      end

      def result(check:, message:, filepath:, line: nil)
        CleoQualityReview::Result.new(
          tool: self.class.tool,
          check: check,
          timestamp: timestamp,
          result: message,
          filepath: filepath,
          line: line&.to_i,
        )
      end
    end

    CheckOutput = Struct.new(:check_name, :extension, :raw_output, :results, keyword_init: true)
  end
end
