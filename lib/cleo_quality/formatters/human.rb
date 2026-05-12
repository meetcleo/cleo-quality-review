# frozen_string_literal: true

require_relative "../llm_client"
require_relative "../llm_config"
require_relative "../prompt_builder"
require_relative "../prompt_loader"
require_relative "../run_artifacts"

module CleoQuality
  module Formatters
    class Human
      def initialize(run:, command_runner:, llm_config: LlmConfig.new, llm_client: nil)
        @run = run
        @command_runner = command_runner
        @llm_config = llm_config
        @llm_client = llm_client
      end

      def format
        llm_client.generate_review(prompt)
      end

      private

      attr_reader :run, :command_runner, :llm_config

      def prompt
        PromptBuilder.new(
          run: run,
          prompt: PromptLoader.load(format: "human"),
          artifacts: artifacts,
        ).build
      end

      def artifacts
        @artifacts ||= run.artifacts || RunArtifacts.new(
          timestamp: run.timestamp,
          target_files: run.target_files,
          command_runner: command_runner,
        )
      end

      def llm_client
        @llm_client ||= LlmClient.new(config: llm_config, command_runner: command_runner)
      end
    end
  end
end
