# frozen_string_literal: true

require "open3"

require_relative "command_result"

module CleoQualityReview
  ##
  # Executes shell commands and captures output
  class CommandRunner
    ##
    # Run a shell command and capture its output
    # @param [Array<String>] command command and arguments to execute
    # @param [Hash{String => String}] env environment variables
    # @param [String, nil] stdin_data data to pipe to stdin
    # @return [CommandResult]
    def run(*command, env: {}, stdin_data: nil)
      stdout, stderr, status = if stdin_data.nil?
        Open3.capture3(env, *command)
      else
        Open3.capture3(env, *command, stdin_data: stdin_data)
      end

      CommandResult.new(stdout: stdout, stderr: stderr, status: status)
    end
  end
end
