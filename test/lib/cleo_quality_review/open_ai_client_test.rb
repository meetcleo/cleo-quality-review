# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/open_ai_client"

module CleoQualityReview
  class OpenAiClientTest < Minitest::Test
    FakeConfig = Struct.new(:api_key, :model, :timeout_seconds, keyword_init: true)
    FakeTransport = Struct.new(:response, :error, :received_uri, :received_headers, :received_body, :received_timeout_seconds, keyword_init: true) do
      def post_json(uri:, headers:, body:, timeout_seconds:)
        self.received_uri = uri
        self.received_headers = headers
        self.received_body = body
        self.received_timeout_seconds = timeout_seconds
        raise error if error

        response
      end
    end

    def test_calls_responses_api_and_extracts_output_text
      transport = FakeTransport.new(response: OpenAiHttpResponse.new(status_code: 200, body: JSON.generate("output_text" => "analysis")))
      client = OpenAiClient.new(
        config: FakeConfig.new(api_key: "secret", model: "gpt-5.5", timeout_seconds: 180),
        http_transport: transport,
      )

      assert_equal "analysis", client.generate_review("prompt")
      assert_equal URI("https://api.openai.com/v1/responses"), transport.received_uri
      assert_equal "Bearer secret", transport.received_headers.fetch("Authorization")
      assert_equal "application/json", transport.received_headers.fetch("Content-Type")
      assert_equal({ model: "gpt-5.5", input: "prompt" }, transport.received_body)
      assert_equal 180, transport.received_timeout_seconds
    end

    def test_http_transport_configures_net_http_timeouts
      fake_http = FakeHttp.new
      received = {}
      start = lambda do |hostname, port, use_ssl:, &block|
        received[:hostname] = hostname
        received[:port] = port
        received[:use_ssl] = use_ssl

        block.call(fake_http)
      end

      original_verbose = $VERBOSE
      $VERBOSE = nil
      Net::HTTP.singleton_class.alias_method(:start_without_timeout_test, :start)
      Net::HTTP.define_singleton_method(:start, &start)
      $VERBOSE = original_verbose

      begin
        response = OpenAiHttpTransport.new.post_json(
          uri: URI("https://api.openai.com/v1/responses"),
          headers: { "Content-Type" => "application/json" },
          body: { input: "prompt" },
          timeout_seconds: 180,
        )

        assert_equal 200, response.status_code
      ensure
        $VERBOSE = nil
        Net::HTTP.singleton_class.alias_method(:start, :start_without_timeout_test)
        Net::HTTP.singleton_class.remove_method(:start_without_timeout_test)
        $VERBOSE = original_verbose
      end

      assert_equal "api.openai.com", received[:hostname]
      assert_equal 443, received[:port]
      assert_equal true, received[:use_ssl]
      assert_equal 180, fake_http.open_timeout
      assert_equal 180, fake_http.read_timeout
      assert_equal 180, fake_http.write_timeout
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
        config: FakeConfig.new(api_key: "secret", model: "gpt-5.5", timeout_seconds: 180),
        http_transport: transport,
      )

      assert_equal "first\nsecond", client.generate_review("prompt")
    end

    def test_raises_clear_error_for_api_failure
      transport = FakeTransport.new(response: OpenAiHttpResponse.new(status_code: 401, body: "unauthorized"))
      client = OpenAiClient.new(
        config: FakeConfig.new(api_key: "secret", model: "gpt-5.5", timeout_seconds: 180),
        http_transport: transport,
      )

      error = assert_raises(OpenAiApiError) do
        client.generate_review("prompt")
      end

      assert_includes error.message, "status 401"
      assert_includes error.message, "unauthorized"
    end

    def test_wraps_net_timeout_errors
      transport = FakeTransport.new(error: Net::ReadTimeout.new("request timed out"))
      client = OpenAiClient.new(
        config: FakeConfig.new(api_key: "secret", model: "gpt-5.5", timeout_seconds: 180),
        http_transport: transport,
      )

      error = assert_raises(OpenAiApiError) do
        client.generate_review("prompt")
      end

      assert_includes error.message, "timed out after 180 seconds"
      assert_includes error.message, "Net::ReadTimeout"
    end

    class FakeHttp
      attr_accessor :open_timeout, :read_timeout, :write_timeout

      def request(_request)
        Struct.new(:code, :body).new("200", JSON.generate("output_text" => "ok"))
      end
    end
  end
end
