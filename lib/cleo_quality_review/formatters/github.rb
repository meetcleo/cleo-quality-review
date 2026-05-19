# frozen_string_literal: true

require_relative "../prompt_loader"

module CleoQualityReview
  module Formatters
    ##
    # Formats quality review results as GitHub Actions workflow commands
    class Github
      DEFAULT_SUMMARY_LIMIT = 5

      ##
      # @param [Run] run the quality review run to format
      def initialize(run:)
        @run = run
      end

      ##
      # Format the run as GitHub Actions annotations
      # @return [String] workflow commands output
      def format
        return "" if findings.empty?

        (findings.map { |finding| annotation(finding) } + [summary_annotation]).compact.join("\n")
      end

      private

      attr_reader :run

      def findings
        Array(run.results)
      end

      def annotation(finding)
        properties = {
          file: finding.filepath,
          line: finding.line,
          title: "#{finding.tool}: #{finding.check}",
        }.compact

        "::warning #{properties(properties)}::#{escape_message(finding.result)}"
      end

      def summary_annotation
        selected_findings = prioritized_findings.first(summary_limit)
        return if selected_findings.empty?

        "::notice title=Cleo Quality Review Summary::#{escape_message(summary_message(selected_findings))}"
      end

      def summary_message(selected_findings)
        entries = selected_findings.each_with_index.map do |finding, index|
          location = [finding.filepath, finding.line].compact.join(":")
          "#{index + 1}. #{location} #{finding.tool}/#{finding.check}: #{finding.result}"
        end

        [PromptLoader.load(format: "github").strip, *entries].reject(&:empty?).join("\n")
      end

      def prioritized_findings
        findings.sort_by { |finding| -priority_score(finding) }
      end

      def priority_score(finding)
        case finding.tool
        when "flog"
          1_000 + finding.result.to_s[/\A\d+(?:\.\d+)?/].to_f
        when "reek"
          500 + reek_priority(finding.check)
        when "fasterer"
          250
        else
          0
        end
      end

      def reek_priority(check)
        {
          "TooManyStatements" => 80,
          "FeatureEnvy" => 70,
          "DuplicateMethodCall" => 60,
          "NestedIterators" => 50,
          "LongParameterList" => 40,
        }.fetch(check.to_s, 10)
      end

      def summary_limit
        Integer(ENV.fetch("CLEO_QUALITY_REVIEW_GITHUB_SUMMARY_LIMIT", DEFAULT_SUMMARY_LIMIT))
      rescue ArgumentError
        DEFAULT_SUMMARY_LIMIT
      end

      def properties(values)
        values.map { |key, value| "#{key}=#{escape_property(value)}" }.join(",")
      end

      def escape_property(value)
        escape_message(value).gsub(":", "%3A").gsub(",", "%2C")
      end

      def escape_message(value)
        value.to_s
          .gsub("%", "%25")
          .gsub("\r", "%0D")
          .gsub("\n", "%0A")
      end
    end
  end
end
