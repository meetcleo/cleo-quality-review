# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/open_ai_client"

module CleoQualityReview
  class OpenAiClientTest < Minitest::Test
    FakeConfig = Struct.new(:api_key, :model, keyword_init: true)
    FakeTransport = Struct.new(:response, :received_uri, :received_headers, :received_body, keyword_init: true) do
      def post_json(uri:, headers:, body:)
        self.received_uri = uri
        self.received_headers = headers
        self.received_body = body
        response
      end
    end

    def test_calls_responses_api_and_extracts_output_text
      transport = FakeTransport.new(response: OpenAiHttpResponse.new(status_code: 200, body: JSON.generate("output_text" => "analysis")))
      client = OpenAiClient.new(
        config: FakeConfig.new(api_key: "secret", model: "gpt-5.5"),
        http_transport: transport,
      )

      assert_equal "analysis", client.generate_review("prompt")
      assert_equal URI("https://api.openai.com/v1/responses"), transport.received_uri
      assert_equal "Bearer secret", transport.received_headers.fetch("Authorization")
      assert_equal "application/json", transport.received_headers.fetch("Content-Type")
      assert_equal({ model: "gpt-5.5", input: "prompt" }, transport.received_body)
    end

    def test_extracts_nested_response_text
      response = {
        "output" => [
          {
            "content" => [
              { "text" => "first" },
              { "text" => "second" },
            ],
          },
        ],
      }
      transport = FakeTransport.new(response: OpenAiHttpResponse.new(status_code: 200, body: JSON.generate(response)))
      client = OpenAiClient.new(
        config: FakeConfig.new(api_key: "secret", model: "gpt-5.5"),
        http_transport: transport,
      )

      assert_equal "first\nsecond", client.generate_review("prompt")
    end

    def test_raises_clear_error_for_api_failure
      transport = FakeTransport.new(response: OpenAiHttpResponse.new(status_code: 401, body: "unauthorized"))
      client = OpenAiClient.new(
        config: FakeConfig.new(api_key: "secret", model: "gpt-5.5"),
        http_transport: transport,
      )

      error = assert_raises(OpenAiApiError) do
        client.generate_review("prompt")
      end

      assert_includes error.message, "status 401"
      assert_includes error.message, "unauthorized"
    end
  end
end
