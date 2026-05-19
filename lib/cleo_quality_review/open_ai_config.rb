# frozen_string_literal: true

module CleoQualityReview
  ##
  # Configuration for OpenAI API access
  class OpenAiConfig
    OPEN_AI_API_KEY = "CLEO_QUALITY_REVIEW_OPEN_AI_KEY"
    TIMEOUT_SECONDS = "CLEO_QUALITY_REVIEW_TIMEOUT_SECONDS"
    DEFAULT_MODEL = "gpt-5.5"
    DEFAULT_TIMEOUT_SECONDS = 180

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
    # @return [String] environment variable name for the request timeout
    def timeout_seconds_env
      TIMEOUT_SECONDS
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
    # @return [Integer] timeout in seconds for OpenAI HTTP requests
    # @raise [ArgumentError] if the configured timeout is not a positive integer
    def timeout_seconds
      value = env.fetch(TIMEOUT_SECONDS, "").to_s.strip
      return DEFAULT_TIMEOUT_SECONDS if value.empty?

      Integer(value, 10).tap do |seconds|
        raise ArgumentError if seconds <= 0
      end
    rescue ArgumentError
      raise ArgumentError, "#{TIMEOUT_SECONDS} must be a positive integer number of seconds"
    end

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
