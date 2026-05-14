# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/command_llm_client"

module CleoQualityReview
  class CommandLlmClientTest < Minitest::Test
    FakeCommandRunner = Struct.new(:received_command, :received_stdin, :result, keyword_init: true) do
      def run(*command, env: {}, stdin_data: nil)
        self.received_command = command
        self.received_stdin = stdin_data
        result
      end
    end

    def test_runs_command_with_prompt_on_stdin
      command_runner = FakeCommandRunner.new(result: command_result(stdout: "review"))
      client = CommandLlmClient.new(command: "llm --model local", command_runner: command_runner)

      assert_equal "review", client.generate_review("prompt")
      assert_equal ["llm", "--model", "local"], command_runner.received_command
      assert_equal "prompt", command_runner.received_stdin
    end

    def test_raises_when_command_fails
      command_runner = FakeCommandRunner.new(result: command_result(stderr: "failed", success: false))
      client = CommandLlmClient.new(command: "llm", command_runner: command_runner)

      error = assert_raises(LlmProviderError) do
        client.generate_review("prompt")
      end

      assert_includes error.message, "failed"
    end
  end
end
