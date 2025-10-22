# frozen_string_literal: true

module BetterTranslate
  # Input validation utilities
  #
  # Validates language codes, text, paths, and other inputs.
  #
  # @example Validate language code
  #   Validator.validate_language_code!("en")  #=> true
  #   Validator.validate_language_code!("invalid")  # raises ValidationError
  #
  class Validator
    # Validate a language code
    #
    # Language codes must be 2-letter strings (e.g., "en", "it", "fr").
    #
    # @param code [String] Language code to validate
    # @raise [ValidationError] if code is invalid
    # @return [true] if valid
    #
    # @example Valid codes
    #   Validator.validate_language_code!("en")  #=> true
    #   Validator.validate_language_code!("IT")  #=> true
    #
    # @example Invalid codes
    #   Validator.validate_language_code!("eng")  # raises ValidationError
    #   Validator.validate_language_code!(nil)    # raises ValidationError
    #
    def self.validate_language_code!(code)
      raise ValidationError, "Language code cannot be nil" if code.nil?
      raise ValidationError, "Language code must be a String" unless code.is_a?(String)
      raise ValidationError, "Language code cannot be empty" if code.empty?
      raise ValidationError, "Language code must be 2 letters" unless code.match?(/^[a-z]{2}$/i)

      true
    end

    # Validate text for translation
    #
    # Text must be a non-empty string.
    #
    # @param text [String] Text to validate
    # @raise [ValidationError] if text is invalid
    # @return [true] if valid
    #
    # @example Valid text
    #   Validator.validate_text!("Hello world")  #=> true
    #
    # @example Invalid text
    #   Validator.validate_text!("")      # raises ValidationError
    #   Validator.validate_text!("   ")   # raises ValidationError
    #
    def self.validate_text!(text)
      raise ValidationError, "Text cannot be nil" if text.nil?
      raise ValidationError, "Text must be a String" unless text.is_a?(String)
      raise ValidationError, "Text cannot be empty" if text.strip.empty?

      true
    end

    # Validate a file path exists
    #
    # @param path [String] File path to validate
    # @raise [FileError] if path is invalid
    # @return [true] if valid
    #
    # @example Valid path
    #   Validator.validate_file_exists!("config/locales/en.yml")  #=> true
    #
    # @example Invalid path
    #   Validator.validate_file_exists!("/nonexistent/file.yml")  # raises FileError
    #
    def self.validate_file_exists!(path)
      raise FileError, "File path cannot be nil" if path.nil?
      raise FileError, "File path must be a String" unless path.is_a?(String)
      raise FileError, "File does not exist: #{path}" unless File.exist?(path)

      true
    end

    # Validate an API key
    #
    # API keys must be non-empty strings.
    #
    # @param key [String] API key to validate
    # @param provider [Symbol] Provider name for error message
    # @raise [ConfigurationError] if key is invalid
    # @return [true] if valid
    #
    # @example Valid API key
    #   Validator.validate_api_key!("sk-test123", provider: :chatgpt)  #=> true
    #
    # @example Invalid API key
    #   Validator.validate_api_key!(nil, provider: :chatgpt)  # raises ConfigurationError
    #   Validator.validate_api_key!("", provider: :gemini)    # raises ConfigurationError
    #
    def self.validate_api_key!(key, provider:)
      raise ConfigurationError, "API key for #{provider} cannot be nil" if key.nil?
      raise ConfigurationError, "API key for #{provider} must be a String" unless key.is_a?(String)
      raise ConfigurationError, "API key for #{provider} cannot be empty" if key.strip.empty?

      true
    end
  end
end
