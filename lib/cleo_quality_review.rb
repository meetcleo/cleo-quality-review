# frozen_string_literal: true

##
# Quality review tool for Ruby code analysis
module CleoQualityReview
  require_relative "cleo_quality_review/version"
  require_relative "cleo_quality_review/check_registry"
  require_relative "cleo_quality_review/checks"

  CheckRegistry.register("Reek", "Checks::Reek", tool_type: :smell_detection)
  CheckRegistry.register("Flog", "Checks::Flog", tool_type: :complexity)
  CheckRegistry.register("Fasterer", "Checks::Fasterer", tool_type: :performance)
end
