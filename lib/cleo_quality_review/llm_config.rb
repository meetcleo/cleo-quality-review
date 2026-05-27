# frozen_string_literal: true

require_relative "llm_providers/open_ai_config"

module CleoQualityReview
  ##
  # Configuration for LLM provider
  class LlmConfig
    PROVIDER = "openai"

    ##
    # @param [Hash{String => String}] env environment variables
    def initialize(env: ENV)
      @env = env
    end

    ##
    # @return [String] the provider name
    def provider
      PROVIDER
    end

    ##
    # @return [LlmProviders::OpenAi::Config]
    def open_ai_config
      @open_ai_config ||= LlmProviders::OpenAi::Config.new(env: env)
    end

    ##
    # @return [LlmProviders::Stub::Config]
    def stub_config
      require_relative "llm_providers/stub"
      @stub_config ||= LlmProviders::Stub::Config.new(env: env)
    end

    private

    attr_reader :env
  end
end
