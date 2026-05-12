# frozen_string_literal: true

module CleoQuality
  class OpenAiConfig
    DEFAULT_API_KEY_ENV = "OPEN_AI_API_KEY"
    API_KEY_ENV_OVERRIDE = "CLEO_QUALITY_OPENAI_API_KEY_ENV"
    DEFAULT_MODEL = "gpt-5.5"
    MODEL_OVERRIDE = "CLEO_QUALITY_OPENAI_MODEL"

    attr_reader :env

    def initialize(env: ENV)
      @env = env
    end

    def api_key_env
      env.fetch(API_KEY_ENV_OVERRIDE, DEFAULT_API_KEY_ENV).then do |value|
        value.to_s.empty? ? DEFAULT_API_KEY_ENV : value
      end
    end

    def api_key
      env.fetch(api_key_env, nil)
    end

    def model
      env.fetch(MODEL_OVERRIDE, DEFAULT_MODEL).then do |value|
        value.to_s.empty? ? DEFAULT_MODEL : value
      end
    end

    def configured?
      api_key.to_s.strip != ""
    end
  end
end
