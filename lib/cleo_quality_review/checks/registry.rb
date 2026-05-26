# frozen_string_literal: true

module CleoQualityReview
  module Checks
    ##
    # Registry for available quality check implementations
    class Registry
      class UnknownCheckError < CleoQualityReview::Error
        def initialize(name)
          super("Unknown check name: #{name}")
        end
      end

      class CheckName < DelegateClass(String)
        def initialize(name)
          super(name.to_s.downcase)
        end

      end

      Registration = Data.define(:check_name, :klass, :tool_type)
      class << self
        ##
        # Register a quality check implementation
        # @param [String] name check identifier
        # @param [Class] klass class name under CleoQualityReview
        # @param [Symbol, String] tool_type category of tool findings
        # @return [void]
        def register(name, klass, tool_type:)
          name = CheckName.new(name).to_s
          registration = Registration.new(check_name: name.to_s, klass: klass, tool_type: tool_type.to_s)
          registrations[name] = registration
          nil
        end

        ##
        # Resolve check names to check classes
        # @param [Array<String>] names check names to resolve
        # @return [Array<Class>] resolved check classes
        # @raise [ArgumentError] if an unknown check name is provided
        def resolve(names)
          names = ['all'] if names.empty?
          names_to_resolve = names.include?('all') ? @registrations.keys : names.map(&:to_s)
          require 'debug'

          names_to_resolve.map do |name|
            begin
              name = CheckName.new(name).to_s
              registration = registrations[name]
              raise UnknownCheckError.new(name) unless registration

              registration.klass
            rescue NameError
              raise UnknownCheckError.new(name)
            end
          end
        end

        def registered?(tool_name)
          registrations.key?(CheckName.new(tool_name))
        end

        private

        def registrations
          @registrations ||= {}
        end
      end
    end
  end
end
