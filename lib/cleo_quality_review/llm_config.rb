# frozen_string_literal: true

require_relative "open_ai_config"

module CleoQualityReview
  ##
  # Configuration for LLM provider
  class LlmConfig
    PROVIDER = "openai"

    attr_reader :env

    ##
    # @param [Hash] env environment variables
    def initialize(env: ENV)
      @env = env
    end

    ##
    # @return [String] the provider name
    def provider
      PROVIDER
    end

    ##
    # @return [OpenAiConfig]
    def open_ai_config
      @open_ai_config ||= OpenAiConfig.new(env: env)
    end
  end
end
