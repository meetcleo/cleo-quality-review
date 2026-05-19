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
  # HTTP transport layer for OpenAI API requests
  class OpenAiHttpTransport
    ##
    # Send a POST request with JSON body
    # @param [URI] uri the request URI
    # @param [Hash{String => String}] headers HTTP headers
    # @param [Hash] body request body to be serialized as JSON
    # @param [Integer] timeout_seconds HTTP timeout in seconds
    # @return [OpenAiHttpResponse]
    def post_json(uri:, headers:, body:, timeout_seconds:)
      request = Net::HTTP::Post.new(uri)
      headers.each { |key, value| request[key] = value }
      request.body = JSON.generate(body)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.open_timeout = timeout_seconds
        http.read_timeout = timeout_seconds
        http.write_timeout = timeout_seconds

        http.request(request)
      end

      OpenAiHttpResponse.new(status_code: response.code.to_i, body: response.body.to_s)
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
      response = http_transport.post_json(
        uri: RESPONSES_API_URL,
        headers: headers,
        body: {
          model: config.model,
          input: prompt,
        },
        timeout_seconds: timeout_seconds,
      )
      raise OpenAiApiError, api_error_message(response) unless response.success?

      extract_text(JSON.parse(response.body))
    rescue JSON::ParserError => e
      raise OpenAiApiError, "OpenAI Responses API returned invalid JSON: #{e.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout => e
      raise OpenAiApiError,
        "OpenAI Responses API request timed out after #{timeout_seconds} seconds: #{e.class}: #{e.message}"
    end

    private

    attr_reader :config, :http_transport

    def headers
      {
        "Authorization" => "Bearer #{config.api_key}",
        "Content-Type" => "application/json",
      }
    end

    def extract_text(response)
      return response["output_text"] if response["output_text"].to_s.strip != ""

      text = Array(response["output"]).flat_map do |item|
        Array(item["content"]).filter_map { |content| content["text"] }
      end.join("\n")

      return text unless text.empty?

      JSON.pretty_generate(response)
    end

    def api_error_message(response)
      "OpenAI Responses API request failed with status #{response.status_code}: #{response.body}"
    end
  end

  ##
  # Error raised when OpenAI API requests fail
  class OpenAiApiError < LlmProviderError; end
end
