# frozen_string_literal: true

require 'test_helper'

module CleoQualityReview
  class ChecksTest < Minitest::Test
    class Custom < CleoQualityReview::Checks::QualityCheck
    end

    def setup
      @original_registrations = CleoQualityReview::Checks::Registry.instance_variable_get(:@registrations)
      CleoQualityReview::Checks::Registry.instance_variable_set(:@registrations, {})
    end

    def teardown
      CleoQualityReview::Checks::Registry.instance_variable_set(:@registrations, @original_registrations)
    end

    def test_register_registers_the_check_with_name_class_and_tool_type
      assert_equal false, CleoQualityReview::Checks.registered?('Foo')

      CleoQualityReview::Checks.register("Foo", Custom, tool_type: "foo")

      assert_equal true, CleoQualityReview::Checks.registered?('Foo')
      assert_equal true, CleoQualityReview::Checks.registered?('foo')
    end

    def test_resolve_resolves_through_module
      CleoQualityReview::Checks.register("Foo", Custom, tool_type: "foo")

      assert_equal [Custom], CleoQualityReview::Checks.resolve(["foo"])
    end
  end
end
