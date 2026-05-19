# frozen_string_literal: true

module CleoQualityReview
  ##
  # Stub LLM client for testing that returns configured responses
  class StubLlmClient
    attr_reader :received_prompts

    ##
    # @param [String, Proc] response fixed response or callable that receives the prompt
    def initialize(response:)
      @response = response
      @received_prompts = []
    end

    ##
    # Generate a review by returning the configured response
    # @param [String] prompt the prompt sent
    # @return [String] the configured response
    def generate_review(prompt)
      received_prompts << prompt

      case response
      when Proc
        response.call(prompt)
      else
        response.to_s
      end
    end

    private

    attr_reader :response
  end

  ##
  # Stub LLM provider for testing without making HTTP requests
  class StubLlmProvider
    DEFAULT_RESPONSE = "This is a stub review response for testing."

    class << self
      ##
      # Configure the response for the stub client
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
    # Validate config - always passes for stub
    # @param [LlmConfig] config
    # @return [void]
    def validate_config(config)
    end

    ##
    # Build the stub client
    # @param [LlmConfig] config
    # @param [CommandRunner] command_runner
    # @return [StubLlmClient]
    def build_client(config:, command_runner:)
      StubLlmClient.new(response: self.class.response)
    end
  end
end
