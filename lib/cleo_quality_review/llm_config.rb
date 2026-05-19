# frozen_string_literal: true

require_relative "open_ai_config"

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

    private

    attr_reader :env

    public

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

    ##
    # @return [StubConfig]
    def stub_config
      require_relative "stub_llm_provider"
      @stub_config ||= StubConfig.new(env: env)
    end
  end
end
