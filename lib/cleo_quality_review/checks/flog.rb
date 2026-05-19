# frozen_string_literal: true

require_relative "quality_check"

module CleoQualityReview
  module Checks
    ##
    # Quality check implementation for Flog complexity analyzer
    class Flog < QualityCheck
      self.check_name = "flog"
      self.tool = "flog"

      private

      def command(files)
        [ruby_executable, gem_executable("flog", "flog"), "--all", "--methods", *files]
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
        match = line.match(/^\s*(?<score>\d+(?:\.\d+)?):\s+(?<subject>.+?)\s+(?<filepath>[^:\s]+):(?<line>\d+)/)
        return unless match

        result(
          check: "Complexity",
          message: "#{match[:score]}: #{match[:subject]}",
          filepath: match[:filepath],
          line: match[:line],
        )
      end
    end
  end
end
