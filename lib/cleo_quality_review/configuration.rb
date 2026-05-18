# frozen_string_literal: true

require "set"
require "yaml"

module CleoQualityReview
  class Configuration
    DEFAULT_CONFIG_PATH = File.expand_path("../../config/default.yml", __dir__)
    LOCAL_CONFIG_PATH = ".cleo_quality_review.yaml"
    ALL_COPS = "AllCops"
    INCLUDE = "Include"
    EXCLUDE = "Exclude"
    INHERIT_FROM = "inherit_from"
    GEM_DEFAULT_ALIASES = ["default", "gem:default"].freeze
    MATCH_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB

    def self.load(root: Dir.pwd)
      Loader.new(root: root).load
    end

    def initialize(data)
      @data = data
    end

    def include_patterns
      patterns_for(INCLUDE)
    end

    def exclude_patterns
      patterns_for(EXCLUDE)
    end

    def target_file?(path)
      normalized_path = normalize_path(path)

      matches_any?(include_patterns, normalized_path) && !matches_any?(exclude_patterns, normalized_path)
    end

    private

    attr_reader :data

    def patterns_for(key)
      Array(data.fetch(ALL_COPS) { {} }.fetch(key) { [] }).map(&:to_s)
    end

    def matches_any?(patterns, path)
      patterns.any? { |pattern| matches?(pattern, path) }
    end

    def matches?(pattern, path)
      normalized_pattern = normalize_pattern(pattern)

      File.fnmatch?(normalized_pattern, path, MATCH_FLAGS)
    end

    def normalize_path(path)
      path.to_s.delete_prefix("./").tr(File::ALT_SEPARATOR || File::SEPARATOR, File::SEPARATOR).tr("\\", "/")
    end

    def normalize_pattern(pattern)
      pattern.to_s.delete_prefix("./").tr("\\", "/")
    end

    class Loader
      def initialize(root:)
        @root = File.expand_path(root)
      end

      def load
        data = load_file(DEFAULT_CONFIG_PATH)
        local_config_path = File.join(root, LOCAL_CONFIG_PATH)
        data = merge(data, load_file(local_config_path)) if File.file?(local_config_path)

        Configuration.new(data)
      end

      private

      attr_reader :root

      def load_file(path, seen: Set.new)
        expanded_path = expand_config_path(path, relative_to: root)
        return {} if seen.include?(expanded_path)
        raise ArgumentError, "Config file not found: #{expanded_path}" unless File.file?(expanded_path)

        seen.add(expanded_path)
        config = read_yaml(expanded_path)
        inherited_data = inherit_from(config).reduce({}) do |merged, inherited_path|
          merge(merged, load_file(resolve_inherited_path(inherited_path, expanded_path), seen: seen))
        end

        merge(inherited_data, config.except(INHERIT_FROM))
      end

      def read_yaml(path)
        parsed = YAML.safe_load(File.read(path), aliases: true)
        return {} if parsed.nil?
        raise ArgumentError, "Config file must contain a YAML mapping: #{path}" unless parsed.is_a?(Hash)

        stringify_keys(parsed)
      end

      def inherit_from(config)
        Array(config.fetch(INHERIT_FROM) { [] })
      end

      def resolve_inherited_path(path, parent_path)
        value = path.to_s
        return DEFAULT_CONFIG_PATH if GEM_DEFAULT_ALIASES.include?(value)

        expand_config_path(value, relative_to: File.dirname(parent_path))
      end

      def expand_config_path(path, relative_to:)
        expanded_path = File.expand_path(path.to_s)
        return expanded_path if path.to_s.start_with?("/", "~")

        File.expand_path(path.to_s, relative_to)
      end

      def merge(base, override)
        base.merge(override) do |_key, base_value, override_value|
          merge_values(base_value, override_value)
        end
      end

      def merge_values(base_value, override_value)
        if base_value.is_a?(Hash) && override_value.is_a?(Hash)
          merge(base_value, override_value)
        elsif base_value.is_a?(Array) && override_value.is_a?(Array)
          (base_value + override_value).uniq
        else
          override_value
        end
      end

      def stringify_keys(value)
        case value
        when Hash
          value.to_h { |key, nested_value| [key.to_s, stringify_keys(nested_value)] }
        when Array
          value.map { |nested_value| stringify_keys(nested_value) }
        else
          value
        end
      end
    end
  end
end
