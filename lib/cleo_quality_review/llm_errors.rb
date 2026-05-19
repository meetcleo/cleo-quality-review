# frozen_string_literal: true

module CleoQualityReview
  ##
  # Base error class for CleoQualityReview
  class Error < StandardError; end

  ##
  # Raised when required LLM configuration is missing
  class MissingLlmConfigurationError < Error; end

  ##
  # Raised when an unsupported LLM provider is requested
  class UnsupportedLlmProviderError < Error; end

  ##
  # Base class for LLM provider-specific errors
  class LlmProviderError < Error; end
end
