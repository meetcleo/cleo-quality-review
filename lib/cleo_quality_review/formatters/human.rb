# frozen_string_literal: true

require_relative "../llm_client"
require_relative "../llm_config"
require_relative "../prompt_builder"
require_relative "../prompt_loader"
require_relative "../run_artifacts"

module CleoQualityReview
  module Formatters
    ##
    # Formats quality review results as human-readable text via LLM
    class Human
      ##
      # @param [Run] run the quality review run to format
      # @param [CommandRunner] command_runner for executing shell commands
      # @param [LlmConfig] llm_config LLM provider configuration
      # @param [LlmClient, nil] llm_client optional pre-configured client
      def initialize(run:, command_runner:, llm_config: LlmConfig.new, llm_client: nil)
        @run = run
        @command_runner = command_runner
        @llm_config = llm_config
        @llm_client = llm_client
      end

      ##
      # Format the run by generating an LLM review
      # @return [String] human-readable review text
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
        @llm_client ||= LlmClient.new(config: llm_config)
      end
    end
  end
end
