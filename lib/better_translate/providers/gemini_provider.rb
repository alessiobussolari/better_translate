# frozen_string_literal: true

module BetterTranslate
  module Providers
    # Google Gemini translation provider
    #
    # Uses gemini-2.0-flash-exp model for fast, high-quality translations.
    #
    # @example Basic usage
    #   config = Configuration.new
    #   config.google_gemini_key = ENV['GOOGLE_GEMINI_KEY']
    #   provider = GeminiProvider.new(config)
    #   result = provider.translate_text("Hello", "it", "Italian")
    #   #=> "Ciao"
    #
    class GeminiProvider < BaseHttpProvider
      # Google Gemini API endpoint
      API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"

      # Model to use for translations
      MODEL = "gemini-2.0-flash-exp"

      # Translate a single text
      #
      # @param text [String] Text to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [String] Translated text
      # @raise [ValidationError] if input is invalid
      # @raise [TranslationError] if translation fails
      #
      # @example
      #   provider.translate_text("Hello world", "it", "Italian")
      #   #=> "Ciao mondo"
      #
      def translate_text(text, target_lang_code, target_lang_name)
        Validator.validate_text!(text)
        Validator.validate_language_code!(target_lang_code)

        cache_key = build_cache_key(text, target_lang_code)

        with_cache(cache_key) do
          prompt = build_prompt(text, target_lang_name)
          response = make_generation_request(prompt)
          extract_translation(response)
        end
      rescue ApiError => e
        raise TranslationError.new(
          "Failed to translate text with Gemini: #{e.message}",
          context: { text: text, target_lang: target_lang_code, original_error: e }
        )
      end

      # Translate multiple texts in a batch
      #
      # @param texts [Array<String>] Texts to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Array<String>] Translated texts
      #
      # @example
      #   provider.translate_batch(["Hello", "World"], "it", "Italian")
      #   #=> ["Ciao", "Mondo"]
      #
      def translate_batch(texts, target_lang_code, target_lang_name)
        texts.map { |text| translate_text(text, target_lang_code, target_lang_name) }
      end

      private

      # Build prompt for Gemini API
      #
      # @param text [String] Text to translate
      # @param target_lang_name [String] Target language name
      # @return [String] Prompt
      # @api private
      #
      def build_prompt(text, target_lang_name)
        base_prompt = "Translate the following text to #{target_lang_name}. " \
                      "Return ONLY the translated text, without any explanations.\n\n" \
                      "Text: #{text}"

        if config.translation_context && !config.translation_context.empty?
          base_prompt = "Context: #{config.translation_context}\n\n#{base_prompt}"
        end

        base_prompt
      end

      # Make generation request to Gemini API
      #
      # @param prompt [String] Prompt text
      # @return [Faraday::Response] HTTP response
      # @api private
      #
      def make_generation_request(prompt)
        url = "#{API_URL}?key=#{config.google_gemini_key}"

        body = {
          contents: [
            {
              parts: [
                { text: prompt }
              ]
            }
          ]
        }

        headers = {
          "Content-Type" => "application/json"
        }

        make_request(:post, url, body: body, headers: headers)
      end

      # Extract translation from API response
      #
      # @param response [Faraday::Response] HTTP response
      # @return [String] Translated text
      # @raise [TranslationError] if parsing fails or no translation found
      # @api private
      #
      def extract_translation(response)
        parsed = JSON.parse(response.body)
        translation = parsed.dig("candidates", 0, "content", "parts", 0, "text")

        raise TranslationError, "No translation in response" if translation.nil? || translation.empty?

        translation.strip
      rescue JSON::ParserError => e
        raise TranslationError.new(
          "Failed to parse Gemini response",
          context: { error: e.message, body: response.body }
        )
      end
    end
  end
end
