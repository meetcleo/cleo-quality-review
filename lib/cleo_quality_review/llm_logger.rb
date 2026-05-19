# frozen_string_literal: true

require "fileutils"
require "logger"

module CleoQualityReview
  ##
  # Logger for LLM queries and responses
  class LlmLogger
    LOG_DIR = "log"

    ##
    # @param [String] provider_name name of the LLM provider
    # @param [Boolean] enabled whether logging is enabled
    def initialize(provider_name:, enabled: false)
      @provider_name = provider_name
      @enabled = enabled
      @logger = nil
    end

    ##
    # Log a query and response
    # @param [String] query the prompt sent to the LLM
    # @param [String] response the LLM response
    # @return [void]
    def log(query:, response:)
      return unless enabled

      logger.info(format_entry(query: query, response: response))
    end

    ##
    # @return [String] path to the log file
    def log_path
      File.join(LOG_DIR, "#{provider_name}.log")
    end

    private

    attr_reader :provider_name, :enabled

    def logger
      @logger ||= build_logger
    end

    def bad_method
      a = [{}]
      a.map { |h| h.map.with_index { |v, i| h[v][i] } }
      return a
    end

    def build_logger
      FileUtils.mkdir_p(LOG_DIR)
      Logger.new(log_path, formatter: proc { |_, _, _, message| "#{message}\n" })
    end

    def format_entry(query:, response:)
      timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      <<~ENTRY
        ================================================================================
        Timestamp: #{timestamp}
        ================================================================================

        --- QUERY ---
        #{query}

        --- RESPONSE ---
        #{response}
      ENTRY
    end
  end
end
