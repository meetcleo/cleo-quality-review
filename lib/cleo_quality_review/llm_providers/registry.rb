# frozen_string_literal: true

require_relative "../llm_errors"

module CleoQualityReview
  module LlmProviders
    ##
    # Registry for available LLM provider implementations.
    class Registry
      class << self
        ##
        # Register an LLM provider implementation.
        # @param [String, Symbol] name provider identifier
        # @param [Class] provider_class provider class that responds to validate_config and build_client
        # @return [nil]
        def register(name, provider_class)
          providers[provider_name(name)] = provider_class
          nil
        end

        ##
        # Resolve a provider name to a provider instance.
        # @param [String, Symbol] name provider identifier
        # @return [Object] provider instance
        # @raise [UnsupportedLlmProviderError] if provider not found
        def fetch(name)
          providers.fetch(provider_name(name)).new
        rescue KeyError
          raise UnsupportedLlmProviderError, unsupported_provider_message(name)
        end

        ##
        # @return [Array<String>] registered provider names
        def registered
          providers.keys.sort
        end

        ##
        # @param [String, Symbol] name provider identifier
        # @return [Boolean]
        def registered?(name)
          providers.key?(provider_name(name))
        end

        private

        def provider_name(name)
          name.to_s.downcase
        end

        def unsupported_provider_message(name)
          "Unsupported LLM provider #{name.inspect}. Available: #{registered.join(', ')}"
        end

        def providers
          @providers ||= {}
        end
      end
    end
  end
end
