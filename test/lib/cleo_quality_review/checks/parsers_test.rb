# frozen_string_literal: true

require_relative "../../../test_helper"
require "cleo_quality_review/checks/debride"
require "cleo_quality_review/checks/fasterer"
require "cleo_quality_review/checks/flog"
require "cleo_quality_review/checks/reek"

module CleoQualityReview
  module Checks
    class ParsersTest < Minitest::Test
      FakeCommandRunner = Struct.new(:command_result, keyword_init: true) do
        def run(*)
          command_result
        end
      end

      private

      def runner(stdout)
        FakeCommandRunner.new(command_result: command_result(stdout: stdout))
      end
    end
  end
end
