# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "llm_errors"

module CleoQualityReview
  OpenAiHttpResponse = Struct.new(:status_code, :body, keyword_init: true) do
    def success?
      (200..299).cover?(status_code.to_i)
    end
  end

  class OpenAiHttpTransport
    def post_json(uri:, headers:, body:)
      request = Net::HTTP::Post.new(uri)
      headers.each { |key, value| request[key] = value }
      request.body = JSON.generate(body)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      OpenAiHttpResponse.new(status_code: response.code.to_i, body: response.body.to_s)
    end
  end

  class OpenAiClient
    RESPONSES_API_URL = URI("https://api.openai.com/v1/responses")

    def initialize(config:, http_transport: OpenAiHttpTransport.new)
      @config = config
      @http_transport = http_transport
    end

    def generate_review(prompt)
      response = http_transport.post_json(
        uri: RESPONSES_API_URL,
        headers: headers,
        body: {
          model: config.model,
          input: prompt,
        },
      )
      raise OpenAiApiError, api_error_message(response) unless response.success?

      extract_text(JSON.parse(response.body))
    rescue JSON::ParserError => e
      raise OpenAiApiError, "OpenAI Responses API returned invalid JSON: #{e.message}"
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

  class OpenAiApiError < LlmProviderError; end
end
