# frozen_string_literal: true

module CleoQualityReview
  ##
  # Namespace for bundled quality check implementations.
  module Checks
    require_relative "checks/registry"
    require_relative "checks/quality_check"
    require_relative "checks/reek"
    require_relative "checks/flog"
    require_relative "checks/fasterer"
    require_relative "checks/debride"

    class << self
      ##
      # Register a new check for use
      # @param [String] tool_name
      # @param [String, Symbol] tool_class_name
      # @param [String, Symbol] tool_type
      def register(tool_name, tool_class_name, tool_type: )
        Registry.register(tool_name.to_s, tool_class_name.to_s, tool_type: tool_type.to_s)
      end
    end
  end
end
