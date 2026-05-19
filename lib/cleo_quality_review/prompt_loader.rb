# frozen_string_literal: true

module CleoQualityReview
  ##
  # Loads prompt templates from local or gem-bundled locations
  class PromptLoader
    GEM_PROMPTS_DIRECTORY = File.expand_path("../../prompts", __dir__)
    LOCAL_PROMPTS_DIRECTORY = ".cleo_quality_review"

    ##
    # Load a prompt template for the given format
    # @param [String] format output format name
    # @return [String] prompt template content
    # @raise [ArgumentError] if no prompt found for the format
    def self.load(format: "human")
      new(format: format).load
    end

    ##
    # @param [String] format output format name
    def initialize(format:)
      @format = format
    end

    ##
    # Load the prompt template
    # @return [String] prompt content
    # @raise [ArgumentError] if no prompt found
    def load
      prompt_paths.each do |path|
        return File.read(path) if File.file?(path)
      end

      raise ArgumentError, "No prompt found for format #{format.inspect}"
    end

    private

    attr_reader :format

    def prompt_paths
      [
        File.join(LOCAL_PROMPTS_DIRECTORY, "prompts", "#{format}.md"),
        File.join(LOCAL_PROMPTS_DIRECTORY, "#{format}.md"),
        legacy_local_prompt_path,
        File.join(GEM_PROMPTS_DIRECTORY, "#{format}.md"),
        File.join(GEM_PROMPTS_DIRECTORY, "default.md"),
      ].compact
    end

    def legacy_local_prompt_path
      return unless format == "human"

      File.join(LOCAL_PROMPTS_DIRECTORY, "prompt.md")
    end
  end
end
