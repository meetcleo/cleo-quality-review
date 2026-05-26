# frozen_string_literal: true

require "json"

require_relative "quality_check"

module CleoQualityReview
  module Checks
    ##
    # Quality check implementation for Debride unused-code analyzer
    class Debride < QualityCheck
      self.check_name = "dead_code"
      self.tool_name = "debride"
      self.output_extension = "json"

      private

      def command(files)
        [ruby_executable, gem_executable("debride", "debride"), "--json", "--rails", *files]
      end

      def parse(stdout, stderr)
        findings = missing_methods(stdout).flat_map do |class_name, methods|
          Array(methods).map { |entry| method_to_result(class_name, entry) }
        end
        return findings unless findings.empty? && stderr.to_s.strip != ""

        [result(check: "Execution error", message: stderr, filepath: nil)]
      end

      def missing_methods(stdout)
        parsed = JSON.parse(stdout.to_s)
        missing = parsed.fetch("missing", {})
        return {} unless missing.is_a?(Hash)

        missing
      rescue JSON::ParserError
        {}
      end

      def method_to_result(class_name, entry)
        method_name, location = Array(entry)
        filepath, line = parse_location(location)

        result(
          check: "PotentialDeadMethod",
          message: "#{class_name}##{method_name} might not be called",
          filepath: filepath,
          line: line,
        )
      end

      def parse_location(location)
        match = location.to_s.match(/\A(?<filepath>.*):(?<line>\d+)(?:-\d+)?\z/)
        return [nil, nil] unless match

        match.values_at(:filepath, :line)
      end
    end
  end
end
