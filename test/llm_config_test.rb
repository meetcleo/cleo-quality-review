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

    def test_explicit_provider_overrides_default
      config = LlmConfig.new(
        env: {
          "CLEO_QUALITY_REVIEW_LLM_PROVIDER" => "custom",
        },
      )

      assert_equal "custom", config.provider
    end

    def test_provider_is_lowercased
      config = LlmConfig.new(
        env: {
          "CLEO_QUALITY_REVIEW_LLM_PROVIDER" => "OpenAI",
        },
      )

      assert_equal "openai", config.provider
    end
  end
end
