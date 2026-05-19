# frozen_string_literal: true

require "json"
require "fileutils"

require_relative "result"
require_relative "run"

module CleoQualityReview
  ##
  # Manages artifacts produced during a quality review run
  class RunArtifacts
    ROOT = "tmp/quality_checks"

    ##
    # @param [String] review_id deterministic identifier for the reviewed diff
    # @param [Integer] timestamp epoch milliseconds for the run
    # @param [Array<String>] target_files file paths being analyzed
    # @param [String] changes_diff captured git diff content
    def initialize(review_id:, timestamp: nil, target_files: [], changes_diff: nil)
      @review_id = review_id.to_s
      @timestamp = timestamp
      @target_files = target_files
      @changes_diff_content = changes_diff
      @path = File.join(ROOT, @review_id)
    end

    ##
    # Load artifacts by review ID
    # @param [String] review_id deterministic identifier for the reviewed diff
    # @return [RunArtifacts]
    def self.load(review_id:)
      new(review_id: review_id)
    end

    ##
    # Prepare the artifact directory and capture initial data
    # @return [self]
    def prepare!
      FileUtils.mkdir_p(path)
      write_changes_diff
      self
    end

    ##
    # @return [Boolean] whether this artifact directory contains a complete analysis
    def complete?
      File.file?(complete_path)
    end

    ##
    # Write raw check output to a file
    # @param [String] check_name name of the check
    # @param [String] extension file extension for the output
    # @param [String] output raw check output content
    # @return [void]
    def write_check_output(check_name:, extension:, output:)
      check_path = File.join(path, check_name)
      FileUtils.mkdir_p(check_path)
      File.write(File.join(check_path, "raw_output.#{extension}"), output)
    end

    ##
    # Persist normalized findings for later render/publish commands
    # @param [Array<Result>] results normalized tool findings
    # @return [void]
    def write_results(results)
      File.write(results_path, JSON.pretty_generate(Array(results).map(&:to_h)))
    end

    ##
    # Persist run metadata for later render/publish commands
    # @param [Run] run completed run
    # @return [void]
    def write_manifest(run)
      File.write(
        manifest_path,
        JSON.pretty_generate(
          {
            review_id: run.review_id,
            timestamp: run.timestamp,
            checks: run.checks,
            target_files: run.target_files,
            ruby_files: run.ruby_files,
          },
        ),
      )
    end

    ##
    # Mark this artifact directory as safe to reuse
    # @return [void]
    def mark_complete!
      File.write(complete_path, JSON.pretty_generate({ review_id: review_id, completed: true }))
    end

    ##
    # Reconstruct a run from persisted artifacts
    # @param [String] format output format to render
    # @param [Boolean] log whether LLM logging should be enabled
    # @return [Run]
    def to_run(format:, log: false)
      raise ArgumentError, "No completed quality review artifacts found for review ID #{review_id}" unless complete?

      manifest = read_manifest
      Run.new(
        timestamp: manifest.fetch("timestamp"),
        review_id: manifest.fetch("review_id"),
        format: format,
        checks: manifest.fetch("checks", []),
        target_files: manifest.fetch("target_files", []),
        ruby_files: manifest.fetch("ruby_files", manifest.fetch("target_files", [])),
        run_directory: path,
        results: read_results,
        artifacts: self,
        log: log,
      )
    end

    ##
    # Read the captured git diff for changes
    # @return [String]
    def changes_diff
      File.read(changes_diff_path)
    end

    ##
    # Read all raw check outputs from the artifact directory
    # @return [Hash{String => String}] check name to output content mapping
    def raw_check_outputs
      Dir.glob(File.join(path, "*", "raw_output.*")).sort.to_h do |filepath|
        check_name = File.basename(File.dirname(filepath))
        [check_name, File.read(filepath, invalid: :replace, undef: :replace)]
      end
    end

    ##
    # @return [String] path to the artifacts directory
    def to_s
      path
    end

    private

    attr_reader :changes_diff_content, :path, :review_id, :timestamp, :target_files

    def changes_diff_path
      File.join(path, "changes.diff")
    end

    def manifest_path
      File.join(path, "manifest.json")
    end

    def results_path
      File.join(path, "results.json")
    end

    def complete_path
      File.join(path, "complete.json")
    end

    def write_changes_diff
      File.write(changes_diff_path, changes_diff_content.to_s)
    end

    def read_manifest
      JSON.parse(File.read(manifest_path))
    rescue Errno::ENOENT
      raise ArgumentError, "Missing manifest for review ID #{review_id}"
    end

    def read_results
      JSON.parse(File.read(results_path)).map do |hash|
        Result.new(
          tool: hash["tool"],
          check: hash["check"],
          timestamp: hash["timestamp"],
          result: hash["result"],
          filepath: hash["filepath"],
          line: hash["line"],
        )
      end
    rescue Errno::ENOENT
      []
    end
  end
end
