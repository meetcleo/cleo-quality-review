# frozen_string_literal: true

module CleoQualityReview
  class OpenAiConfig
    OPEN_AI_API_KEY = "CLEO_QUALITY_REVIEW_OPEN_AI_KEY"
    DEFAULT_MODEL = "gpt-5.5"

    attr_reader :env

    def initialize(env: ENV)
      @env = env
    end

    def api_key_env
      OPEN_AI_API_KEY
    end

    def api_key
      env.fetch(OPEN_AI_API_KEY)
    end

    def model = DEFAULT_MODEL

    def configured?
      api_key.to_s.strip != ""
    end
  end
end
