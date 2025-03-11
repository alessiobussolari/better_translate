module BetterTranslate
  # Helper class that provides utility methods for translating text and arrays of text
  # to multiple target languages using different translation providers.
  # This class simplifies the process of translating content by abstracting away
  # the provider-specific implementation details.
  #
  # @example Translating a single text to multiple languages
  #   BetterTranslate::Helper.translate_text_to_languages(
  #     "Hello world!",
  #     [{ short_name: "it", name: "Italian" }, { short_name: "fr", name: "French" }],
  #     "en",
  #     :chatgpt
  #   )
  class Helper
    class << self
      # Translates a given text into multiple target languages.
      #
      # @param text [String] The text to be translated.
      # @param target_languages [Array<Hash>] Array of target language hashes,
      #   e.g. [{ short_name: "it", name: "Italian" }, { short_name: "fr", name: "French" }]
      # @param source_language [String] The source language code (e.g., "en").
      # @param provider_name [Symbol] The provider to use (e.g., :chatgpt or :gemini).
      # @return [Hash] A hash where each key is a target language code and the value is the translated text.
      #
      # Example:
      #   translated = BetterTranslate::Helpers.translate_text_to_languages(
      #     "Hello world!",
      #     [{ short_name: "it", name: "Italian" }, { short_name: "fr", name: "French" }],
      #     "en",
      #     :chatgpt
      #   )
      #   # => { "it" => "Ciao mondo!", "fr" => "Bonjour le monde!" }
      def translate_text_to_languages(text, target_languages, source_language, provider_name)
        provider_instance = case provider_name
                            when :chatgpt
                              Providers::ChatgptProvider.new(BetterTranslate.configuration.openai_key)
                            when :gemini
                              Providers::GeminiProvider.new(BetterTranslate.configuration.google_gemini_key)
                            else
                              raise "Provider not supported: #{provider_name}"
                            end

        result = {}
        target_languages.each do |lang|
          # Optionally, you could also pass the source_language if needed by your provider.
          translated_text = provider_instance.translate(text, lang[:short_name], lang[:name])
          result[lang[:short_name]] = translated_text
        end
        result
      end

      # Translates an array of texts into multiple target languages using the translate_text_to_languages helper.
      #
      # @param texts [Array<String>] An array of texts to translate.
      # @param target_languages [Array<Hash>] Array of target language hashes,
      #   e.g. [{ short_name: "it", name: "Italian" }, { short_name: "fr", name: "French" }].
      # @param source_language [String] The source language code (e.g., "en").
      # @param provider_name [Symbol] The provider to use (e.g., :chatgpt or :gemini).
      # @return [Hash] A hash where each key is a target language code and the value is an array of translated texts.
      #
      # Example:
      #   texts = ["Hello world!", "How are you?"]
      #   result = BetterTranslate::TranslationHelper.translate_texts_to_languages(
      #     texts,
      #     [{ short_name: "it", name: "Italian" }, { short_name: "fr", name: "French" }],
      #     "en",
      #     :chatgpt
      #   )
      #   # => { "it" => ["Ciao mondo!", "Come stai?"], "fr" => ["Bonjour le monde!", "Comment ça va?"] }
      def translate_texts_to_languages(texts, target_languages, source_language, provider_name)
        result = {}
        target_languages.each do |lang|
          # For each target language, translate each text and collect translations into an array.
          result[lang[:short_name]] = texts.map do |text|
            translation_hash = translate_text_to_languages(text, [lang], source_language, provider_name)
            translation_hash[lang[:short_name]]
          end
        end
        result
      end
    end
  end
end