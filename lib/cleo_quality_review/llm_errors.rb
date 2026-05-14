# frozen_string_literal: true

module CleoQualityReview
  class MissingLlmConfigurationError < StandardError; end
  class UnsupportedLlmProviderError < StandardError; end
  class LlmProviderError < StandardError; end
end
