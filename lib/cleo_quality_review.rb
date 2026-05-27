# frozen_string_literal: true

##
# Quality review tool for Ruby code analysis
module CleoQualityReview
  class Error < StandardError;end

  require_relative "cleo_quality_review/version"
  require_relative "cleo_quality_review/checks"
  require_relative "cleo_quality_review/llm_providers"

  ##
  # Register all supported tools for analysing code here
  Checks.register("Reek", Checks::Reek, tool_type: :smell_detection)
  Checks.register("Flog", Checks::Flog, tool_type: :complexity)
  Checks.register("Fasterer", Checks::Fasterer, tool_type: :performance)
  Checks.register("Debride", Checks::Debride, tool_type: :dead_code)

  ##
  # Register all supported LLM APIs for formatting output here
  LlmProviders.register("openai", LlmProviders::OpenAi::Provider)
  LlmProviders.register("stub", LlmProviders::Stub::Provider)
end
