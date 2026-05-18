# frozen_string_literal: true

require "optparse"

module CleoQualityReview
  class Options
    FORMATS = %w[human agent github].freeze
    DEFAULT_FORMAT = "human"
    DEFAULT_CHECKS = ["all"].freeze

    ParseResult = Struct.new(:format, :checks, :files, :exclude, :changed, keyword_init: true)

    def self.parse(argv)
      new(argv).parse
    end

    def initialize(argv)
      @argv = argv.dup
      @format = DEFAULT_FORMAT
      @checks = []
      @files = []
      @exclude = []
      @changed = false
    end

    def parse
      parser.parse!(argv)
      validate_format!

      ParseResult.new(
        format: format,
        checks: checks.empty? ? DEFAULT_CHECKS.dup : checks,
        files: files,
        exclude: exclude,
        changed: changed,
      )
    end

    private

    attr_reader :argv, :format, :checks, :files, :exclude, :changed

    def parser
      OptionParser.new do |opts|
        opts.banner = "Usage: check_quality [options] [files...]"

        opts.on("-f", "--format FORMAT", FORMATS, "Output format: #{FORMATS.join(', ')} (default: human)") do |value|
          @format = value
        end

        opts.on("-c", "--checks CHECKS", Array, "Checks to run: all, reek, flog, fasterer") do |values|
          checks.concat(values)
        end

        opts.on("--only CHECKS", Array, "Alias for --checks") do |values|
          checks.concat(values)
        end

        opts.on("-x", "--exclude CHECKS", Array, "Checks to exclude") do |values|
          exclude.concat(values)
        end

        opts.on("--files PATHS", Array, "Comma-separated files or directories to check") do |values|
          files.concat(values)
        end

        opts.on("--changed", "Only check files changed from main branch") do
          @changed = true
        end

        opts.on("-h", "--help", "Print help") do
          puts opts
          exit 0
        end
      end
    end

    def validate_format!
      return if FORMATS.include?(format)

      raise OptionParser::InvalidArgument, "format must be one of: #{FORMATS.join(', ')}"
    end
  end
end
