# frozen_string_literal: true

require_relative "formatters/agent"
require_relative "formatters/github"
require_relative "formatters/human"

module CleoQuality
  class Formatter
    def initialize(run:, command_runner:)
      @run = run
      @command_runner = command_runner
    end

    def format
      formatter_class.new(**formatter_args).format
    end

    private

    attr_reader :run, :command_runner

    def formatter_class
      case run.format
      when "agent"
        Formatters::Agent
      when "github"
        Formatters::Github
      when "human"
        Formatters::Human
      else
        raise ArgumentError, "Unknown format #{run.format.inspect}"
      end
    end

    def formatter_args
      args = { run: run }
      args[:command_runner] = command_runner if run.format == "human"
      args
    end
  end
end
