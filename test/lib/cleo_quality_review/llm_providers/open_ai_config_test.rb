# frozen_string_literal: true

require_relative "../../../test_helper"
require "cleo_quality_review/llm_providers/open_ai_config"

module CleoQualityReview
  module LlmProviders
    module OpenAi
      class ConfigTest < Minitest::Test
        def test_reads_api_key_from_env
          config = config_with_key

          assert_equal "CLEO_QUALITY_REVIEW_OPEN_AI_KEY", config.api_key_env
          assert_equal "secret", config.api_key
        end

        def test_defaults_model_and_timeout
          config = config_with_key

          assert_equal "gpt-5.5", config.model
          assert_equal 180, config.timeout_seconds
        end

        def test_exposes_timeout_env_name
          assert_equal "CLEO_QUALITY_REVIEW_TIMEOUT_SECONDS", config_with_key.timeout_seconds_env
        end

        def test_configured_returns_true_when_api_key_present
          config = config_with_key

          assert_predicate config, :configured?
        end

        def test_reads_timeout_seconds_from_env
          config = Config.new(
            env: {
              "CLEO_QUALITY_REVIEW_OPEN_AI_KEY" => "secret",
              "CLEO_QUALITY_REVIEW_TIMEOUT_SECONDS" => "240",
            },
          )

          assert_equal 240, config.timeout_seconds
        end

        def test_rejects_invalid_timeout_seconds
          config = Config.new(
            env: {
              "CLEO_QUALITY_REVIEW_OPEN_AI_KEY" => "secret",
              "CLEO_QUALITY_REVIEW_TIMEOUT_SECONDS" => "0",
            },
          )

          error = assert_raises(ArgumentError) { config.timeout_seconds }

          assert_includes error.message, "CLEO_QUALITY_REVIEW_TIMEOUT_SECONDS"
          assert_includes error.message, "positive integer"
        end

        def test_configured_returns_false_when_api_key_missing
          config = Config.new(env: {})

          assert_raises(KeyError) { config.api_key }
        end

        def test_configured_returns_false_when_api_key_blank
          config = Config.new(env: { "CLEO_QUALITY_REVIEW_OPEN_AI_KEY" => "  " })

          refute_predicate config, :configured?
        end

        private

        def config_with_key
          Config.new(env: { "CLEO_QUALITY_REVIEW_OPEN_AI_KEY" => "secret" })
        end
      end
    end
  end
end
