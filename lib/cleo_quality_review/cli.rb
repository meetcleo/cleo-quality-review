# frozen_string_literal: true

require "optparse"

require_relative "command_runner"
require_relative "formatter"
require_relative "github_review_publisher"
require_relative "options"
require_relative "runner"
require_relative "run_artifacts"

module CleoQualityReview
  ##
  # Command-line interface entry point
  class CLI
    SUBCOMMANDS = %w[analyze render publish-pr-review].freeze

    ##
    # @param [Array<String>] argv command-line arguments
    # @param [IO] stdout standard output stream
    # @param [IO] stderr standard error stream
    def initialize(argv, stdout: $stdout, stderr: $stderr)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
    end

    ##
    # Execute the CLI
    # @return [Integer] exit code (0 for success, 1 for error)
    def run
      command_runner = CommandRunner.new
      command = argv.first

      if SUBCOMMANDS.include?(command)
        run_subcommand(command, argv.drop(1), command_runner)
      else
        run_one_shot(argv, command_runner)
      end
    rescue Error, OptionParser::ParseError, ArgumentError => e
      stderr.puts("check_quality: #{e.message}")
      1
    end

    private

    attr_reader :argv, :stdout, :stderr

    def run_one_shot(arguments, command_runner)
      options = Options.parse(arguments)
      run = Runner.new(options: options, command_runner: command_runner).run
      output = Formatter.new(run: run, command_runner: command_runner).format
      stdout.puts(output) unless output.empty?
      0
    end

    def run_subcommand(command, arguments, command_runner)
      case command
      when "analyze"
        run_analyze(arguments, command_runner)
      when "render"
        run_render(arguments, command_runner)
      when "publish-pr-review"
        run_publish_pr_review(arguments)
      end
    end

    def run_analyze(arguments, command_runner)
      options = Options.parse(arguments)
      run = Runner.new(options: options, command_runner: command_runner).run
      stdout.puts(run.review_id)
      0
    end

    def run_render(arguments, command_runner)
      options = Options.parse(arguments)
      run = load_run(options)
      output = Formatter.new(run: run, command_runner: command_runner).format
      stdout.puts(output) unless output.empty?
      0
    end

    def run_publish_pr_review(arguments)
      options = Options.parse(arguments)
      run = load_run(options)
      output = GitHubReviewPublisher.new(run: run).publish
      stdout.puts(output) unless output.empty?
      0
    end

    def load_run(options)
      raise OptionParser::MissingArgument, "--review-id is required" if options.review_id.to_s.strip == ""

      RunArtifacts.load(review_id: options.review_id).to_run(format: options.format, log: options.log)
    end
  end
end
