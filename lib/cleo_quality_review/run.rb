# frozen_string_literal: true

module CleoQualityReview
  ##
  # Value object representing a quality review run with its configuration and results
  #
  # @!attribute [r] timestamp
  #   @return [Integer] epoch milliseconds when the run started
  # @!attribute [r] format
  #   @return [String] output format (human, agent, github)
  # @!attribute [r] checks
  #   @return [Array<String>] names of checks that were run
  # @!attribute [r] target_files
  #   @return [Array<String>] file paths that were analyzed
  # @!attribute [r] ruby_files
  #   @return [Array<String>] Ruby file paths that were analyzed
  # @!attribute [r] run_directory
  #   @return [String] path to the directory containing run artifacts
  # @!attribute [r] results
  #   @return [Array<Result>] findings from the quality checks
  # @!attribute [r] artifacts
  #   @return [RunArtifacts, nil] artifacts associated with this run
  Run = Struct.new(
    :timestamp,
    :format,
    :checks,
    :target_files,
    :ruby_files,
    :run_directory,
    :results,
    :artifacts,
    :log,
    keyword_init: true,
  ) do
    ##
    # Convert the run to a hash representation
    # @return [Hash{Symbol => Object}]
    def to_h
      {
        timestamp: timestamp,
        format: format,
        checks: checks,
        target_files: target_files,
        ruby_files: ruby_files,
        run_directory: run_directory,
        changes_diff: artifacts&.changes_diff,
        check_outputs: check_outputs,
        findings: Array(results).map(&:to_h),
      }
    end

    ##
    # Build array of check output hashes for serialization
    # @return [Array<Hash{Symbol => String}>]
    def check_outputs
      return [] unless artifacts

      artifacts.raw_check_outputs.map do |check, output|
        {
          check: check,
          raw_output: output,
        }
      end
    end
  end
end
