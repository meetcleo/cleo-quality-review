# frozen_string_literal: true

require "cleo_quality_review"
require_relative "../test_helper"
require "cleo_quality_review/check_registry"

module CleoQualityReview
  class RequireTest < Minitest::Test
    def test_gem_name_require_path_loads
      assert defined?(CleoQualityReview::VERSION)
    end

    def test_gem_name_require_path_registers_default_checks
      checks = CheckRegistry.resolve(["all"])

      assert_equal %w[reek flog fasterer], checks.map(&:check_name)
      assert_equal %w[smell_detection complexity performance], checks.map(&:tool_type)
    end
  end
end
