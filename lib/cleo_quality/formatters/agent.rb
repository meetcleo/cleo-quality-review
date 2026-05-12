# frozen_string_literal: true

require "json"

require_relative "../prompt_loader"

module CleoQuality
  module Formatters
    class Agent
      def initialize(run:)
        @run = run
      end

      def format
        JSON.pretty_generate(run.to_h.merge(instructions: PromptLoader.load(format: "agent")))
      end

      private

      attr_reader :run
    end
  end
end
