# frozen_string_literal: true

##
# Quality review tool for Ruby code analysis
module CleoQualityReview
  require_relative "cleo_quality_review/version"
  require_relative "cleo_quality_review/check_registry"
  require_relative "cleo_quality_review/checks"
  require_relative "cleo_quality_review/llm_provider_registry"

  ##
  # Register all supported tools for analysing code here
  CheckRegistry.register("Reek", "Checks::Reek", tool_type: :smell_detection)
  CheckRegistry.register("Flog", "Checks::Flog", tool_type: :complexity)
  CheckRegistry.register("Fasterer", "Checks::Fasterer", tool_type: :performance)

  ##
  # Register all supported LLM APIs for formatting output here
  LlmProviderRegistry.register( "openai", :OpenAiLlmProvider)
end
