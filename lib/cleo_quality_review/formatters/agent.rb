# frozen_string_literal: true

require "json"

require_relative "../prompt_loader"

module CleoQualityReview
  module Formatters
    ##
    # Formats quality review results as JSON for agent consumption
    class Agent
      ##
      # @param [Run] run the quality review run to format
      def initialize(run:)
        @run = run
      end

      ##
      # Format the run as JSON with embedded instructions
      # @return [String] JSON output
      def format
        JSON.pretty_generate(run.to_h.merge(instructions: PromptLoader.load(format: "agent")))
      end

      private

      attr_reader :run
    end
  end
end
