# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/llm_logger"

module CleoQualityReview
  class LlmLoggerTest < Minitest::Test
    def test_log_path_uses_provider_name
      logger = LlmLogger.new(provider_name: "openai", enabled: false)

      assert_equal "log/openai.log", logger.log_path
    end

    def test_log_does_nothing_when_disabled
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          logger = LlmLogger.new(provider_name: "openai", enabled: false)

          logger.log(query: "test query", response: "test response")

          refute File.exist?(logger.log_path)
        end
      end
    end

    def test_log_writes_to_file_when_enabled
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          logger = LlmLogger.new(provider_name: "testprovider", enabled: true)

          logger.log(query: "What is 2+2?", response: "4")

          assert File.exist?(logger.log_path)
          content = File.read(logger.log_path)
          assert_includes content, "What is 2+2?"
          assert_includes content, "4"
          assert_includes content, "--- QUERY ---"
          assert_includes content, "--- RESPONSE ---"
        end
      end
    end

    def test_log_appends_multiple_entries
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          logger = LlmLogger.new(provider_name: "testprovider", enabled: true)

          logger.log(query: "First query", response: "First response")
          logger.log(query: "Second query", response: "Second response")

          content = File.read(logger.log_path)
          assert_includes content, "First query"
          assert_includes content, "Second query"
        end
      end
    end

    def test_log_creates_directory_if_missing
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          refute File.exist?("log")

          logger = LlmLogger.new(provider_name: "testprovider", enabled: true)
          logger.log(query: "test", response: "test")

          assert File.directory?("log")
        end
      end
    end
  end
end
