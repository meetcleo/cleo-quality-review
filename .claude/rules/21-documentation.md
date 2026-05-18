# Documentation

## RBS Type Annotations

All Ruby code in `app/` and `lib/` must be fully documented with valid inline Yard / RDoc comments.

### Requirements

- All public methods must have Yard / RDoc type signatures
- Method parameters must be typed
- Return types must be specified
- Known raised exceptions must be specified

### Format

```ruby
##
# Example class used for demonstration
class Example
  ##
  # Process an example with given input
  # @param [String] input
  # @param [Integer] count
  # @return [Boolean]
  def process(input, count:)
    # implementation
  end

  ##
  # Perform the work.
  # @return [void]
  def perform
    # implementation
  end

  ##
  # Find a +User+ with given params
  # @param [Integer] user_id
  # @param [Hash{Symbol => String}] options
  def find_user(user_id:, options: {})
    # implementation
  end
end
```

### Benefits

- Improves code clarity and maintainability
- Enables better tooling support
- Documents intent alongside implementation
- Provides type checking capabilities
