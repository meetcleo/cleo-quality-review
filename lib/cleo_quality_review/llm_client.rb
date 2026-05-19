# frozen_string_literal: true

require_relative "llm_config"
require_relative "llm_logger"
require_relative "llm_provider_registry"

module CleoQualityReview
  ##
  # Client for generating LLM reviews using configured provider
  class LlmClient
    ##
    # @param [LlmConfig] config
    # @param [Boolean] log whether to log queries and responses
    def initialize(config: LlmConfig.new, log: false)
      @config = config
      @logger = LlmLogger.new(provider_name: config.provider, enabled: log)
      provider.validate_config(config)
    end

    ##
    # Generate a review from the given prompt
    # @param [String] prompt
    # @return [String] the generated review
    def generate_review(prompt)
      response = provider_client.generate_review(prompt)
      logger.log(query: prompt, response: response)
      response
    rescue StandardError => e
      logger.log(query: prompt, response: "ERROR: #{e.class}: #{e.message}")
      raise
    end

    private

    attr_reader :config, :logger

    def provider_client
      provider.build_client(config: config)
    end

    def provider
      @provider ||= LlmProviderRegistry.fetch(config.provider)
    end
  end
end
