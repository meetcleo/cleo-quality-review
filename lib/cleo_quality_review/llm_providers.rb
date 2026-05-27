# frozen_string_literal: true

module CleoQualityReview
  ##
  # Namespace for bundled LLM provider implementations.
  module LlmProviders
    require_relative "llm_providers/registry"
    require_relative "llm_providers/open_ai"
    require_relative "llm_providers/stub"

    class << self
      ##
      # Register a new LLM provider for use.
      # @param [String, Symbol] provider_name
      # @param [Class] provider_class
      # @return [nil]
      def register(provider_name, provider_class)
        Registry.register(provider_name.to_s, provider_class)
      end

      ##
      # Resolve a registered LLM provider.
      # @param [String, Symbol] provider_name
      # @return [Object]
      def fetch(provider_name)
        Registry.fetch(provider_name.to_s)
      end

      ##
      # @return [Array<String>] registered provider names
      def registered
        Registry.registered
      end

      ##
      # Has a provider with the given name been registered?
      # @param [String, Symbol] provider_name
      # @return [Boolean]
      def registered?(provider_name)
        Registry.registered?(provider_name)
      end
    end
  end
end
