# frozen_string_literal: true

module BetterTranslate
  module Strategies
    # Deep translation strategy
    #
    # Translates each string individually with detailed progress tracking.
    # Used for smaller files (< 50 strings) to provide more granular progress.
    #
    # @example
    #   strategy = DeepStrategy.new(config, provider, tracker)
    #   translated = strategy.translate(strings, "it", "Italian")
    #
    class DeepStrategy < BaseStrategy
      # Translate strings individually
      #
      # @param strings [Hash] Flattened hash of strings to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Hash] Translated strings (flattened)
      #
      # @example
      #   translated = strategy.translate({ "greeting" => "Hello" }, "it", "Italian")
      #   #=> { "greeting" => "Ciao" }
      #
      def translate(strings, target_lang_code, target_lang_name)
        # @type var translated: Hash[String, String]
        translated = {}
        total = strings.size

        strings.each_with_index do |(key, value), index|
          progress_tracker.update(
            language: target_lang_name,
            current_key: key,
            progress: ((index + 1).to_f / total * 100.0).round(1)
          )

          translated[key] = provider.translate_text(value, target_lang_code, target_lang_name)
        end

        translated
      end
    end
  end
end
