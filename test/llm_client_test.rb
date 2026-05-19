# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/llm_client"

module CleoQualityReview
  class LlmClientTest < Minitest::Test
    def test_rejects_missing_openai_configuration
      config = LlmConfig.new(env: {})

      error = assert_raises(MissingLlmConfigurationError) do
        LlmClient.new(config: config)
      end

      assert_includes error.message, "Missing OpenAI API key"
    end
  end
end
