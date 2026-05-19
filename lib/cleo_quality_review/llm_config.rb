# frozen_string_literal: true

require_relative "open_ai_config"

module CleoQualityReview
  ##
  # Configuration for LLM providers
  class LlmConfig
    PROVIDER_ENV = "CLEO_QUALITY_REVIEW_LLM_PROVIDER"
    DEFAULT_PROVIDER = "openai"

    attr_reader :env

    ##
    # @param [Hash] env environment variables
    def initialize(env: ENV)
      @env = env
    end

    ##
    # @return [String] the configured provider name
    def provider
      configured = env.fetch(PROVIDER_ENV, nil).to_s.strip
      configured.empty? ? DEFAULT_PROVIDER : configured.downcase
    end

    ##
    # @return [OpenAiConfig]
    def open_ai_config
      @open_ai_config ||= OpenAiConfig.new(env: env)
    end
  end
end
