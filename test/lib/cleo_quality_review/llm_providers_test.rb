# frozen_string_literal: true

require "test_helper"

module CleoQualityReview
  class LlmProvidersTest < Minitest::Test
    class CustomProvider
    end

    def setup
      @original_providers = CleoQualityReview::LlmProviders::Registry.instance_variable_get(:@providers)
      CleoQualityReview::LlmProviders::Registry.instance_variable_set(:@providers, {})
    end

    def teardown
      CleoQualityReview::LlmProviders::Registry.instance_variable_set(:@providers, @original_providers)
    end

    def test_register_and_fetch_go_through_module
      refute CleoQualityReview::LlmProviders.registered?("custom")

      CleoQualityReview::LlmProviders.register("Custom", CustomProvider)

      assert CleoQualityReview::LlmProviders.registered?("custom")
      assert_instance_of CustomProvider, CleoQualityReview::LlmProviders.fetch("custom")
    end

    def test_fetch_rejects_unknown_provider
      CleoQualityReview::LlmProviders.register("Custom", CustomProvider)

      error = assert_raises(UnsupportedLlmProviderError) do
        CleoQualityReview::LlmProviders.fetch("missing")
      end

      assert_includes error.message, "Unsupported LLM provider"
      assert_includes error.message, "custom"
    end
  end
end
