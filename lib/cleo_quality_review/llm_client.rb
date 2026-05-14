# frozen_string_literal: true

require_relative "llm_config"
require_relative "llm_provider_registry"

module CleoQualityReview
  class LlmClient
    def initialize(config: LlmConfig.new, command_runner: CommandRunner.new, provider_registry: LlmProviderRegistry.default)
      @config = config
      @command_runner = command_runner
      @provider_registry = provider_registry
      provider.validate_config(config)
    end

    def generate_review(prompt)
      provider_client.generate_review(prompt)
    end

    private

    attr_reader :config, :command_runner, :provider_registry

    def provider_client
      provider.build_client(config: config, command_runner: command_runner)
    end

    def provider
      @provider ||= provider_registry.fetch(config.provider)
    end
  end
end
