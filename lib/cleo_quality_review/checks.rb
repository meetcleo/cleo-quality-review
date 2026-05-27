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
      # @param [Class] tool_class
      # @param [String, Symbol] tool_type
      # @return [nil]
      def register(tool_name, tool_class, tool_type: )
        Registry.register(tool_name.to_s, tool_class, tool_type: tool_type.to_s)
      end

      def resolve(tool_name)
        Registry.resolve(tool_name.to_s)
      end
      ##
      # Has a tool with the given name been registered?
      #
      # @param [String] tool_name
      # @return [Boolean]
      def registered?(tool_name)
        Registry.registered?(tool_name)
      end
    end
  end
end
