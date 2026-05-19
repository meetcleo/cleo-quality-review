# frozen_string_literal: true

require "optparse"

require_relative "command_runner"
require_relative "formatter"
require_relative "options"
require_relative "runner"

module CleoQualityReview
  ##
  # Command-line interface entry point
  class CLI
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
      options = Options.parse(argv)
      run = Runner.new(options: options, command_runner: command_runner).run
      output = Formatter.new(run: run, command_runner: command_runner).format
      stdout.puts(output) unless output.empty?
      0
    rescue Error, OptionParser::ParseError, ArgumentError => e
      stderr.puts("check_quality: #{e.message}")
      1
    end

    private

    attr_reader :argv, :stdout, :stderr
  end
end
