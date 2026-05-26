# frozen_string_literal: true

module CleoQualityReview
  ##
  # Registry for available quality check implementations
  class CheckRegistry
    Registration = Struct.new(:check_name, :class_name, :tool_type, keyword_init: true) do
      def check_class
        @check_class ||= constantize.tap { |klass| configure(klass) }
      end

      private

      def constantize
        parts = class_name.split("::").reject(&:empty?)
        root = parts.first == "CleoQualityReview" ? Object : CleoQualityReview

        parts.reduce(root) { |scope, const_name| scope.const_get(const_name) }
      end

      def configure(klass)
        klass.check_name = check_name
        klass.tool_name = check_name
        klass.tool_type = tool_type
      end
    end

    class << self
      ##
      # Register a quality check implementation
      # @param [String] name check identifier
      # @param [String] class_name class name under CleoQualityReview
      # @param [Symbol, String] tool_type category of tool findings
      # @return [void]
      def register(name, class_name, tool_type:)
        registration = Registration.new(
          check_name: normalize_name(name),
          class_name: class_name.to_s,
          tool_type: tool_type.to_s,
        )
        registrations[registration.check_name] = registration
        registration.check_class
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
    end

    ##
    # Resolve check names to check classes
    # @param [Array<String>] names check names to resolve
    # @return [Array<Class>] resolved check classes
    # @raise [ArgumentError] if an unknown check name is provided
    def resolve(names)
      normalized = normalize_names(names)
      return registrations.values.map(&:check_class) if all_checks_requested?(normalized)

      fetch_checks(normalized)
    end

    private

    def all_checks_requested?(normalized)
      normalized.empty? || normalized.include?("all")
    end

    def fetch_checks(normalized)
      normalized.map { |name| fetch_registration(name).check_class }.uniq
    end

    def normalize_names(names)
      names.flat_map { |name| normalize_list_item(name) }
    end

    def fetch_registration(name)
      registrations.fetch(name) do
        raise ArgumentError, "Unknown check #{name.inspect}. Expected one of: #{registrations.keys.join(', ')}, all"
      end
    end

    def normalize_list_item(name)
      name.to_s.split(",").filter_map do |part|
        normalized = part.strip.downcase
        next if normalized.empty?

        normalized
      end
    end

    def registrations
      self.class.send(:registrations)
    end
  end
end
