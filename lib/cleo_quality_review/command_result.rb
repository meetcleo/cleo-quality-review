# frozen_string_literal: true

module CleoQualityReview
  ##
  # Value object representing the result of a shell command execution
  #
  # @!attribute [r] stdout
  #   @return [String] standard output from the command
  # @!attribute [r] stderr
  #   @return [String] standard error from the command
  # @!attribute [r] status
  #   @return [Process::Status] process exit status
  CommandResult = Struct.new(:stdout, :stderr, :status, keyword_init: true) do
    ##
    # Check if the command succeeded
    # @return [Boolean]
    def success?
      status.success?
    end
  end
end
