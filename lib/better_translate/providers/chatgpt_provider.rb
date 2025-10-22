# frozen_string_literal: true

module BetterTranslate
  module Providers
    # OpenAI ChatGPT translation provider
    #
    # Uses GPT-5-nano model with temperature=1.0 for natural translations.
    #
    # @example Basic usage
    #   config = Configuration.new
    #   config.openai_key = ENV['OPENAI_API_KEY']
    #   provider = ChatGPTProvider.new(config)
    #   result = provider.translate_text("Hello", "it", "Italian")
    #   #=> "Ciao"
    #
    class ChatGPTProvider < BaseHttpProvider
      # OpenAI API endpoint
      API_URL = "https://api.openai.com/v1/chat/completions"

      # Model to use for translations
      MODEL = "gpt-5-nano"

      # Temperature setting for creativity
      TEMPERATURE = 1.0

      # Translate a single text
      #
      # @param text [String] Text to translate
      # @param target_lang_code [String] Target language code (e.g., "it")
      # @param target_lang_name [String] Target language name (e.g., "Italian")
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
          response = make_chat_completion_request(messages)
          extract_translation(response)
        end
      rescue ApiError => e
        raise TranslationError.new(
          "Failed to translate text with ChatGPT: #{e.message}",
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

      # Build messages array for ChatGPT API
      #
      # @param text [String] Text to translate
      # @param target_lang_name [String] Target language name
      # @return [Array<Hash>] Messages array
      # @api private
      #
      def build_messages(text, target_lang_name)
        system_message = build_system_message(target_lang_name)

        [
          { role: "system", content: system_message },
          { role: "user", content: text }
        ]
      end

      # Build system message with optional context
      #
      # @param target_lang_name [String] Target language name
      # @return [String] System message
      # @api private
      #
      def build_system_message(target_lang_name)
        base_message = "You are a professional translator. Translate the following text to #{target_lang_name}. " \
                       "Return ONLY the translated text, without any explanations or additional text. " \
                       "Words like VARIABLE_0, VARIABLE_1, etc. are placeholders and must be kept unchanged in the translation."

        if config.translation_context && !config.translation_context.empty?
          base_message += "\n\nContext: #{config.translation_context}"
        end

        base_message
      end

      # Make chat completion request to OpenAI API
      #
      # @param messages [Array<Hash>] Messages array
      # @return [Faraday::Response] HTTP response
      # @api private
      #
      def make_chat_completion_request(messages)
        body = {
          model: MODEL,
          messages: messages,
          temperature: TEMPERATURE
        }

        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{config.openai_key}"
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
        translation = parsed.dig("choices", 0, "message", "content")

        raise TranslationError, "No translation in response" if translation.nil? || translation.empty?

        translation.strip
      rescue JSON::ParserError => e
        raise TranslationError.new(
          "Failed to parse ChatGPT response",
          context: { error: e.message, body: response.body }
        )
      end
    end
  end
end
