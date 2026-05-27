# frozen_string_literal: true

require "json"
require "fileutils"

require_relative "result"
require_relative "run"
require_relative "git_diff_base"
require_relative "run_artifacts/raw_check_outputs"

module CleoQualityReview
  ##
  # Manages artifacts produced during a quality review run
  class RunArtifacts
    ROOT = "tmp/quality_checks"
    RawCheckOutput = RawCheckOutputs::Record

    ##
    # @param [String] review_id deterministic identifier for the reviewed diff
    # @param [Integer] timestamp epoch milliseconds for the run
    # @param [Array<String>] target_files file paths being analyzed
    # @param [String] changes_diff captured git diff content
    def initialize(review_id:, changes_diff: nil, **_run_metadata)
      @review_id = review_id.to_s
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
      FileUtils.mkdir_p(@path)
      write_changes_diff
      self
    end

    ##
    # @return [Boolean] whether this artifact directory contains a complete analysis
    def complete?
      File.file?(artifact_path("complete.json"))
    end

    ##
    # Write raw check output to a file
    # @param [Checks::CheckOutput] check_output output record from a quality check
    # @return [void]
    def write_check_output(check_output)
      raw_check_output_store.write(check_output)
    end

    ##
    # Persist run metadata for later render/publish commands
    # @param [Run] run completed run
    # @return [void]
    def write_run(run)
      File.write(artifact_path("results.json"), JSON.pretty_generate(Array(run.results).map(&:to_h)))
      File.write(artifact_path("manifest.json"), JSON.pretty_generate(run.manifest_data))
      File.write(artifact_path("complete.json"), JSON.pretty_generate({ review_id: @review_id, completed: true }))
    end

    ##
    # Reconstruct a run from persisted artifacts
    # @param [String] format output format to render
    # @param [Boolean] log whether LLM logging should be enabled
    # @return [Run]
    def to_run(format:, log: false)
      raise ArgumentError, "No completed quality review artifacts found for review ID #{@review_id}" unless complete?

      manifest = read_manifest
      target_files = manifest.fetch("target_files", [])
      Run.new(
        timestamp: manifest.fetch("timestamp"),
        review_id: manifest.fetch("review_id"),
        base_ref: manifest.fetch("base_ref", GitDiffBase::DEFAULT_BASE_REF),
        format: format,
        checks: manifest.fetch("checks", []),
        target_files: target_files,
        ruby_files: manifest.fetch("ruby_files", target_files),
        run_directory: @path,
        results: read_results,
        artifacts: self,
        log: log,
      )
    end

    ##
    # Read the captured git diff for changes
    # @return [String]
    def changes_diff
      File.read(artifact_path("changes.diff"))
    end

    ##
    # Read all raw check outputs from the artifact directory
    # @return [Hash{String => String}] check name to output content mapping
    def raw_check_outputs
      raw_check_output_store.to_h
    end

    ##
    # Read all raw check outputs with metadata from the artifact directory
    # @return [Array<RawCheckOutputs::Record>]
    def raw_check_output_records
      raw_check_output_store.records
    end

    ##
    # @return [String] path to the artifacts directory
    def to_s
      @path
    end

    private

    def artifact_path(filename)
      File.join(@path, filename)
    end

    def write_changes_diff
      File.write(artifact_path("changes.diff"), @changes_diff_content.to_s)
    end

    def read_manifest
      JSON.parse(File.read(artifact_path("manifest.json")))
    rescue Errno::ENOENT
      raise ArgumentError, "Missing manifest for review ID #{@review_id}"
    end

    def read_results
      JSON.parse(File.read(artifact_path("results.json"))).map { |hash| Result.from_h(hash) }
    rescue Errno::ENOENT
      []
    end

    def raw_check_output_store
      @raw_check_output_store ||= RawCheckOutputs.new(path: @path)
    end
  end
end
