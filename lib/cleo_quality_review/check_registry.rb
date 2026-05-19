# frozen_string_literal: true

require_relative "checks/fasterer"
require_relative "checks/flog"
require_relative "checks/reek"

module CleoQualityReview
  ##
  # Registry for available quality check implementations
  class CheckRegistry
    CHECKS = {
      "reek" => Checks::Reek,
      "flog" => Checks::Flog,
      "fasterer" => Checks::Fasterer,
    }.freeze
    ALIASES = {
      "fast-ruby" => "fasterer",
      "fast_ruby" => "fasterer",
    }.freeze

    ##
    # Resolve check names to check classes
    # @param [Array<String>] names check names to resolve
    # @return [Array<Class>] resolved check classes
    # @raise [ArgumentError] if an unknown check name is provided
    def self.resolve(names)
      new.resolve(names)
    end

    ##
    # Resolve check names to check classes
    # @param [Array<String>] names check names to resolve
    # @return [Array<Class>] resolved check classes
    # @raise [ArgumentError] if an unknown check name is provided
    def resolve(names)
      normalized_names = names.flat_map { |name| normalize_list_item(name) }

      return CHECKS.values if normalized_names.empty? || normalized_names.include?("all")

      normalized_names.map do |name|
        CHECKS.fetch(name) do
          raise ArgumentError, "Unknown check #{name.inspect}. Expected one of: #{CHECKS.keys.join(', ')}, all"
        end
      end.uniq
    end

    private

    def normalize_list_item(name)
      name.to_s.split(",").filter_map do |part|
        normalized = part.strip.downcase
        next if normalized.empty?

        ALIASES.fetch(normalized, normalized)
      end
    end
  end
end
