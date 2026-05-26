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
    RawCheckOutput = Struct.new(:check_name, :tool_name, :tool_type, :extension, :path, :raw_output, keyword_init: true) do
      def to_pair
        [check_name, raw_output]
      end

      def to_record_pair
        [check_name, self]
      end

      def to_h
        {
          check_name: check_name,
          tool_name: tool_name,
          tool_type: tool_type,
          extension: extension,
          path: path,
          raw_output: raw_output,
        }.compact
      end
    end

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
    # @param [Checks::CheckOutput] check_output output record from a quality check
    # @return [void]
    def write_check_output(check_output)
      check_name, tool_type, extension, output = check_output.to_h.values_at(
        :check_name, :tool_type, :extension, :raw_output
      )
      check_path = check_output_path(check_name: check_name, tool_type: tool_type)
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
      File.write(manifest_path, JSON.pretty_generate(run.manifest_data))
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
      target_files = manifest.fetch("target_files", [])
      Run.new(
        timestamp: manifest.fetch("timestamp"),
        review_id: manifest.fetch("review_id"),
        format: format,
        checks: manifest.fetch("checks", []),
        target_files: target_files,
        ruby_files: manifest.fetch("ruby_files", target_files),
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
      raw_check_output_records.to_h(&:to_pair)
    end

    ##
    # Read all raw check outputs with metadata from the artifact directory
    # @return [Array<RawCheckOutput>]
    def raw_check_output_records
      records_by_check_name = legacy_raw_check_output_records.to_h(&:to_record_pair)
      records_by_check_name.merge!(typed_raw_check_output_records.to_h(&:to_record_pair))
      records_by_check_name.values
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

    def check_output_path(check_name:, tool_type:)
      normalized_tool_type = tool_type.to_s.strip
      return File.join(path, check_name) if normalized_tool_type.empty?

      File.join(path, normalized_tool_type, check_name)
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
      JSON.parse(File.read(results_path)).map { |hash| result_from_hash(hash) }
    rescue Errno::ENOENT
      []
    end

    def result_from_hash(hash)
      Result.new(
        tool_name: hash["tool_name"] || hash["tool"],
        tool_type: hash["tool_type"],
        check: hash["check"],
        timestamp: hash["timestamp"],
        result: hash["result"],
        filepath: hash["filepath"],
        line: hash["line"],
      )
    end

    def typed_raw_check_output_records
      Dir.glob(File.join(path, "*", "*", "raw_output.*")).sort.map do |filepath|
        check_dir = File.dirname(filepath)
        check_name = File.basename(check_dir)
        tool_type = File.basename(File.dirname(check_dir))

        raw_check_output_record(
          filepath: filepath,
          check_name: check_name,
          tool_type: tool_type,
        )
      end
    end

    def legacy_raw_check_output_records
      Dir.glob(File.join(path, "*", "raw_output.*")).sort.map do |filepath|
        check_name = File.basename(File.dirname(filepath))

        raw_check_output_record(
          filepath: filepath,
          check_name: check_name,
          tool_type: nil,
        )
      end
    end

    def raw_check_output_record(filepath:, check_name:, tool_type:)
      RawCheckOutput.new(
        check_name: check_name,
        tool_name: check_name,
        tool_type: tool_type,
        extension: File.extname(filepath).delete_prefix("."),
        path: filepath,
        raw_output: File.read(filepath, invalid: :replace, undef: :replace),
      )
    end
  end
end
