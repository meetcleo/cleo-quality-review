require 'test_helper'

module CleoQualityReview
  class Checks::RegistryTest < Minitest::Test
    def setup
      @original_registrations = CleoQualityReview::Checks::Registry.instance_variable_get(:@registrations)
      CleoQualityReview::Checks::Registry.instance_variable_set(:@registrations, {})
    end

    def teardown
      CleoQualityReview::Checks::Registry.instance_variable_set(:@registrations, @original_registrations)
    end

    def test_register_resolves_registered_class_name_with_metadata
      klass = Class.new(CleoQualityReview::Checks::QualityCheck) do
        self.check_name = 'custom-check-name'
        self.tool_name = 'custom-tool-name'
        self.tool_type = 'custom-tool-type'
      end

      CleoQualityReview::Checks::Registry.register("Custom", klass, tool_type: :custom_type)

      check = CleoQualityReview::Checks::Registry.resolve(["custom"]).first

      assert_equal klass, check
      assert_equal "custom-check-name", check.check_name
      assert_equal "custom-tool-name", check.tool_name
      assert_equal "custom-tool-type", check.tool_type
    end

    class CheckFoo < CleoQualityReview::Checks::QualityCheck; end
    class CheckBar < CleoQualityReview::Checks::QualityCheck; end

    def test_all_includes_all_registered_checks
      bar_class = Class.new(CleoQualityReview::Checks::QualityCheck)
      foo_class = Class.new(CleoQualityReview::Checks::QualityCheck)
      CleoQualityReview::Checks::Registry.register("bar", bar_class, tool_type: :custom_type)
      CleoQualityReview::Checks::Registry.register("foo", foo_class, tool_type: :custom_type)

      checks = CleoQualityReview::Checks::Registry.resolve(["all"])

      assert_includes checks, bar_class
      assert_includes checks, foo_class
      assert_equal 2, checks.size
    end


    def test_rejects_unknown_checks
      error = assert_raises(CleoQualityReview::Checks::Registry::UnknownCheckError) do
        CleoQualityReview::Checks::Registry.resolve(["missing"])
      end
      message = error.message

      assert_includes message, "Unknown check name: missing"
    end
  end
end
