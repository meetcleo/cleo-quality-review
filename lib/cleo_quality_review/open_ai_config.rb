# frozen_string_literal: true

module CleoQualityReview
  ##
  # Configuration for OpenAI API access
  class OpenAiConfig
    OPEN_AI_API_KEY = "CLEO_QUALITY_REVIEW_OPEN_AI_KEY"
    DEFAULT_MODEL = "gpt-5.5"

    ##
    # @param [Hash{String => String}] env environment variables
    def initialize(env: ENV)
      @env = env
    end

    ##
    # @return [String] environment variable name for the API key
    def api_key_env
      OPEN_AI_API_KEY
    end

    ##
    # @return [String] the OpenAI API key
    # @raise [KeyError] if the API key is not set
    def api_key
      env.fetch(OPEN_AI_API_KEY)
    end

    ##
    # @return [String] the model identifier to use
    def model = DEFAULT_MODEL

    ##
    # Check if the OpenAI configuration is complete
    # @return [Boolean]
    def configured?
      env.fetch(OPEN_AI_API_KEY, "").to_s.strip != ""
    end

    private

    attr_reader :env
  end
end
