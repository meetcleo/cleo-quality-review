# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/open_ai_config"

module CleoQualityReview
  class OpenAiConfigTest < Minitest::Test
    def test_reads_api_key_from_env
      config = OpenAiConfig.new(env: { "CLEO_QUALITY_REVIEW_OPEN_AI_KEY" => "secret" })

      assert_equal "CLEO_QUALITY_REVIEW_OPEN_AI_KEY", config.api_key_env
      assert_equal "secret", config.api_key
      assert_equal "gpt-5.5", config.model
      assert_predicate config, :configured?
    end

    def test_configured_returns_false_when_api_key_missing
      config = OpenAiConfig.new(env: {})

      assert_raises(KeyError) { config.api_key }
    end

    def test_configured_returns_false_when_api_key_blank
      config = OpenAiConfig.new(env: { "CLEO_QUALITY_REVIEW_OPEN_AI_KEY" => "  " })

      refute_predicate config, :configured?
    end
  end
end
