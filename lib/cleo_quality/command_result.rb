# frozen_string_literal: true

module CleoQuality
  CommandResult = Struct.new(:stdout, :stderr, :status, keyword_init: true) do
    def success?
      status.success?
    end
  end
end
