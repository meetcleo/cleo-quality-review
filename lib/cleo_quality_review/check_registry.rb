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
      normalized = normalize_names(names)
      return CHECKS.values if normalized.empty? || normalized.include?("all")

      normalized.map { |name| fetch_check(name) }.uniq
    end

    private

    def normalize_names(names)
      names.flat_map { |name| normalize_list_item(name) }
    end

    def fetch_check(name)
      CHECKS.fetch(name) do
        raise ArgumentError, "Unknown check #{name.inspect}. Expected one of: #{CHECKS.keys.join(', ')}, all"
      end
    end

    def normalize_list_item(name)
      name.to_s.split(",").filter_map do |part|
        normalized = part.strip.downcase
        next if normalized.empty?

        ALIASES.fetch(normalized, normalized)
      end
    end
  end
end
