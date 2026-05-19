# frozen_string_literal: true

require "optparse"

module CleoQualityReview
  ##
  # Parses command-line options for the quality review CLI
  class Options
    FORMATS = %w[human agent github pr_review].freeze
    DEFAULT_FORMAT = "human"
    DEFAULT_CHECKS = ["all"].freeze

    ##
    # Value object containing parsed command-line options
    #
    # @!attribute [r] format
    #   @return [String] output format
    # @!attribute [r] checks
    #   @return [Array<String>] checks to run
    # @!attribute [r] files
    #   @return [Array<String>] explicit file paths
    # @!attribute [r] exclude
    #   @return [Array<String>] checks to exclude
    # @!attribute [r] changed
    #   @return [Boolean] whether to filter to changed files only
    ParseResult = Struct.new(:format, :checks, :files, :exclude, :changed, :log, :review_id, :review_file, keyword_init: true)

    ##
    # Parse command-line arguments
    # @param [Array<String>] argv command-line arguments
    # @return [ParseResult]
    # @raise [OptionParser::ParseError] if arguments are invalid
    def self.parse(argv)
      new(argv).parse
    end

    ##
    # @param [Array<String>] argv command-line arguments
    def initialize(argv)
      @argv = argv.dup
      @format = DEFAULT_FORMAT
      @checks = []
      @files = []
      @exclude = []
      @changed = false
      @log = false
      @review_id = nil
      @review_file = nil
    end

    ##
    # Parse the arguments and return the result
    # @return [ParseResult]
    # @raise [OptionParser::InvalidArgument] if format is invalid
    def parse
      parser.parse!(argv)
      validate_format!
      files.concat(argv)

      ParseResult.new(
        format: format,
        checks: checks.empty? ? DEFAULT_CHECKS.dup : checks,
        files: files,
        exclude: exclude,
        changed: changed,
        log: log,
        review_id: review_id,
        review_file: review_file,
      )
    end

    private

    attr_reader :argv, :format, :checks, :files, :exclude, :changed, :log, :review_id, :review_file

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

        opts.on("--log", "Log LLM queries and responses to log/[provider].log") do
          @log = true
        end

        opts.on("--review-id REVIEW_ID", "Reuse an existing analysis artifact by review ID") do |value|
          @review_id = value
        end

        opts.on("--review-file PATH", "Rendered pr_review JSON to publish") do |value|
          @review_file = value
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
