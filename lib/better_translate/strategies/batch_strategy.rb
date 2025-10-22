# frozen_string_literal: true

module BetterTranslate
  module Strategies
    # Batch translation strategy
    #
    # Translates strings in batches for improved performance.
    # Used for larger files (>= 50 strings).
    #
    # @example
    #   strategy = BatchStrategy.new(config, provider, tracker)
    #   translated = strategy.translate(strings, "it", "Italian")
    #
    class BatchStrategy < BaseStrategy
      # Batch size for translation
      BATCH_SIZE = 10

      # Translate strings in batches
      #
      # @param strings [Hash] Flattened hash of strings to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Hash] Translated strings (flattened)
      #
      # @example
      #   strings = { "key1" => "value1", "key2" => "value2", ... }
      #   translated = strategy.translate(strings, "it", "Italian")
      #
      def translate(strings, target_lang_code, target_lang_name)
        # @type var translated: Hash[String, String]
        translated = {}
        keys = strings.keys
        values = strings.values
        total_batches = (values.size.to_f / BATCH_SIZE).ceil

        values.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
          progress_tracker.update(
            language: target_lang_name,
            current_key: "Batch #{batch_index + 1}/#{total_batches}",
            progress: ((batch_index + 1).to_f / total_batches * 100.0).round(1)
          )

          translated_batch = provider.translate_batch(batch, target_lang_code, target_lang_name)

          # Map back to keys
          batch_keys = keys[batch_index * BATCH_SIZE, batch.size]
          batch_keys&.each_with_index do |key, i|
            translated[key] = translated_batch[i]
          end
        end

        translated
      end
    end
  end
end
