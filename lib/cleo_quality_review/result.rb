# frozen_string_literal: true

module CleoQualityReview
  ##
  # Value object representing a single finding from a quality check
  #
  # @!attribute [r] tool_name
  #   @return [String] name of the tool that produced this result
  # @!attribute [r] tool_type
  #   @return [String] category for the tool that produced this result
  # @!attribute [r] check
  #   @return [String] specific check or rule that triggered
  # @!attribute [r] timestamp
  #   @return [Integer] epoch milliseconds when the check ran
  # @!attribute [r] result
  #   @return [String] description of the finding
  # @!attribute [r] filepath
  #   @return [String, nil] path to the file with the issue
  # @!attribute [r] line
  #   @return [Integer, nil] line number of the issue
  Result = Struct.new(
    :tool_name,
    :tool_type,
    :check,
    :timestamp,
    :result,
    :filepath,
    :line,
    keyword_init: true,
  ) do
    def self.from_h(hash)
      new(
        tool_name: hash["tool_name"] || hash["tool"],
        tool_type: hash["tool_type"],
        check: hash["check"],
        timestamp: hash["timestamp"],
        result: hash["result"],
        filepath: hash["filepath"],
        line: hash["line"],
      )
    end

    ##
    # Convert the result to a hash, omitting nil values
    # @return [Hash{Symbol => Object}]
    def to_h
      {
        tool_name: tool_name,
        tool_type: tool_type,
        check: check,
        timestamp: timestamp,
        result: result,
        filepath: filepath,
        line: line,
      }.compact
    end
  end
end
