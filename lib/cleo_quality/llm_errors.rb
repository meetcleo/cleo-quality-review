# frozen_string_literal: true

module CleoQuality
  class MissingLlmConfigurationError < StandardError; end
  class UnsupportedLlmProviderError < StandardError; end
  class LlmProviderError < StandardError; end
end
