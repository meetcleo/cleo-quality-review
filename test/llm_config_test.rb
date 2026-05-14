# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/llm_config"

module CleoQualityReview
  class LlmConfigTest < Minitest::Test
    def test_defaults_to_openai_provider
      config = LlmConfig.new(env: { "OPEN_AI_API_KEY" => "secret" })

      assert_equal "openai", config.provider
      assert_equal "secret", config.open_ai_config.api_key
    end

    def test_uses_command_provider_when_command_is_configured_without_explicit_provider
      config = LlmConfig.new(env: { "CLEO_QUALITY_REVIEW_LLM_COMMAND" => "llm prompt" })

      assert_equal "command", config.provider
      assert_equal "llm prompt", config.command
    end

    def test_explicit_provider_takes_precedence
      config = LlmConfig.new(
        env: {
          "CLEO_QUALITY_REVIEW_LLM_PROVIDER" => "openai",
          "CLEO_QUALITY_REVIEW_LLM_COMMAND" => "llm prompt",
        },
      )

      assert_equal "openai", config.provider
    end
  end
end
