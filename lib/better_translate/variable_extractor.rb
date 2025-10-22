# frozen_string_literal: true

module BetterTranslate
  # Extracts and preserves interpolation variables during translation
  #
  # Supports multiple variable formats:
  # - Rails I18n: %{name}, %{count}
  # - I18n.js: {{user}}, {{email}}
  # - ES6 templates: ${var}
  # - Simple braces: {name}
  #
  # Variables are extracted before translation, replaced with safe placeholders,
  # and then restored after translation to ensure they remain unchanged.
  #
  # @example Basic usage
  #   extractor = VariableExtractor.new("Hello %{name}, you have {{count}} messages")
  #   safe_text = extractor.extract
  #   #=> "Hello __VAR_0__, you have __VAR_1__ messages"
  #
  #   translated = translate(safe_text)  # "Ciao __VAR_0__, hai __VAR_1__ messaggi"
  #   final = extractor.restore(translated)
  #   #=> "Ciao %{name}, hai {{count}} messaggi"
  #
  # @example Variable validation
  #   extractor = VariableExtractor.new("Total: %{amount}")
  #   extractor.extract
  #   extractor.validate_variables!("Totale: %{amount}")  #=> true
  #   extractor.validate_variables!("Totale:")  # raises ValidationError
  #
  class VariableExtractor
    # Variable patterns to detect and preserve
    VARIABLE_PATTERNS = {
      rails_template: /%\{[^}]+\}/, # %{name}, %{count}
      rails_annotated: /%<[^>]+>[a-z]/i,    # %<name>s, %<count>d
      i18n_js: /\{\{[^}]+\}\}/,             # {{user}}, {{email}}
      es6: /\$\{[^}]+\}/,                   # ${var}
      simple: /\{[a-zA-Z_][a-zA-Z0-9_]*\}/  # {name} but not {1,2,3}
    }.freeze

    # Combined pattern to match any variable format
    COMBINED_PATTERN = Regexp.union(*VARIABLE_PATTERNS.values).freeze

    # Placeholder prefix
    PLACEHOLDER_PREFIX = "__VAR_"

    # Placeholder suffix
    PLACEHOLDER_SUFFIX = "__"

    # @return [String] Original text with variables
    attr_reader :original_text

    # @return [Array<String>] Extracted variables in order
    attr_reader :variables

    # @return [Hash<String, String>] Mapping of placeholders to original variables
    attr_reader :placeholder_map

    # Initialize extractor with text
    #
    # @param text [String] Text containing variables
    #
    # @example
    #   extractor = VariableExtractor.new("Hello %{name}")
    #
    def initialize(text)
      @original_text = text
      @variables = []
      @placeholder_map = {}
      @reverse_map = {}
    end

    # Extract variables and replace with placeholders
    #
    # Scans the text for all supported variable formats and replaces them
    # with numbered placeholders (__VAR_0__, __VAR_1__, etc.).
    #
    # @return [String] Text with variables replaced by placeholders
    #
    # @example
    #   extractor = VariableExtractor.new("Hello %{name}")
    #   extractor.extract  #=> "Hello __VAR_0__"
    #
    def extract
      return "" if original_text.nil? || original_text.empty?

      result = original_text.dup
      index = 0

      # Find and replace all variables
      result.gsub!(COMBINED_PATTERN) do |match|
        placeholder = "#{PLACEHOLDER_PREFIX}#{index}#{PLACEHOLDER_SUFFIX}"
        @variables << match
        @placeholder_map[placeholder] = match
        @reverse_map[match] = placeholder
        index += 1
        placeholder
      end

      result
    end

    # Restore variables from placeholders in translated text
    #
    # Replaces all placeholders with their original variable formats.
    # In strict mode, validates that all original variables are present.
    #
    # @param translated_text [String] Translated text with placeholders
    # @param strict [Boolean] If true, raises error if variables are missing
    # @return [String] Translated text with original variables restored
    # @raise [ValidationError] if strict mode and variables are missing
    #
    # @example Successful restore
    #   extractor = VariableExtractor.new("Hello %{name}")
    #   extractor.extract
    #   extractor.restore("Ciao __VAR_0__")  #=> "Ciao %{name}"
    #
    # @example Strict mode with missing variable
    #   extractor = VariableExtractor.new("Hello %{name}")
    #   extractor.extract
    #   extractor.restore("Ciao", strict: true)  # raises ValidationError
    #
    def restore(translated_text, strict: true)
      return "" if translated_text.nil? || translated_text.empty?

      result = translated_text.dup

      # Restore all placeholders
      @placeholder_map.each do |placeholder, original_var|
        result.gsub!(placeholder, original_var)
      end

      # Validate all variables are present
      validate_variables!(result) if strict

      result
    end

    # Check if text contains variables
    #
    # @return [Boolean] true if variables are present
    #
    # @example
    #   extractor = VariableExtractor.new("Hello %{name}")
    #   extractor.extract
    #   extractor.variables?  #=> true
    #
    def variables?
      !@variables.empty?
    end

    # Get count of variables
    #
    # @return [Integer] Number of variables
    #
    # @example
    #   extractor = VariableExtractor.new("Hi %{name}, {{count}} items")
    #   extractor.extract
    #   extractor.variable_count  #=> 2
    #
    def variable_count
      @variables.size
    end

    # Validate that all original variables are present in text
    #
    # Checks that:
    # 1. All original variables are still present
    # 2. No unexpected/extra variables have been added
    #
    # @param text [String] Text to validate
    # @raise [ValidationError] if variables are missing or modified
    # @return [true] if all variables are present
    #
    # @example Valid text
    #   extractor = VariableExtractor.new("Hello %{name}")
    #   extractor.extract
    #   extractor.validate_variables!("Ciao %{name}")  #=> true
    #
    # @example Missing variable
    #   extractor = VariableExtractor.new("Hello %{name}")
    #   extractor.extract
    #   extractor.validate_variables!("Ciao")  # raises ValidationError
    #
    def validate_variables!(text)
      # @type var missing: Array[String]
      missing = []
      # @type var extra: Array[String]
      extra = []

      # Check for missing variables
      @variables.each do |var|
        var_str = var.is_a?(String) ? var : var.to_s
        missing << var_str unless text.include?(var_str)
      end

      # Check for extra/unknown variables (potential corruption)
      found_vars = text.scan(COMBINED_PATTERN)
      found_vars.each do |var|
        var_str = var.is_a?(String) ? var : var.to_s
        extra << var_str unless @variables.include?(var_str)
      end

      if missing.any? || extra.any?
        # @type var error_msg: Array[String]
        error_msg = []
        error_msg << "Missing variables: #{missing.join(", ")}" if missing.any?
        error_msg << "Unexpected variables: #{extra.join(", ")}" if extra.any?

        raise ValidationError.new(
          "Variable validation failed: #{error_msg.join("; ")}",
          context: {
            original_variables: @variables,
            missing: missing,
            extra: extra,
            text: text
          }
        )
      end

      true
    end

    # Extract variables from text without creating instance
    #
    # Static method to find all variables in text without needing
    # to instantiate the extractor.
    #
    # @param text [String] Text to analyze
    # @return [Array<String>] List of variables found
    #
    # @example
    #   VariableExtractor.find_variables("Hi %{name}, {{count}} items")
    #   #=> ["%{name}", "{{count}}"]
    #
    def self.find_variables(text)
      return [] if text.nil? || text.empty?

      text.scan(COMBINED_PATTERN)
    end

    # Check if text contains variables
    #
    # Static method to quickly check if text contains any supported
    # variable format.
    #
    # @param text [String] Text to check
    # @return [Boolean] true if variables are present
    #
    # @example
    #   VariableExtractor.contains_variables?("Hello %{name}")  #=> true
    #   VariableExtractor.contains_variables?("Hello world")    #=> false
    #
    def self.contains_variables?(text)
      return false if text.nil? || text.empty?

      text.match?(COMBINED_PATTERN)
    end
  end
end
