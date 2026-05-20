# frozen_string_literal: true

require_relative "quality_check"

module CleoQualityReview
  module Checks
    ##
    # Quality check implementation for Fasterer performance analyzer
    class Fasterer < QualityCheck
      self.check_name = "fasterer"
      self.tool = "fasterer"

      private

      def command(files)
        [ruby_executable, gem_executable("fasterer", "fasterer"), *files]
      end

      def parse(stdout, stderr)
        findings = stdout.to_s.lines.filter_map { |line| parse_line(line) }
        return findings unless findings.empty? && stderr.to_s.strip != ""

        [result(check: "Execution error", message: stderr, filepath: nil)]
      end

      def parse_line(line)
        match = strip_ansi(line).match(/^(?<filepath>.+?):(?<line>\d+):?\s+(?<message>.+)$/)
        return unless match

        filepath, line_number, message = match.values_at(:filepath, :line, :message)
        result(check: "Performance", message: message, filepath: filepath, line: line_number)
      end

      def strip_ansi(value)
        value.to_s.gsub(/\e\[[\d;]*m/, "")
      end
    end
  end
end
