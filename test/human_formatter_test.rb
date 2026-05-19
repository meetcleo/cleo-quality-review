# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/formatters/human"
require "cleo_quality_review/llm_config"
require "cleo_quality_review/run"

module CleoQualityReview
  module Formatters
    class HumanTest < Minitest::Test
      FakeLlmClient = Struct.new(:received_prompt, keyword_init: true) do
        def generate_review(prompt)
          self.received_prompt = prompt
          "review"
        end
      end

      def test_uses_configured_llm_client
        in_tmpdir do
          FileUtils.mkdir_p("tmp/quality_checks/123/reek")
          File.write("tmp/quality_checks/123/changes.diff", "diff")
          File.write("tmp/quality_checks/123/reek/raw_output.json", "[]")
          llm_client = FakeLlmClient.new
          run = Run.new(timestamp: 123, target_files: [], checks: ["reek"])

          output = Human.new(run: run, command_runner: nil, llm_client: llm_client).format

          assert_equal "review", output
          assert_includes llm_client.received_prompt, "Raw reek output"
        end
      end

      def test_fails_clearly_when_llm_is_missing
        run = Run.new(timestamp: 123, target_files: [], checks: [])
        config = LlmConfig.new(env: {})

        error = assert_raises(MissingLlmConfigurationError) do
          Human.new(run: run, command_runner: nil, llm_config: config).format
        end

        assert_includes error.message, "Missing OpenAI API key"
        assert_includes error.message, "OPEN_AI_API_KEY"
      end
    end
  end
end
