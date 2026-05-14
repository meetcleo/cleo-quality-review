# frozen_string_literal: true

require_relative "open_ai_config"

module CleoQualityReview
  class LlmConfig
    PROVIDER_ENV = "CLEO_QUALITY_REVIEW_LLM_PROVIDER"
    COMMAND_ENV = "CLEO_QUALITY_REVIEW_LLM_COMMAND"
    OPENAI_PROVIDER = "openai"
    COMMAND_PROVIDER = "command"
    PROVIDERS = [OPENAI_PROVIDER, COMMAND_PROVIDER].freeze

    attr_reader :env

    def initialize(env: ENV)
      @env = env
    end

    def provider
      configured_provider = env.fetch(PROVIDER_ENV, nil).to_s.strip
      return configured_provider.downcase unless configured_provider.empty?

      return COMMAND_PROVIDER if command.to_s.strip != ""

      OPENAI_PROVIDER
    end

    def command
      env.fetch(COMMAND_ENV, nil)
    end

    def open_ai_config
      @open_ai_config ||= OpenAiConfig.new(env: env)
    end
  end
end
