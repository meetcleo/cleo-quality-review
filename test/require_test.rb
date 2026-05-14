# frozen_string_literal: true

require "cleo_quality_review"
require_relative "test_helper"

module CleoQualityReview
  class RequireTest < Minitest::Test
    def test_gem_name_require_path_loads
      assert defined?(CleoQualityReview::VERSION)
    end
  end
end
