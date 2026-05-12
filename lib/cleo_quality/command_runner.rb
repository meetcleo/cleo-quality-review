# frozen_string_literal: true

require "open3"

require_relative "command_result"

module CleoQuality
  class CommandRunner
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
