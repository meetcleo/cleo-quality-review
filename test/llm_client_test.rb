# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/llm_client"

module CleoQualityReview
  class LlmClientTest < Minitest::Test
    FakeProvider = Struct.new(:validated_config, keyword_init: true) do
      def validate_config(config)
        self.validated_config = config
      end

      def build_client(config:, command_runner:)
        FakeClient.new
      end
    end

    class FakeClient
      def generate_review(prompt)
        "fake review for #{prompt}"
      end
    end

    def test_supports_registered_provider
      provider = FakeProvider.new
      LlmProviderRegistry.register("fake", provider)
      config = LlmConfig.new(env: { "CLEO_QUALITY_REVIEW_LLM_PROVIDER" => "fake" })

      output = LlmClient.new(config: config).generate_review("prompt")

      assert_equal config, provider.validated_config
      assert_equal "fake review for prompt", output
    ensure
      LlmProviderRegistry.reset!
    end

    def test_rejects_unregistered_provider
      config = LlmConfig.new(env: { "CLEO_QUALITY_REVIEW_LLM_PROVIDER" => "missing" })

      error = assert_raises(UnsupportedLlmProviderError) do
        LlmClient.new(config: config)
      end

      assert_includes error.message, "Unsupported LLM provider"
    end

    def test_rejects_missing_openai_configuration
      config = LlmConfig.new(env: { "CLEO_QUALITY_REVIEW_LLM_PROVIDER" => "openai" })

      error = assert_raises(MissingLlmConfigurationError) do
        LlmClient.new(config: config)
      end

      assert_includes error.message, "Missing OpenAI API key"
    end
  end
end
