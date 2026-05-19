# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/llm_config"

module CleoQualityReview
  class LlmConfigTest < Minitest::Test
    def test_provider_is_openai
      config = LlmConfig.new(env: {})

      assert_equal "openai", config.provider
    end

    def test_open_ai_config_reads_api_key
      config = LlmConfig.new(env: { "OPEN_AI_API_KEY" => "secret" })

      assert_equal "secret", config.open_ai_config.api_key
    end
  end
end
