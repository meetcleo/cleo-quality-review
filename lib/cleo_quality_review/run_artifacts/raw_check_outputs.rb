# frozen_string_literal: true

require "fileutils"

module CleoQualityReview
  class RunArtifacts
    ##
    # Handles persisted raw output files for quality checks.
    class RawCheckOutputs
      ##
      # Raw output content and metadata for one quality check.
      Record = Struct.new(:check_name, :tool_name, :tool_type, :extension, :path, :raw_output, keyword_init: true) do
        def self.from_path(filepath:, check_name:, tool_type:)
          new(
            check_name: check_name,
            tool_name: check_name,
            tool_type: tool_type,
            extension: File.extname(filepath).delete_prefix("."),
            path: filepath,
            raw_output: File.read(filepath, invalid: :replace, undef: :replace),
          )
        end

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

      def initialize(path:)
        @path = path
      end

      def write(check_output)
        check_name, tool_type, extension, output = check_output.to_h.values_at(
          :check_name, :tool_type, :extension, :raw_output
        )
        check_path = check_output_path(check_name: check_name, tool_type: tool_type)
        FileUtils.mkdir_p(check_path)
        File.write(File.join(check_path, "raw_output.#{extension}"), output)
      end

      def to_h
        records.to_h(&:to_pair)
      end

      def records
        records_by_check_name = legacy_records.to_h(&:to_record_pair)
        records_by_check_name.merge!(typed_records.to_h(&:to_record_pair))
        records_by_check_name.values
      end

      private

      attr_reader :path

      def check_output_path(check_name:, tool_type:)
        normalized_tool_type = tool_type.to_s.strip
        return File.join(path, check_name) if normalized_tool_type.empty?

        File.join(path, normalized_tool_type, check_name)
      end

      def typed_records
        Dir.glob(File.join(path, "*", "*", "raw_output.*")).sort.map do |filepath|
          check_dir = File.dirname(filepath)
          check_name = File.basename(check_dir)
          tool_type = File.basename(File.dirname(check_dir))

          Record.from_path(filepath: filepath, check_name: check_name, tool_type: tool_type)
        end
      end

      def legacy_records
        Dir.glob(File.join(path, "*", "raw_output.*")).sort.map do |filepath|
          check_name = File.basename(File.dirname(filepath))

          Record.from_path(filepath: filepath, check_name: check_name, tool_type: nil)
        end
      end
    end
  end
end
