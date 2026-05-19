# frozen_string_literal: true

require_relative "llm_config"
require_relative "llm_provider_registry"

module CleoQualityReview
  ##
  # Client for generating LLM reviews using configured provider
  class LlmClient
    ##
    # @param [LlmConfig] config
    def initialize(config: LlmConfig.new)
      @config = config
      provider.validate_config(config)
    end

    ##
    # Generate a review from the given prompt
    # @param [String] prompt
    # @return [String] the generated review
    def generate_review(prompt)
      provider_client.generate_review(prompt)
    end

    private

    attr_reader :config

    def provider_client
      provider.build_client(config: config)
    end

    def provider
      @provider ||= LlmProviderRegistry.fetch(config.provider)
    end
  end
end
