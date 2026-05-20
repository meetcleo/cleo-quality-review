# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "llm_errors"

module CleoQualityReview
  ##
  # Value object representing an HTTP response from OpenAI
  #
  # @!attribute [r] status_code
  #   @return [Integer] HTTP status code
  # @!attribute [r] body
  #   @return [String] response body
  OpenAiHttpResponse = Struct.new(:status_code, :body, keyword_init: true) do
    ##
    # Check if the response indicates success
    # @return [Boolean]
    def success?
      (200..299).cover?(status_code.to_i)
    end
  end

  ##
  # Value object for a JSON POST request to OpenAI
  OpenAiHttpRequest = Struct.new(:uri, :headers, :body, :timeout_seconds, keyword_init: true)

  ##
  # HTTP transport layer for OpenAI API requests
  class OpenAiHttpTransport
    ##
    # Send a POST request with JSON body
    # @param [OpenAiHttpRequest] request JSON POST request options
    # @return [OpenAiHttpResponse]
    def post_json(request)
      http_request = build_request(request)
      response = perform_request(request, http_request)

      OpenAiHttpResponse.new(status_code: response.code.to_i, body: response.body.to_s)
    end

    private

    def build_request(request)
      http_request = Net::HTTP::Post.new(request.uri)
      request.headers.each { |key, value| http_request[key] = value }
      http_request.body = JSON.generate(request.body)
      http_request
    end

    def perform_request(request, http_request)
      uri = request.uri
      timeout_seconds = request.timeout_seconds

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        apply_timeouts(http, timeout_seconds)
        http.request(http_request)
      end
    end

    def apply_timeouts(http, timeout_seconds)
      http.open_timeout = timeout_seconds
      http.read_timeout = timeout_seconds
      http.write_timeout = timeout_seconds
    end
  end

  ##
  # Client for the OpenAI Responses API
  class OpenAiClient
    RESPONSES_API_URL = URI("https://api.openai.com/v1/responses")

    ##
    # @param [OpenAiConfig] config OpenAI configuration
    # @param [OpenAiHttpTransport] http_transport transport layer for HTTP requests
    def initialize(config:, http_transport: OpenAiHttpTransport.new)
      @config = config
      @http_transport = http_transport
    end

    ##
    # Generate a review using the OpenAI Responses API
    # @param [String] prompt the prompt to send
    # @return [String] generated review text
    # @raise [OpenAiApiError] if the API request fails
    def generate_review(prompt)
      timeout_seconds = config.timeout_seconds
      response = http_transport.post_json(build_request(prompt, timeout_seconds))
      raise OpenAiApiError, api_error_message(response) unless response.success?

      extract_text(JSON.parse(response.body))
    rescue JSON::ParserError => e
      raise OpenAiApiError, "OpenAI Responses API returned invalid JSON: #{e.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout => e
      raise OpenAiApiError, timeout_error_message(timeout_seconds, e)
    end

    private

    attr_reader :config, :http_transport

    def build_request(prompt, timeout_seconds)
      OpenAiHttpRequest.new(
        uri: RESPONSES_API_URL,
        headers: headers,
        body: { model: config.model, input: prompt },
        timeout_seconds: timeout_seconds,
      )
    end

    def timeout_error_message(timeout_seconds, error)
      "OpenAI Responses API request timed out after #{timeout_seconds} seconds: #{error.class}: #{error.message}"
    end

    def headers
      {
        "Authorization" => "Bearer #{config.api_key}",
        "Content-Type" => "application/json",
      }
    end

    def extract_text(response)
      output_text = response["output_text"]
      return output_text if output_text.to_s.strip != ""

      text = extract_content_text(response)
      return text unless text.empty?

      JSON.pretty_generate(response)
    end

    def extract_content_text(response)
      Array(response["output"]).flat_map { |item| extract_item_texts(item) }.join("\n")
    end

    def extract_item_texts(item)
      Array(item["content"]).filter_map { |content| content["text"] }
    end

    def api_error_message(response)
      "OpenAI Responses API request failed with status #{response.status_code}: #{response.body}"
    end
  end

  ##
  # Error raised when OpenAI API requests fail
  class OpenAiApiError < LlmProviderError; end
end
