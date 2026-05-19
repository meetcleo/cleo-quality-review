# frozen_string_literal: true

require "set"

module CleoQualityReview
  ##
  # Maps a unified git diff to right-side line numbers that GitHub can comment on
  class DiffMap
    HUNK_HEADER = /^@@ -\d+(?:,\d+)? \+(?<line>\d+)(?:,\d+)? @@/.freeze

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
      current_path = nil
      new_line = nil

      diff.each_line do |line|
        if line.start_with?("+++ ")
          current_path = normalize_path(line.delete_prefix("+++ ").strip)
          new_line = nil
        elsif (match = line.match(HUNK_HEADER))
          new_line = match[:line].to_i
        elsif current_path && new_line
          new_line = parse_hunk_line(line, current_path, new_line)
        end
      end
    end

    def parse_hunk_line(line, current_path, new_line)
      case line[0]
      when "+"
        commentable_lines[current_path] << new_line
        new_line + 1
      when " "
        commentable_lines[current_path] << new_line
        new_line + 1
      when "-"
        new_line
      else
        nil
      end
    end

    def normalize_path(path)
      return nil if path == "/dev/null"

      path.delete_prefix("b/")
    end
  end
end
