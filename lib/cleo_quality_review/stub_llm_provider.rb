# frozen_string_literal: true

module CleoQualityReview
  ##
  # Configuration for stub LLM provider, mirrors OpenAiConfig interface
  class StubConfig
    DEFAULT_RESPONSE = "This is a stub review response for testing."

    class << self
      ##
      # Configure the response for all stub clients
      # @param [String, Proc] response fixed response or callable
      # @return [void]
      def response=(response)
        @response = response
      end

      ##
      # @return [String, Proc] the configured response
      def response
        @response || DEFAULT_RESPONSE
      end

      ##
      # Reset to default response
      # @return [void]
      def reset!
        @response = nil
      end
    end

    ##
    # @param [Hash{String => String}] env environment variables (unused, for interface compatibility)
    def initialize(env: ENV)
    end

    ##
    # @return [String] the configured response
    def response
      self.class.response
    end

    ##
    # @return [Boolean] always true for stub
    def configured?
      true
    end
  end

  ##
  # Stub LLM client for testing, mirrors OpenAiClient interface
  class StubLlmClient
    attr_reader :received_prompts

    ##
    # @param [StubConfig] config stub configuration
    def initialize(config:)
      @config = config
      @received_prompts = []
    end

    ##
    # Generate a review by returning the configured response
    # @param [String] prompt the prompt sent
    # @return [String] the configured response
    def generate_review(prompt)
      received_prompts << prompt
      response = config.response

      case response
      when Proc
        response.call(prompt)
      else
        response.to_s
      end
    end

    private

    attr_reader :config
  end

  ##
  # Stub LLM provider for testing without making HTTP requests
  class StubLlmProvider
    ##
    # Validate config - always passes for stub
    # @param [LlmConfig] config
    # @return [void]
    def validate_config(config)
    end

    ##
    # Build the stub client
    # @param [LlmConfig] config
    # @return [StubLlmClient]
    def build_client(config:)
      StubLlmClient.new(config: config.stub_config)
    end
  end
end
