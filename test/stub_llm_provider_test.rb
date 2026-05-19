# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/stub_llm_provider"
require "cleo_quality_review/llm_config"

module CleoQualityReview
  class StubLlmProviderTest < Minitest::Test
    def test_provider_is_registered_as_stub
      assert_includes LlmProviderRegistry.registered, "stub"
    end

    def test_validate_config_always_passes
      provider = StubLlmProvider.new
      config = LlmConfig.new(env: {})

      provider.validate_config(config)
    end

    def test_client_returns_default_response
      provider = StubLlmProvider.new
      StubLlmProvider.reset!
      client = provider.build_client(config: nil, command_runner: nil)

      result = client.generate_review("test prompt")

      assert_equal StubLlmProvider::DEFAULT_RESPONSE, result
    end

    def test_client_returns_configured_response
      provider = StubLlmProvider.new
      StubLlmProvider.response = "custom response"
      client = provider.build_client(config: nil, command_runner: nil)

      result = client.generate_review("test prompt")

      assert_equal "custom response", result
    ensure
      StubLlmProvider.reset!
    end

    def test_client_supports_proc_response
      provider = StubLlmProvider.new
      StubLlmProvider.response = ->(prompt) { "Received: #{prompt}" }
      client = provider.build_client(config: nil, command_runner: nil)

      result = client.generate_review("hello")

      assert_equal "Received: hello", result
    ensure
      StubLlmProvider.reset!
    end

    def test_client_records_received_prompts
      provider = StubLlmProvider.new
      StubLlmProvider.reset!
      client = provider.build_client(config: nil, command_runner: nil)

      client.generate_review("first prompt")
      client.generate_review("second prompt")

      assert_equal ["first prompt", "second prompt"], client.received_prompts
    end
  end
end
