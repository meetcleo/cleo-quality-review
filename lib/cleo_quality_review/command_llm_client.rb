# frozen_string_literal: true

require "shellwords"

require_relative "command_runner"
require_relative "llm_errors"

module CleoQualityReview
  class CommandLlmClient
    def initialize(command:, command_runner: CommandRunner.new)
      @command = command.to_s
      @command_runner = command_runner
    end

    def generate_review(prompt)
      result = command_runner.run(*command_parts, stdin_data: prompt)
      raise LlmProviderError, command_error_message(result) unless result.success?

      result.stdout
    end

    private

    attr_reader :command, :command_runner

    def command_parts
      @command_parts ||= Shellwords.split(command).tap do |parts|
        raise MissingLlmConfigurationError, "Missing command for LLM provider \"command\"." if parts.empty?
      end
    end

    def command_error_message(result)
      "LLM command failed: #{result.stderr.to_s.strip}"
    end
  end
end
