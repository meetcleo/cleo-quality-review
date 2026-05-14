# frozen_string_literal: true

require_relative "quality_check"

module CleoQualityReview
  module Checks
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

        [
          result(
            check: "Execution error",
            message: stderr,
            filepath: nil,
          ),
        ]
      end

      def parse_line(line)
        match = line.match(/^(?<filepath>.+?\.rb):(?<line>\d+):?\s+(?<message>.+)$/)
        return unless match

        result(
          check: "Performance",
          message: match[:message],
          filepath: match[:filepath],
          line: match[:line],
        )
      end
    end
  end
end
