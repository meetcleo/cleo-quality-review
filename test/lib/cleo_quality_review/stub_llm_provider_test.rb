# frozen_string_literal: true

require "test_helper"

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
      StubConfig.reset!
      provider = StubLlmProvider.new
      config = LlmConfig.new(env: {})
      client = provider.build_client(config: config, )

      result = client.generate_review("test prompt")

      assert_equal StubConfig::DEFAULT_RESPONSE, result
    end

    def test_client_returns_configured_response
      StubConfig.response = "custom response"
      provider = StubLlmProvider.new
      config = LlmConfig.new(env: {})
      client = provider.build_client(config: config, )

      result = client.generate_review("test prompt")

      assert_equal "custom response", result
    ensure
      StubConfig.reset!
    end

    def test_client_supports_proc_response
      StubConfig.response = ->(prompt) { "Received: #{prompt}" }
      provider = StubLlmProvider.new
      config = LlmConfig.new(env: {})
      client = provider.build_client(config: config, )

      result = client.generate_review("hello")

      assert_equal "Received: hello", result
    ensure
      StubConfig.reset!
    end

    def test_client_records_received_prompts
      StubConfig.reset!
      provider = StubLlmProvider.new
      config = LlmConfig.new(env: {})
      client = provider.build_client(config: config, )

      client.generate_review("first prompt")
      client.generate_review("second prompt")

      assert_equal ["first prompt", "second prompt"], client.received_prompts
    end

    def test_stub_config_is_always_configured
      config = StubConfig.new(env: {})

      assert_predicate config, :configured?
    end
  end
end
