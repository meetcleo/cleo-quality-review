# frozen_string_literal: true

require_relative "test_helper"
require "cleo_quality_review/check_registry"

module CleoQualityReview
  class CheckRegistryTest < Minitest::Test
    def test_defaults_to_all_checks
      assert_equal %w[reek flog fasterer], CheckRegistry.resolve(["all"]).map(&:check_name)
    end

    def test_resolves_repeated_comma_separated_checks
      checks = CheckRegistry.resolve(["reek,flog", "reek"])

      assert_equal %w[reek flog], checks.map(&:check_name)
    end

    def test_resolves_fast_ruby_alias
      assert_equal ["fasterer"], CheckRegistry.resolve(["fast-ruby"]).map(&:check_name)
    end

    def test_rejects_unknown_checks
      error = assert_raises(ArgumentError) do
        CheckRegistry.resolve(["missing"])
      end

      assert_includes error.message, 'Unknown check "missing"'
    end
  end
end
