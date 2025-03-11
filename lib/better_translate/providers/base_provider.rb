module BetterTranslate
  module Providers
    class BaseProvider
      def initialize(api_key)
        @api_key = api_key
        @last_request_time = Time.now - 1
      end

      private

      def rate_limit
        time_since_last_request = Time.now - @last_request_time
        sleep(0.5 - time_since_last_request) if time_since_last_request < 0.5
        @last_request_time = Time.now
      end

      def validate_input(text, target_lang_code)
        raise ArgumentError, "Text cannot be empty" if text.nil? || text.strip.empty?
        raise ArgumentError, "Invalid target language code" unless target_lang_code.match?(/^[a-z]{2}(-[A-Z]{2})?$/)
      end

      # Method to be implemented in derived classes.
      # @param text [String] text to translate.
      # @param target_lang_code [String] target language code (e.g. "en").
      # @param target_lang_name [String] target language name (e.g. "English").
      # @return [String] testo tradotto.
      MAX_RETRIES = 3
      RETRY_DELAY = 2 # seconds

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

      def perform_translation(text, target_lang_code, target_lang_name)
        validate_input(text, target_lang_code)
        rate_limit
        translate_text(text, target_lang_code, target_lang_name)
      end

      def translate_text(text, target_lang_code, target_lang_name)
        raise NotImplementedError, "The provider #{self.class} must implement the translate_text method"
      end
    end
  end
end
