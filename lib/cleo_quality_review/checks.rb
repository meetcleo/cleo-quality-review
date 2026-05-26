# frozen_string_literal: true

module CleoQualityReview
  ##
  # Namespace for bundled quality check implementations.
  module Checks
    require_relative "checks/quality_check"
    require_relative "checks/reek"
    require_relative "checks/flog"
    require_relative "checks/fasterer"
    require_relative "checks/debride"
  end
end
