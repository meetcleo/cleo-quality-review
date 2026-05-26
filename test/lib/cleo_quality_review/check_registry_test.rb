# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/checks/quality_check"
require "cleo_quality_review/check_registry"

module CleoQualityReview
  module Checks
    class Custom < QualityCheck
    end
  end

  class CheckRegistryTest < Minitest::Test
    def setup
      @original_registrations = CheckRegistry.instance_variable_get(:@registrations)
      CheckRegistry.instance_variable_set(:@registrations, {})
    end

    def teardown
      CheckRegistry.instance_variable_set(:@registrations, @original_registrations)
    end

    def test_register_resolves_registered_class_name_with_metadata
      CheckRegistry.register("Custom", "Checks::Custom", tool_type: :custom_type)

      check = CheckRegistry.resolve(["custom"]).first

      assert_equal Checks::Custom, check
      assert_equal "custom", check.check_name
      assert_equal "custom", check.tool_name
      assert_equal "custom_type", check.tool_type
    end

    def test_defaults_to_all_checks
      register_default_checks

      checks = CheckRegistry.resolve(["all"])

      assert_equal %w[reek flog fasterer debride], checks.map(&:check_name)
      assert_equal %w[smell_detection complexity performance dead_code], checks.map(&:tool_type)
    end

    def test_resolves_repeated_comma_separated_checks
      register_default_checks

      checks = CheckRegistry.resolve(["reek,flog", "reek"])

      assert_equal %w[reek flog], checks.map(&:check_name)
    end

    def test_rejects_dropped_fast_ruby_alias
      register_default_checks

      %w[fast-ruby fast_ruby].each do |alias_name|
        assert_raises(ArgumentError) do
          CheckRegistry.resolve([alias_name])
        end
      end
    end

    def test_resolves_debride
      register_default_checks

      checks = CheckRegistry.resolve(["debride"])

      assert_equal ["debride"], checks.map(&:check_name)
      assert_equal ["dead_code"], checks.map(&:tool_type)
    end

    def test_rejects_unknown_checks
      register_default_checks

      error = assert_raises(ArgumentError) do
        CheckRegistry.resolve(["missing"])
      end
      message = error.message

      assert_includes message, 'Unknown check "missing"'
      assert_includes message, "Expected one of: reek, flog, fasterer, debride, all"
    end

    private

    def register_default_checks
      load File.expand_path("../../../lib/cleo_quality_review.rb", __dir__)
    end
  end
end
