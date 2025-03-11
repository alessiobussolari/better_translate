module BetterTranslate
  module Providers
    # Abstract base class for translation providers.
    # Provides common functionality and defines the interface that all providers must implement.
    # Handles rate limiting, input validation, and retry logic for failed translations.
    #
    # @abstract Subclass and override {#translate_text} to implement a provider
    class BaseProvider
      # Number of retry attempts for failed translations
      MAX_RETRIES = 3
      
      # Delay in seconds between retry attempts
      RETRY_DELAY = 2 # seconds
      
      # Initializes a new provider instance with the specified API key.
      #
      # @param api_key [String] The API key for the translation service
      # @return [BaseProvider] A new instance of the provider
      def initialize(api_key)
        @api_key = api_key
        @last_request_time = Time.now - 1
      end

      private

      # Implements a simple rate limiting mechanism to prevent overloading the API.
      # Ensures at least 0.5 seconds between consecutive requests.
      #
      # @return [void]
      def rate_limit
        time_since_last_request = Time.now - @last_request_time
        sleep(0.5 - time_since_last_request) if time_since_last_request < 0.5
        @last_request_time = Time.now
      end

      # Validates the input parameters for translation.
      # Ensures that the text is not empty and the language code is in a valid format.
      #
      # @param text [String] The text to translate
      # @param target_lang_code [String] The target language code (e.g., "en", "fr-FR")
      # @raise [ArgumentError] If the text is empty or the language code is invalid
      # @return [void]
      def validate_input(text, target_lang_code)
        raise ArgumentError, "Text cannot be empty" if text.nil? || text.strip.empty?
        raise ArgumentError, "Invalid target language code" unless target_lang_code.match?(/^[a-z]{2}(-[A-Z]{2})?$/)
      end

      # Public method to translate text with built-in retry logic.
      # Attempts to translate the text and retries on failure up to MAX_RETRIES times.
      #
      # @param text [String] The text to translate
      # @param target_lang_code [String] The target language code (e.g., "en")
      # @param target_lang_name [String] The target language name (e.g., "English")
      # @return [String] The translated text
      # @raise [StandardError] If translation fails after all retry attempts
      def translate(text, target_lang_code, target_lang_name)
        retries = 0
        begin
          perform_translation(text, target_lang_code, target_lang_name)
        rescue StandardError => e
          retries += 1
          if retries <= MAX_RETRIES
            message = "Translation attempt #{retries} failed. Retrying in #{RETRY_DELAY} seconds..."
            BetterTranslate::Utils.logger(message: message)
            sleep(RETRY_DELAY)
            retry
          else
            message = "Translation failed after #{MAX_RETRIES} attempts: #{e.message}"
            BetterTranslate::Utils.logger(message: message)
            raise
          end
        end
      end

      # Performs the actual translation process.
      # Validates input, applies rate limiting, and calls the provider-specific translation method.
      #
      # @param text [String] The text to translate
      # @param target_lang_code [String] The target language code
      # @param target_lang_name [String] The target language name
      # @return [String] The translated text
      def perform_translation(text, target_lang_code, target_lang_name)
        validate_input(text, target_lang_code)
        rate_limit
        translate_text(text, target_lang_code, target_lang_name)
      end

      # Provider-specific implementation of the translation logic.
      # Must be overridden by subclasses to implement the actual translation.
      #
      # @abstract
      # @param text [String] The text to translate
      # @param target_lang_code [String] The target language code
      # @param target_lang_name [String] The target language name
      # @return [String] The translated text
      # @raise [NotImplementedError] If the method is not overridden by a subclass
      def translate_text(text, target_lang_code, target_lang_name)
        raise NotImplementedError, "The provider #{self.class} must implement the translate_text method"
      end
    end
  end
end
