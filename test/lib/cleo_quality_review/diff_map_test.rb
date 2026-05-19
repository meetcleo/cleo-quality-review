# frozen_string_literal: true

require_relative "../../test_helper"
require "cleo_quality_review/diff_map"

module CleoQualityReview
  class DiffMapTest < Minitest::Test
    def test_maps_right_side_lines_in_diff_hunks
      diff = <<~DIFF
        diff --git a/app/example.rb b/app/example.rb
        index 111..222 100644
        --- a/app/example.rb
        +++ b/app/example.rb
        @@ -1,3 +1,4 @@
         class Example
        -  def old
        +  def new
        +    true
         end
      DIFF

      map = DiffMap.new(diff)

      assert map.commentable?("app/example.rb", 1)
      assert map.commentable?("app/example.rb", 2)
      assert map.commentable?("app/example.rb", 3)
      assert map.commentable?("app/example.rb", 4)
      refute map.commentable?("app/example.rb", 5)
      refute map.commentable?("app/other.rb", 2)
    end
  end
end
