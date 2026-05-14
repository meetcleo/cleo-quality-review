# frozen_string_literal: true

require_relative "test_helper"
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

    def test_supports_legacy_human_prompt_override
      in_tmpdir do
        FileUtils.mkdir_p(".cleo_quality_review")
        File.write(".cleo_quality_review/prompt.md", "legacy human prompt")

        assert_equal "legacy human prompt", PromptLoader.load(format: "human")
      end
    end

    def test_uses_format_prompt_when_no_override_exists
      in_tmpdir do
        assert_includes PromptLoader.load(format: "human"), "You are reviewing a local code change"
        assert_includes PromptLoader.load(format: "agent"), "coding agent"
        assert_includes PromptLoader.load(format: "github"), "top actionable issues"
      end
    end
  end
end
