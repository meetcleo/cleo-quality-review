# frozen_string_literal: true

require 'test_helper'

module CleoQualityReview
  class ChecksTest < Minitest::Test
    class Custom < CleoQualityReview::Checks::QualityCheck
    end

    def test_register_registers_the_check_with_name_class_and_tool_type
      class_name = '::CleoQualityReview::ChecksTest::Custom'
      assert_equal false, CleoQualityReview::Checks.registered?('Foo')

      check = CleoQualityReview::Checks.register("Foo", class_name, tool_type: "foo")

      assert_equal true, CleoQualityReview::Checks.registered?('Foo')
      assert_equal true, CleoQualityReview::Checks.registered?('foo')
    end
  end
end
