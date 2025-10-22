# frozen_string_literal: true

module BetterTranslate
  # Direct text translator for non-YAML workflows
  #
  # Provides convenience methods for translating individual strings or batches
  # without requiring YAML files. Useful for runtime translation needs.
  #
  # @example Basic usage
  #   config = Configuration.new
  #   config.provider = :chatgpt
  #   config.openai_key = ENV['OPENAI_API_KEY']
  #   config.source_language = "en"
  #
  #   translator = DirectTranslator.new(config)
  #   result = translator.translate("Hello", to: "it", language_name: "Italian")
  #   #=> "Ciao"
  #
  # @example Batch translation
  #   results = translator.translate_batch(
  #     ["Hello", "Goodbye"],
  #     to: "it",
  #     language_name: "Italian"
  #   )
  #   #=> ["Ciao", "Arrivederci"]
  #
  class DirectTranslator
    # @return [Configuration] Configuration object
    attr_reader :config

    # Initialize direct translator
    #
    # @param config [Configuration] Configuration object (must be valid)
    # @raise [ConfigurationError] if configuration is invalid
    #
    # @example
    #   translator = DirectTranslator.new(config)
    #
    def initialize(config)
      @config = config
      # Validate provider is configured (minimal validation for DirectTranslator)
      raise ConfigurationError, "Provider must be configured" unless config.provider

      @provider = ProviderFactory.create(config.provider, config)
    end

    # Translate a single text string
    #
    # @param text [String] Text to translate
    # @param to [String, Symbol] Target language code (e.g., "it", :it)
    # @param language_name [String] Full language name (e.g., "Italian")
    #
    # @return [String] Translated text
    # @raise [ValidationError] if text or language_code is invalid
    # @raise [TranslationError] if translation fails
    #
    # @example
    #   translator.translate("Hello", to: "it", language_name: "Italian")
    #   #=> "Ciao"
    #
    def translate(text, to:, language_name:)
      Validator.validate_text!(text)
      target_lang_code = to.to_s
      Validator.validate_language_code!(target_lang_code)

      @provider.translate_text(text, target_lang_code, language_name)
    rescue ValidationError
      raise # Re-raise validation errors without wrapping
    rescue ApiError, StandardError => e
      raise TranslationError.new(
        "Failed to translate text: #{e.message}",
        context: { text: text, target_lang: target_lang_code, original_error: e }
      )
    end

    # Translate multiple text strings
    #
    # @param texts [Array<String>] Array of texts to translate
    # @param to [String, Symbol] Target language code
    # @param language_name [String] Full language name
    # @param skip_errors [Boolean] Continue on error, returning nil for failed translations (default: false)
    #
    # @return [Array<String, nil>] Array of translated texts (nil for errors if skip_errors: true)
    # @raise [ArgumentError] if texts is not an Array
    # @raise [ValidationError] if any text is invalid
    # @raise [TranslationError] if translation fails (unless skip_errors: true)
    #
    # @example
    #   translator.translate_batch(
    #     ["Hello", "Goodbye"],
    #     to: "it",
    #     language_name: "Italian"
    #   )
    #   #=> ["Ciao", "Arrivederci"]
    #
    # @example With error handling
    #   translator.translate_batch(
    #     ["Hello", "Goodbye"],
    #     to: "it",
    #     language_name: "Italian",
    #     skip_errors: true
    #   )
    #   #=> ["Ciao", nil] # If second translation fails
    #
    def translate_batch(texts, to:, language_name:, skip_errors: false)
      raise ArgumentError, "texts must be an Array" unless texts.is_a?(Array)

      return [] if texts.empty?

      # Validate all texts first
      texts.each { |text| Validator.validate_text!(text) }

      target_lang_code = to.to_s
      Validator.validate_language_code!(target_lang_code)

      # Translate each text
      texts.map do |text|
        @provider.translate_text(text, target_lang_code, language_name)
      rescue ApiError, StandardError => e
        unless skip_errors
          raise TranslationError.new(
            "Failed to translate text: #{e.message}",
            context: { text: text, target_lang: target_lang_code, original_error: e }
          )
        end

        nil
      end
    end
  end
end
