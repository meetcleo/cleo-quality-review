# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/open_ai_client"

module CleoQualityReview
  class OpenAiClientTest < Minitest::Test
    FakeConfig = Struct.new(:api_key, :model, :timeout_seconds, keyword_init: true)
    FakeTransport = Struct.new(:response, :error, :received_request, keyword_init: true) do
      def post_json(request)
        self.received_request = request
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
      assert_responses_api_request(transport.received_request)
    end

    def test_http_transport_configures_net_http_timeouts
      fake_http = FakeHttp.new
      received = {}
      http_start = lambda do |hostname, port, use_ssl:, &block|
        received[:hostname] = hostname
        received[:port] = port
        received[:use_ssl] = use_ssl

        block.call(fake_http)
      end

      response = with_stubbed_net_http_start(http_start) do
        OpenAiHttpTransport.new.post_json(
          OpenAiHttpRequest.new(
            uri: URI("https://api.openai.com/v1/responses"),
            headers: { "Content-Type" => "application/json" },
            body: { input: "prompt" },
            timeout_seconds: 180,
          ),
        )
      end

      assert_equal 200, response.status_code
      assert_http_start(received)
      assert_http_timeouts(fake_http)
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

    private

    def assert_responses_api_request(request)
      headers = request.headers

      assert_equal URI("https://api.openai.com/v1/responses"), request.uri
      assert_equal "Bearer secret", headers.fetch("Authorization")
      assert_equal "application/json", headers.fetch("Content-Type")
      assert_equal({ model: "gpt-5.5", input: "prompt" }, request.body)
      assert_equal 180, request.timeout_seconds
    end

    def assert_http_start(received)
      assert_equal "api.openai.com", received[:hostname]
      assert_equal 443, received[:port]
      assert_equal true, received[:use_ssl]
    end

    def assert_http_timeouts(fake_http)
      assert_equal 180, fake_http.open_timeout
      assert_equal 180, fake_http.read_timeout
      assert_equal 180, fake_http.write_timeout
    end

    def with_stubbed_net_http_start(http_start)
      original_verbose = $VERBOSE
      $VERBOSE = nil
      Net::HTTP.singleton_class.alias_method(:start_without_timeout_test, :start)
      Net::HTTP.define_singleton_method(:start, &http_start)
      $VERBOSE = original_verbose

      yield
    ensure
      $VERBOSE = nil
      Net::HTTP.singleton_class.alias_method(:start, :start_without_timeout_test)
      Net::HTTP.singleton_class.remove_method(:start_without_timeout_test)
      $VERBOSE = original_verbose
    end

    class FakeHttp
      attr_accessor :open_timeout, :read_timeout, :write_timeout

      def request(_request)
        Struct.new(:code, :body).new("200", JSON.generate("output_text" => "ok"))
      end
    end
  end
end
