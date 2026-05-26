# frozen_string_literal: true

module CleoQualityReview
  module Checks
  end
end

Dir[File.join(__dir__, "checks", "*.rb")].sort.each { |path| require path }
