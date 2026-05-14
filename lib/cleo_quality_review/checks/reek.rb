# frozen_string_literal: true

require "json"

require_relative "quality_check"

module CleoQualityReview
  module Checks
    class Reek < QualityCheck
      self.check_name = "reek"
      self.tool = "reek"
      self.output_extension = "json"

      private

      def command(files)
        [ruby_executable, gem_executable("reek", "reek"), "--format", "json", *files]
      end

      def parse(stdout, stderr)
        smells = parse_json(stdout)
        return stderr_result(stderr) if smells.empty? && stderr.to_s.strip != ""

        smells.map do |smell|
          result(
            check: smell.fetch("smell_type", "Reek"),
            message: smell_message(smell),
            filepath: smell.fetch("source", nil),
            line: Array(smell["lines"]).first,
          )
        end
      end

      def parse_json(stdout)
        JSON.parse(stdout.to_s)
      rescue JSON::ParserError
        []
      end

      def smell_message(smell)
        [smell["context"], smell["message"]].compact.join(": ")
      end

      def stderr_result(stderr)
        [
          result(
            check: "Execution error",
            message: stderr,
            filepath: nil,
          ),
        ]
      end
    end
  end
end
