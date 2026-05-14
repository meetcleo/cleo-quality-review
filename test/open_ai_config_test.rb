# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/open_ai_config"

module CleoQualityReview
  class OpenAiConfigTest < Minitest::Test
    def test_defaults_to_requested_env_and_model
      config = OpenAiConfig.new(env: { "OPEN_AI_API_KEY" => "secret" })

      assert_equal "OPEN_AI_API_KEY", config.api_key_env
      assert_equal "secret", config.api_key
      assert_equal "gpt-5.5", config.model
      assert_equal true, config.configured?
    end

    def test_allows_env_and_model_overrides
      config = OpenAiConfig.new(
        env: {
          "CLEO_QUALITY_REVIEW_OPENAI_API_KEY_ENV" => "OPENAI_ACCESS_TOKEN",
          "OPENAI_ACCESS_TOKEN" => "repo-secret",
          "CLEO_QUALITY_REVIEW_OPENAI_MODEL" => "gpt-5.2",
        },
      )

      assert_equal "OPENAI_ACCESS_TOKEN", config.api_key_env
      assert_equal "repo-secret", config.api_key
      assert_equal "gpt-5.2", config.model
    end
  end
end
