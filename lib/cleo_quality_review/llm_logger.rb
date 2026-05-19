# frozen_string_literal: true

require "fileutils"

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
    end

    ##
    # Log a query and response
    # @param [String] query the prompt sent to the LLM
    # @param [String] response the LLM response
    # @return [void]
    def log(query:, response:)
      return unless enabled

      ensure_log_directory
      File.open(log_path, "a") do |file|
        file.puts(format_entry(query: query, response: response))
      end
    end

    ##
    # @return [String] path to the log file
    def log_path
      File.join(LOG_DIR, "#{provider_name}.log")
    end

    private

    attr_reader :provider_name, :enabled

    def ensure_log_directory
      FileUtils.mkdir_p(LOG_DIR)
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
