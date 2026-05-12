# frozen_string_literal: true

module CleoQuality
  Result = Struct.new(
    :tool,
    :check,
    :timestamp,
    :result,
    :filepath,
    :line,
    keyword_init: true,
  ) do
    def to_h
      {
        tool: tool,
        check: check,
        timestamp: timestamp,
        result: result,
        filepath: filepath,
        line: line,
      }.compact
    end
  end
end
