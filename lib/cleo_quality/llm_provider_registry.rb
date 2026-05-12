# frozen_string_literal: true

require_relative "command_llm_client"
require_relative "llm_config"
require_relative "llm_errors"
require_relative "open_ai_client"
require_relative "open_ai_config"

module CleoQuality
  class LlmProviderRegistry
    def self.default
      @default ||= new(
        providers: {
          LlmConfig::OPENAI_PROVIDER => OpenAiLlmProvider.new,
          LlmConfig::COMMAND_PROVIDER => CommandLlmProvider.new,
        },
      )
    end

    def initialize(providers:)
      @providers = providers
    end

    def fetch(provider)
      providers.fetch(provider) do
        raise UnsupportedLlmProviderError, unsupported_provider_message(provider)
      end
    end

    private

    attr_reader :providers

    def unsupported_provider_message(provider)
      "Unsupported LLM provider #{provider.inspect}. Expected one of: #{providers.keys.sort.join(', ')}"
    end
  end

  class OpenAiLlmProvider
    def validate_config(config)
      return if config.open_ai_config.configured?

      raise MissingLlmConfigurationError, missing_configuration_message(config)
    end

    def build_client(config:, command_runner:)
      OpenAiClient.new(config: config.open_ai_config)
    end

    private

    def missing_configuration_message(config)
      "Missing OpenAI API key for LLM provider #{LlmConfig::OPENAI_PROVIDER.inspect}. Set " \
        "#{config.open_ai_config.api_key_env}, set #{OpenAiConfig::API_KEY_ENV_OVERRIDE} to the env var that contains the key, " \
        "or set #{LlmConfig::PROVIDER_ENV}=#{LlmConfig::COMMAND_PROVIDER} with #{LlmConfig::COMMAND_ENV}."
    end
  end

  class CommandLlmProvider
    def validate_config(config)
      return if config.command.to_s.strip != ""

      raise MissingLlmConfigurationError, "Missing command for LLM provider #{LlmConfig::COMMAND_PROVIDER.inspect}. Set #{LlmConfig::COMMAND_ENV}."
    end

    def build_client(config:, command_runner:)
      CommandLlmClient.new(command: config.command, command_runner: command_runner)
    end
  end
end
