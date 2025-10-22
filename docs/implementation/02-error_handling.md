# 02 - Error Handling

[← Previous: 01-Setup Dependencies](./01-setup_dependencies.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 03-Core Components →](./03-core_components.md)

---

## Error Handling

### 2.1 `lib/better_translate/errors.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  # Base error class for all BetterTranslate errors
  #
  # @abstract
  class Error < StandardError
    # @return [Hash] Additional context about the error
    attr_reader :context

    # Initialize a new error with optional context
    #
    # @param message [String] The error message
    # @param context [Hash] Additional context information
    def initialize(message = nil, context: {})
      @context = context
      super(message)
    end
  end

  # Raised when configuration is invalid or incomplete
  class ConfigurationError < Error; end

  # Raised when input validation fails
  class ValidationError < Error; end

  # Raised when translation fails
  class TranslationError < Error; end

  # Raised when a provider encounters an error
  class ProviderError < Error; end

  # Raised when an API call fails
  class ApiError < Error; end

  # Raised when rate limit is exceeded
  class RateLimitError < ApiError; end

  # Raised when file operations fail
  class FileError < Error; end

  # Raised when YAML parsing fails
  class YamlError < Error; end

  # Raised when a provider is not found
  class ProviderNotFoundError < Error; end
end
```

---

---

[← Previous: 01-Setup Dependencies](./01-setup_dependencies.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 03-Core Components →](./03-core_components.md)
