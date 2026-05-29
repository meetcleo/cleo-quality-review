# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/prompt_loader"

module CleoQualityReview
  class PromptLoaderTest < Minitest::Test
    def test_uses_local_prompt_override_when_present
      in_tmpdir do
        FileUtils.mkdir_p(".cleo_quality_review")
        File.write(".cleo_quality_review/agent.md", "local agent prompt")

        assert_equal "local agent prompt", PromptLoader.load(format: "agent")
      end
    end

    def test_uses_local_nested_prompt_override_when_present
      in_tmpdir do
        FileUtils.mkdir_p(".cleo_quality_review/prompts")
        File.write(".cleo_quality_review/prompts/github.md", "local github prompt")

        assert_equal "local github prompt", PromptLoader.load(format: "github")
      end
    end

    def test_uses_format_prompt_when_no_override_exists
      in_tmpdir do
        assert_includes PromptLoader.load(format: "human"), "You are reviewing a local code change"
        assert_includes PromptLoader.load(format: "agent"), "AI coding assistants"
        assert_includes PromptLoader.load(format: "github"), "GitHub Actions automation pipeline"
      end
    end

    def test_agent_prompt_schema_uses_tool_name_and_tool_type
      prompt = PromptLoader.load(format: "agent")

      assert_includes prompt, '"tool_name": "<reek|flog|fasterer>"'
      assert_includes prompt, '"tool_type": "<smell_detection|complexity|performance|dead_code>"'
    end
  end
end
