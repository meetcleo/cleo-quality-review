# frozen_string_literal: true

require "set"

module CleoQualityReview
  ##
  # Maps a unified git diff to right-side line numbers that GitHub can comment on
  class DiffMap
    HUNK_HEADER = /^@@ -\d+(?:,\d+)? \+(?<line>\d+)(?:,\d+)? @@/.freeze

    ##
    # Stateful parser for file and right-side hunk line transitions
    class DiffParser
      def initialize(commentable_lines)
        @commentable_lines = commentable_lines
        @path = nil
        @new_line = nil
      end

      def parse(diff)
        diff.each_line { |line| parse_line(line) }
      end

      private

      attr_reader :commentable_lines, :new_line, :path

      def parse_line(line)
        if line.start_with?("+++ ")
          start_file(line)
        elsif (line_number = hunk_start_line(line))
          @new_line = line_number
        elsif in_hunk?
          parse_hunk_line(line)
        end
      end

      def start_file(line)
        @path = normalize_path(line.delete_prefix("+++ ").strip)
        @new_line = nil
      end

      def hunk_start_line(line)
        match = line.match(HUNK_HEADER)
        match[:line].to_i if match
      end

      def in_hunk?
        path && new_line
      end

      def parse_hunk_line(line)
        case line[0]
        when "+", " "
          commentable_lines[path] << new_line
          @new_line += 1
        when "-"
          new_line
        else
          @new_line = nil
        end
      end

      def normalize_path(path)
        return nil if path == "/dev/null"

        path.delete_prefix("b/")
      end
    end

    ##
    # @param [String] diff unified git diff content
    def initialize(diff)
      @diff = diff.to_s
      @commentable_lines = Hash.new { |hash, key| hash[key] = Set.new }
      parse
    end

    ##
    # @param [String] filepath repository-relative file path
    # @param [Integer] line right-side line number
    # @return [Boolean]
    def commentable?(filepath, line)
      commentable_lines[filepath.to_s].include?(line.to_i)
    end

    private

    attr_reader :commentable_lines, :diff

    def parse
      DiffParser.new(commentable_lines).parse(diff)
    end
  end
end
