# frozen_string_literal: true

module CleoQualityReview
  class Error < StandardError; end
  class MissingLlmConfigurationError < Error; end
  class UnsupportedLlmProviderError < Error; end
  class LlmProviderError < Error; end
end
