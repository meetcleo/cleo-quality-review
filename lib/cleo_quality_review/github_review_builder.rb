# frozen_string_literal: true

require "json"

require_relative "diff_map"
require_relative "llm_errors"

module CleoQualityReview
  ##
  # Builds a GitHub pull request review payload from rendered pr_review JSON
  class GitHubReviewBuilder
    MAX_INLINE_COMMENTS = 20
    MAX_BODY_LENGTH = 3_500

    ##
    # @param [Run] run completed quality review run
    # @param [String] rendered_review JSON produced by the pr_review formatter
    def initialize(run:, rendered_review:)
      @run = run
      @rendered_review = rendered_review
      @diff_map = DiffMap.new(run.artifacts.changes_diff)
    end

    ##
    # @param [String, nil] commit_id pull request head SHA
    # @return [Hash] GitHub pull request review payload
    def payload(commit_id: nil)
      comments = inline_comments
      payload = {
        event: "COMMENT",
        body: review_body(comments),
      }
      payload[:commit_id] = commit_id if commit_id.to_s.strip != ""
      payload[:comments] = comments unless comments.empty?
      payload
    end

    ##
    # @return [String] hidden marker used to avoid duplicate reviews
    def marker
      "<!-- cleo-quality-review:#{run.review_id} -->"
    end

    ##
    # @return [Boolean] whether the rendered review contains anything useful to publish
    def empty?
      rendered_comments.empty?
    end

    private

    attr_reader :diff_map, :rendered_review, :run

    def inline_comments
      rendered_comments.first(MAX_INLINE_COMMENTS).filter_map do |comment|
        inline_comment_payload(normalized_comment(comment))
      end
    end

    def normalized_comment(comment)
      {
        path: comment["path"].to_s,
        line: comment["line"].to_i,
        body: comment["body"].to_s.strip,
      }
    end

    def inline_comment_payload(comment)
      return unless commentable?(comment)

      {
        path: comment.fetch(:path),
        line: comment.fetch(:line),
        side: "RIGHT",
        body: truncate(comment.fetch(:body)),
      }
    end

    def commentable?(comment)
      comment.fetch(:path) != "" &&
        comment.fetch(:line).positive? &&
        comment.fetch(:body) != "" &&
        diff_map.commentable?(comment.fetch(:path), comment.fetch(:line))
    end

    def rendered_comments
      comments = parsed_review.fetch("comments", [])
      raise Error, "pr_review JSON field \"comments\" must be an array" unless comments.is_a?(Array)

      comments
    end

    def parsed_review
      @parsed_review ||= begin
        parsed = JSON.parse(rendered_review.to_s)
        raise Error, "pr_review JSON must be an object" unless parsed.is_a?(Hash)

        parsed
      end
    rescue JSON::ParserError => e
      raise Error, "pr_review output was not valid JSON: #{e.message}"
    end

    def review_body(comments)
      [
        marker,
        body_text,
        inline_summary(comments),
      ].compact.join("\n\n")
    end

    def body_text
      parsed_review.fetch("body", "").to_s.strip
    end

    def inline_summary(comments)
      requested = rendered_comments.length
      return "No rendered comments mapped to commentable PR diff lines." if comments.empty? && requested.positive?
      return if requested == comments.length

      omitted = requested - comments.length
      "#{omitted} rendered comment#{'s' unless omitted == 1} were omitted because they did not map to commentable PR diff lines."
    end

    def truncate(value)
      return value if value.length <= MAX_BODY_LENGTH

      "#{value[0, MAX_BODY_LENGTH - 20]}\n\n[truncated]"
    end
  end
end
