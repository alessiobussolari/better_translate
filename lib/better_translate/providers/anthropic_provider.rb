# frozen_string_literal: true

module BetterTranslate
  module Providers
    # Anthropic Claude translation provider
    #
    # Uses claude-3-5-sonnet-20241022 model for high-quality translations.
    #
    # @example Basic usage
    #   config = Configuration.new
    #   config.anthropic_key = ENV['ANTHROPIC_API_KEY']
    #   provider = AnthropicProvider.new(config)
    #   result = provider.translate_text("Hello", "it", "Italian")
    #   #=> "Ciao"
    #
    class AnthropicProvider < BaseHttpProvider
      # Anthropic API endpoint
      API_URL = "https://api.anthropic.com/v1/messages"

      # Model to use for translations
      MODEL = "claude-3-5-sonnet-20241022"

      # API version
      API_VERSION = "2023-06-01"

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
          messages = build_messages(text, target_lang_name)
          response = make_messages_request(messages)
          extract_translation(response)
        end
      rescue ApiError => e
        raise TranslationError.new(
          "Failed to translate text with Anthropic: #{e.message}",
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

      # Build messages for Anthropic API
      #
      # @param text [String] Text to translate
      # @param target_lang_name [String] Target language name
      # @return [Hash] Messages hash
      # @api private
      #
      def build_messages(text, target_lang_name)
        system_message = build_system_message(target_lang_name)

        {
          system: system_message,
          messages: [
            { role: "user", content: text }
          ]
        }
      end

      # Build system message with optional context
      #
      # @param target_lang_name [String] Target language name
      # @return [String] System message
      # @api private
      #
      def build_system_message(target_lang_name)
        base_message = "You are a professional translator. Translate the following text to #{target_lang_name}. " \
                       "Return ONLY the translated text, without any explanations or additional text."

        if config.translation_context && !config.translation_context.empty?
          base_message += "\n\nContext: #{config.translation_context}"
        end

        base_message
      end

      # Make messages request to Anthropic API
      #
      # @param message_data [Hash] Message data with system and messages
      # @return [Faraday::Response] HTTP response
      # @api private
      #
      def make_messages_request(message_data)
        body = {
          model: MODEL,
          max_tokens: 1024,
          system: message_data[:system],
          messages: message_data[:messages]
        }

        headers = {
          "Content-Type" => "application/json",
          "x-api-key" => config.anthropic_key || "",
          "anthropic-version" => API_VERSION
        }

        make_request(:post, API_URL, body: body, headers: headers)
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
        translation = parsed.dig("content", 0, "text")

        raise TranslationError, "No translation in response" if translation.nil? || translation.empty?

        translation.strip
      rescue JSON::ParserError => e
        raise TranslationError.new(
          "Failed to parse Anthropic response",
          context: { error: e.message, body: response.body }
        )
      end
    end
  end
end
