# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "github_review_builder"
require_relative "llm_errors"

module CleoQualityReview
  ##
  # Publishes quality review findings as a GitHub pull request review
  class GitHubReviewPublisher
    API_VERSION = "2022-11-28"

    ##
    # @param [Run] run completed quality review run
    # @param [String] rendered_review JSON produced by the pr_review formatter
    # @param [Hash{String => String}] env process environment
    def initialize(run:, rendered_review:, env: ENV)
      @run = run
      @rendered_review = rendered_review
      @env = env
    end

    ##
    # Publish the review, or skip when there is no PR context/findings
    # @return [String] status message
    def publish
      skip_reason = publication_skip_reason
      return skip_reason if skip_reason

      post_review
    end

    private

    def publication_skip_reason
      review_id = run.review_id
      return "No PR review comments to publish." if builder.empty?
      return "No pull_request event found; skipping PR review publication." unless pull_request_context?
      return "PR review already published for review ID #{review_id}; skipping." if already_published?

      nil
    end

    def post_review
      response = request_json(:post, reviews_uri, builder.payload(commit_id: head_sha))
      raise Error, "GitHub PR review publication failed with status #{response.status_code}: #{response.body}" unless response.success?

      "Published PR review for review ID #{run.review_id}."
    end

    GitHubResponse = Struct.new(:status_code, :body, keyword_init: true) do
      def success?
        (200..299).cover?(status_code.to_i)
      end
    end

    attr_reader :env, :rendered_review, :run

    def already_published?
      response = request_json(:get, reviews_uri)
      body = response.body
      raise Error, "GitHub PR review lookup failed with status #{response.status_code}: #{body}" unless response.success?

      JSON.parse(body).any? do |review|
        review.fetch("body", "").include?(builder.marker)
      end
    end

    def builder
      @builder ||= GitHubReviewBuilder.new(run: run, rendered_review: rendered_review)
    end

    def pull_request_context?
      event.fetch("pull_request", nil).is_a?(Hash)
    end

    def reviews_uri
      URI("#{api_url}/repos/#{repository}/pulls/#{pull_request_number}/reviews")
    end

    def pull_request_number
      event["number"] || event.fetch("pull_request").fetch("number")
    end

    def head_sha
      event.fetch("pull_request").fetch("head").fetch("sha")
    end

    def repository
      env.fetch("GITHUB_REPOSITORY")
    end

    def api_url
      env.fetch("GITHUB_API_URL", "https://api.github.com")
    end

    def event
      @event ||= JSON.parse(File.read(env.fetch("GITHUB_EVENT_PATH")))
    end

    def token
      env.fetch("GITHUB_TOKEN")
    end

    def request_json(method, uri, body = nil)
      wrap_response(perform_request(uri, build_request(method, uri, body)))
    end

    def build_request(method, uri, body)
      request = request_class(method).new(uri)
      apply_headers(request)
      request.body = JSON.generate(body) if body
      request
    end

    def request_class(method)
      {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
      }.fetch(method) { raise ArgumentError, "Unsupported HTTP method #{method.inspect}" }
    end

    def apply_headers(request)
      github_headers.each { |key, value| request[key] = value }
    end

    def github_headers
      {
        "Accept" => "application/vnd.github+json",
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json",
        "User-Agent" => "cleo-quality-review",
        "X-GitHub-Api-Version" => API_VERSION,
      }
    end

    def perform_request(uri, request)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
    end

    def wrap_response(response)
      GitHubResponse.new(status_code: response.code.to_i, body: response.body.to_s)
    end
  end
end
