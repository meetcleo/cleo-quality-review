# frozen_string_literal: true

require_relative "llm_errors"
require_relative "open_ai_client"
require_relative "open_ai_config"

module CleoQualityReview
  ##
  # Registry for LLM providers. Providers can be registered externally.
  #
  # @example Register a custom provider
  #   CleoQualityReview::LlmProviderRegistry.register(:custom, MyCustomProvider)
  #
  class LlmProviderRegistry
    class << self
      ##
      # Register a provider
      # @param [Symbol, String] name provider identifier
      # @param [Class] provider_class class that responds to validate_config and build_client
      # @return [void]
      def register(name, provider_class)
        providers[name.to_s.downcase] = provider_class
      end

      ##
      # Fetch a provider by name
      # @param [String] name provider identifier
      # @return [Object] the provider instance
      # @raise [UnsupportedLlmProviderError] if provider not found
      def fetch(name)
        key = name.to_s.downcase
        providers.fetch(key) do
          raise UnsupportedLlmProviderError, "Unsupported LLM provider #{name.inspect}. Available: #{providers.keys.sort.join(', ')}"
        end
      end

      ##
      # @return [Array<String>] registered provider names
      def registered
        providers.keys.sort
      end

      ##
      # Reset to default providers (useful for testing)
      # @return [void]
      def reset!
        @providers = nil
      end

      private

      def providers
        @providers ||= default_providers
      end

      def default_providers
        { "openai" => OpenAiLlmProvider.new }
      end
    end
  end

  ##
  # OpenAI provider implementation
  class OpenAiLlmProvider
    ##
    # Validate that the config has required OpenAI settings
    # @param [LlmConfig] config
    # @raise [MissingLlmConfigurationError] if not configured
    # @return [void]
    def validate_config(config)
      return if config.open_ai_config.configured?

      raise MissingLlmConfigurationError,
        "Missing OpenAI API key. Set #{config.open_ai_config.api_key_env} or #{OpenAiConfig::API_KEY_ENV_OVERRIDE}."
    end

    ##
    # Build the client instance
    # @param [LlmConfig] config
    # @param [CommandRunner] command_runner (unused, for interface compatibility)
    # @return [OpenAiClient]
    def build_client(config:, command_runner:)
      OpenAiClient.new(config: config.open_ai_config)
    end
  end
end
