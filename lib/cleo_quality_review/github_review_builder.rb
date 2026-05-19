# frozen_string_literal: true

require_relative "diff_map"

module CleoQualityReview
  ##
  # Builds a GitHub pull request review payload from normalized findings
  class GitHubReviewBuilder
    MAX_INLINE_COMMENTS = 20
    MAX_BODY_LENGTH = 3_500

    ##
    # @param [Run] run completed quality review run
    def initialize(run:)
      @run = run
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

    private

    attr_reader :diff_map, :run

    def inline_comments
      commentable_results.first(MAX_INLINE_COMMENTS).map do |result|
        {
          path: result.filepath,
          line: result.line.to_i,
          side: "RIGHT",
          body: comment_body(result),
        }
      end
    end

    def commentable_results
      deduplicated_results.select do |result|
        result.filepath.to_s != "" &&
          result.line &&
          diff_map.commentable?(result.filepath, result.line)
      end
    end

    def deduplicated_results
      seen = {}
      run.results.select do |result|
        key = [result.tool, result.check, result.filepath, result.line, result.result]
        next false if seen[key]

        seen[key] = true
      end
    end

    def review_body(comments)
      [
        marker,
        "Cleo quality review found #{run.results.length} finding#{'s' unless run.results.length == 1}.",
        inline_summary(comments),
        unmapped_summary,
      ].compact.join("\n\n")
    end

    def inline_summary(comments)
      return "No findings mapped cleanly to commentable PR diff lines." if comments.empty?

      "Posted #{comments.length} inline comment#{'s' unless comments.length == 1}."
    end

    def unmapped_summary
      unmapped = run.results.length - commentable_results.length
      capped = [commentable_results.length - MAX_INLINE_COMMENTS, 0].max
      omitted = unmapped + capped
      return if omitted <= 0

      "#{omitted} finding#{'s' unless omitted == 1} were left in the workflow annotation output because they did not map to an inline review comment."
    end

    def comment_body(result)
      truncate(
        [
          "**#{result.tool} / #{result.check}**",
          result.result,
        ].join("\n\n"),
      )
    end

    def truncate(value)
      return value if value.length <= MAX_BODY_LENGTH

      "#{value[0, MAX_BODY_LENGTH - 20]}\n\n[truncated]"
    end
  end
end
