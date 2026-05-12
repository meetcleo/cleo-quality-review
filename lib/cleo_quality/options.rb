# frozen_string_literal: true

require "optparse"

module CleoQuality
  class Options
    FORMATS = %w[human agent github].freeze
    DEFAULT_FORMAT = "human"
    DEFAULT_CHECKS = ["all"].freeze

    ParseResult = Struct.new(:format, :checks, :files, keyword_init: true)

    def self.parse(argv)
      new(argv).parse
    end

    def initialize(argv)
      @argv = argv.dup
      @format = DEFAULT_FORMAT
      @checks = []
      @files = []
    end

    def parse
      parser.parse!(argv)
      validate_format!

      ParseResult.new(
        format: format,
        checks: checks.empty? ? DEFAULT_CHECKS.dup : checks,
        files: files,
      )
    end

    private

    attr_reader :argv, :format, :checks, :files

    def parser
      OptionParser.new do |opts|
        opts.banner = "Usage: check_quality [options]"

        opts.on("--format FORMAT", FORMATS, "Output format: #{FORMATS.join(', ')}") do |value|
          @format = value
        end

        opts.on("--checks CHECKS", Array, "Checks to run: all, reek, flog, fasterer") do |values|
          checks.concat(values)
        end

        opts.on("--files PATHS", Array, "Comma-separated files or directories to check") do |values|
          files.concat(values)
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
