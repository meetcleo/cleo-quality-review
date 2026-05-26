# frozen_string_literal: true

module CleoQualityReview
  module Checks
    require_relative "checks/quality_check"
    require_relative "checks/reek"
    require_relative "checks/flog"
    require_relative "checks/fasterer"
  end
end
