# frozen_string_literal: true

module CleoQualityReview
  Run = Struct.new(
    :timestamp,
    :format,
    :checks,
    :target_files,
    :ruby_files,
    :run_directory,
    :results,
    :artifacts,
    keyword_init: true,
  ) do
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
