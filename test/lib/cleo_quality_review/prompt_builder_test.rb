# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/prompt_builder"
require "cleo_quality_review/run_artifacts"

module CleoQualityReview
  class PromptBuilderTest < Minitest::Test
    def test_reloaded_run_renders_persisted_base_ref_in_diff_section
      in_tmpdir do
        artifacts = RunArtifacts.new(
          review_id: "review-id",
          changes_diff: "diff --git a/app/example.rb b/app/example.rb\n",
        ).prepare!
        artifacts.write_run(
          Run.new(
            timestamp: 123,
            review_id: "review-id",
            base_ref: "origin/feature-branch",
            format: "agent",
            checks: ["fake"],
            target_files: [],
            ruby_files: [],
            run_directory: artifacts.to_s,
            results: [],
            artifacts: artifacts,
          ),
        )

        run = RunArtifacts.load(review_id: "review-id").to_run(format: "agent")
        prompt = PromptBuilder.new(run: run, prompt: "Base prompt", artifacts: run.artifacts).build

        assert_includes prompt, "## Git diff against origin/feature-branch"
      end
    end
  end
end
