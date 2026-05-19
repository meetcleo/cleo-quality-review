# frozen_string_literal: true

module CleoQualityReview
  ##
  # Value object representing a single finding from a quality check
  #
  # @!attribute [r] tool
  #   @return [String] name of the tool that produced this result
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
    :tool,
    :check,
    :timestamp,
    :result,
    :filepath,
    :line,
    keyword_init: true,
  ) do
    ##
    # Convert the result to a hash, omitting nil values
    # @return [Hash{Symbol => Object}]
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
