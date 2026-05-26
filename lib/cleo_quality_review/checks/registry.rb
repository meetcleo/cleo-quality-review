# frozen_string_literal: true

module CleoQualityReview
  ##
  # Registry for available quality check implementations
  class Registry
    class << self
      ##
      # Register a quality check implementation
      # @param [String] name check identifier
      # @param [String] class_name class name under CleoQualityReview
      # @param [Symbol, String] tool_type category of tool findings
      # @return [void]
      def register(name, class_name, tool_type:)
        check_name = normalize_name(name)
        klass = constantize(class_name.to_s)
        configure(klass, check_name, tool_type.to_s)
        registrations[check_name] = klass
        nil
      end

      ##
      # Resolve check names to check classes
      # @param [Array<String>] names check names to resolve
      # @return [Array<Class>] resolved check classes
      # @raise [ArgumentError] if an unknown check name is provided
      def resolve(names)
        new.resolve(names)
      end

      private

      def registrations
        @registrations ||= {}
      end

      def normalize_name(name)
        name.to_s.strip.downcase
      end

      def constantize(class_name)
        parts = class_name.split("::").reject(&:empty?)
        root = parts.first == "CleoQualityReview" ? Object : CleoQualityReview

        parts.reduce(root) { |scope, const_name| scope.const_get(const_name) }
      end

      def configure(klass, check_name, tool_type)
        klass.check_name = check_name
        klass.tool_name = check_name
        klass.tool_type = tool_type
      end
    end

    ##
    # Resolve check names to check classes
    # @param [Array<String>] names check names to resolve
    # @return [Array<Class>] resolved check classes
    # @raise [ArgumentError] if an unknown check name is provided
    def resolve(names)
      normalized = names.map(&:to_s).join(",").split(",").map(&:strip).map(&:downcase).reject(&:empty?)
      return registrations.values if normalized.empty? || normalized.include?("all")

      fetch_checks(normalized)
    end

    private

    def fetch_checks(normalized)
      normalized.map { |name| fetch_check(name) }.uniq
    end

    def fetch_check(name)
      registrations.fetch(name) do
        raise ArgumentError, "Unknown check #{name.inspect}. Expected one of: #{registrations.keys.join(', ')}, all"
      end
    end

    def registrations
      self.class.send(:registrations)
    end
  end
end
