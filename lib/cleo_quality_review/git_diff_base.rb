# frozen_string_literal: true

module CleoQualityReview
  ##
  # Resolves git comparison bases for changed-file and diff capture flows
  module GitDiffBase
    DEFAULT_BASE_REF = "origin/main"

    module_function

    ##
    # @param [CommandRunner] command_runner for executing git commands
    # @param [String] base_ref git ref to compare against
    # @param [Boolean] strict whether unresolved refs should raise
    # @return [String] merge-base SHA, or the base ref when non-strict resolution fails
    def resolve(command_runner:, base_ref:, strict:)
      result = command_runner.run("git", "merge-base", base_ref, "HEAD")
      base = result.stdout.strip

      return base if result.success? && !base.empty?

      raise ArgumentError, "Could not resolve quality review base ref: #{base_ref}" if strict

      base_ref
    end
  end
end
