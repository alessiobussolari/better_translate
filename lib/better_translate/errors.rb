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
  #
  # @example Raising with context
  #   raise ConfigurationError.new(
  #     "Invalid provider",
  #     context: { provider: :invalid_name }
  #   )
  class ConfigurationError < Error; end

  # Raised when input validation fails
  #
  # @example File validation failure
  #   raise ValidationError.new(
  #     "File does not exist",
  #     context: { file_path: "/path/to/file.yml" }
  #   )
  class ValidationError < Error; end

  # Raised when translation fails
  #
  # @example Translation error
  #   raise TranslationError.new(
  #     "Failed to translate text",
  #     context: { text: "Hello", target_lang: "it" }
  #   )
  class TranslationError < Error; end

  # Raised when a provider encounters an error
  #
  # @example Provider initialization error
  #   raise ProviderError.new(
  #     "Provider not initialized",
  #     context: { provider: :chatgpt }
  #   )
  class ProviderError < Error; end

  # Raised when an API call fails
  #
  # @example API call failure
  #   raise ApiError.new(
  #     "API request failed",
  #     context: { status_code: 500, response: "Internal Server Error" }
  #   )
  class ApiError < Error; end

  # Raised when rate limit is exceeded
  #
  # @example Rate limit error
  #   raise RateLimitError.new(
  #     "Rate limit exceeded",
  #     context: { retry_after: 60 }
  #   )
  class RateLimitError < ApiError; end

  # Raised when file operations fail
  #
  # @example File read error
  #   raise FileError.new(
  #     "Cannot read file",
  #     context: { file_path: "config/locales/en.yml", error: "Permission denied" }
  #   )
  class FileError < Error; end

  # Raised when YAML parsing fails
  #
  # @example YAML syntax error
  #   raise YamlError.new(
  #     "Invalid YAML syntax",
  #     context: { file_path: "config/locales/en.yml", line: 5 }
  #   )
  class YamlError < Error; end

  # Raised when JSON parsing fails
  #
  # @example JSON syntax error
  #   raise JsonError.new(
  #     "Invalid JSON syntax",
  #     context: { file_path: "config/locales/en.json", error: "unexpected token" }
  #   )
  class JsonError < Error; end

  # Raised when a provider is not found
  #
  # @example Provider not found
  #   raise ProviderNotFoundError.new(
  #     "Provider 'unknown' not found",
  #     context: { provider: :unknown, available: [:chatgpt, :gemini, :anthropic] }
  #   )
  class ProviderNotFoundError < Error; end
end
