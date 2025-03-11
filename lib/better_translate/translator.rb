module BetterTranslate
  class Translator
    class << self
      # Main method that orchestrates the translation process.
      # Reads the source file, applies exclusions, and translates the content
      # to all configured target languages sequentially.
      #
      # @return [void]
      def work
        message = "\n[BetterTranslate] Reading source file: #{BetterTranslate.configuration.input_file}\n"
        BetterTranslate::Utils.logger(message: message)

        translations = read_yml_source
        message = "[BetterTranslate] Source file loaded successfully."
        BetterTranslate::Utils.logger(message: message)

        # Removes the keys to exclude (global_exclusions) from the read structure
        message = "[BetterTranslate] Applying global exclusions..."
        BetterTranslate::Utils.logger(message: message)
        global_filtered_translations = remove_exclusions(
          translations, BetterTranslate.configuration.global_exclusions
        )
        message = "[BetterTranslate] Global exclusions applied."
        BetterTranslate::Utils.logger(message: message)

        start_time = Time.now
        results = []
        
        # Elabora ogni lingua target in sequenza invece di utilizzare thread
        BetterTranslate.configuration.target_languages.each do |target_lang|
          # Phase 2: Apply the target language specific filter
          lang_exclusions = BetterTranslate.configuration.exclusions_per_language[target_lang[:short_name]] || []
          filtered_translations = remove_exclusions(
            global_filtered_translations, lang_exclusions
          )

          message = "Starting translation from #{BetterTranslate.configuration.source_language} to #{target_lang[:short_name]}"
          BetterTranslate::Utils.logger(message: message)
          message = "\n[BetterTranslate] Starting translation to #{target_lang[:name]} (#{target_lang[:short_name]})..."
          BetterTranslate::Utils.logger(message: message)
          
          service = BetterTranslate::Service.new
          translated_data = translate_with_progress(filtered_translations, service, target_lang[:short_name], target_lang[:name])
          
          message = "[BetterTranslate] Writing translations for #{target_lang[:short_name]}..."
          BetterTranslate::Utils.logger(message: message)
          BetterTranslate::Writer.write_translations(translated_data, target_lang[:short_name])
          
          lang_end_time = Time.now
          duration = lang_end_time - start_time
          BetterTranslate::Utils.track_metric("translation_duration", duration)
          
          message = "Translation completed from #{BetterTranslate.configuration.source_language} to #{target_lang[:short_name]} in #{duration.round(2)} seconds"
          BetterTranslate::Utils.logger(message: message)
          message = "[BetterTranslate] Completed translation to #{target_lang[:name]} in #{duration.round(2)} seconds."
          BetterTranslate::Utils.logger(message: message)
          
          results << translated_data
        end
      end

      private

      # Reads the YAML file specified in the configuration.
      # The file path is taken from BetterTranslate.configuration.input_file.
      #
      # @return [Hash] The parsed YAML data structure containing the translations
      # @raise [StandardError] If the input file does not exist or cannot be parsed
      def read_yml_source
        file_path = BetterTranslate.configuration.input_file
        unless File.exist?(file_path)
          raise "File not found: #{file_path}"
        end

        YAML.load_file(file_path)
      end

      # Removes the global keys to exclude from the data structure,
      # calculating paths starting from the source language content.
      #
      # For example, if the YAML file is:
      #   { "en" => { "sample" => { "valid" => "valid", "excluded" => "Excluded" } } }
      # and global_exclusions = ["sample.excluded"],
      # the result will be:
      #   { "en" => { "sample" => { "valid" => "valid" } } }
      # Removes specified keys from the translation data structure.
      # Recursively traverses the data structure and excludes any keys that match the exclusion list.
      # Keys can be excluded at any nesting level using dot notation paths.
      #
      # @param data [Hash, Array, Object] The data structure to filter
      # @param exclusion_list [Array<String>] List of dot-separated key paths to exclude
      # @param current_path [Array] The current path in the traversal (used recursively, default: [])
      # @return [Hash, Array, Object] The filtered data structure with excluded keys removed
      def remove_exclusions(data, exclusion_list, current_path = [])
        if data.is_a?(Hash)
          data.each_with_object({}) do |(key, value), result|
            # If we are at the top-level and the key matches the source language,
            # reset the path (to exclude "en" from the final path)
            new_path = if current_path.empty? && key == BetterTranslate.configuration.source_language
                         []
                       else
                         current_path + [key]
                       end

            path_string = new_path.join(".")
            unless exclusion_list.include?(path_string)
              result[key] = remove_exclusions(value, exclusion_list, new_path)
            end
          end
        elsif data.is_a?(Array)
          data.map.with_index do |item, index|
            remove_exclusions(item, exclusion_list, current_path + [index])
          end
        else
          data
        end
      end

      # Recursive method that traverses the structure, translating each string and updating progress.
      #
      # Recursively translates a data structure by traversing it deeply.
      # This method is used for smaller datasets (less than 50 strings) and translates each string individually.
      # It maintains the original structure of the data while replacing string values with their translations.
      #
      # @param data [Hash, Array, String] The data structure to translate
      # @param service [BetterTranslate::Service] The service instance to use for translation
      # @param target_lang_code [String] The target language code (e.g., 'fr', 'es')
      # @param target_lang_name [String] The target language name (e.g., 'French', 'Spanish')
      # @param progress [ProgressBar] A progress bar instance to track translation progress
      # @return [Hash, Array, String] The translated data structure with the same structure as the input
      def deep_translate_with_progress(data, service, target_lang_code, target_lang_name, progress)
        if data.is_a?(Hash)
          data.each_with_object({}) do |(key, value), result|
            result[key] = deep_translate_with_progress(value, service, target_lang_code, target_lang_name, progress)
          end
        elsif data.is_a?(Array)
          data.map do |item|
            deep_translate_with_progress(item, service, target_lang_code, target_lang_name, progress)
          end
        elsif data.is_a?(String)
          progress.increment
          service.translate(data, target_lang_code, target_lang_name)
        else
          data
        end
      end

      # Translates the entire data structure with progress monitoring.
      # Automatically selects between batch and deep translation methods based on the number of strings.
      # For datasets with more than 50 strings, batch processing is used for better performance.
      #
      # @param data [Hash, Array, String] The data structure to translate
      # @param service [BetterTranslate::Service] The service instance to use for translation
      # @param target_lang_code [String] The target language code (e.g., 'fr', 'es')
      # @param target_lang_name [String] The target language name (e.g., 'French', 'Spanish')
      # @return [Hash, Array, String] The translated data structure with the same structure as the input
      def translate_with_progress(data, service, target_lang_code, target_lang_name)
        total = count_strings(data)
        message = "[BetterTranslate] Found #{total} strings to translate to #{target_lang_name}"
        BetterTranslate::Utils.logger(message: message)
        
        # Creiamo la barra di progresso ma aggiungiamo anche output visibile
        progress = ProgressBar.create(total: total, format: '%a %B %p%% %t')

        start_time = Time.now
        message = "[BetterTranslate] Using #{total > 50 ? 'batch' : 'deep'} translation method"
        BetterTranslate::Utils.logger(message: message)
        
        result = if total > 50 # Usa il batch processing per dataset grandi
          batch_translate_with_progress(data, service, target_lang_code, target_lang_name, progress)
        else
          deep_translate_with_progress(data, service, target_lang_code, target_lang_name, progress)
        end

        duration = Time.now - start_time
        message = "[BetterTranslate] Translation processing completed in #{duration.round(2)} seconds"
        BetterTranslate::Utils.logger(message: message)
        
        BetterTranslate::Utils.track_metric("translation_method_duration", {
          method: total > 50 ? 'batch' : 'deep',
          duration: duration,
          total_strings: total
        })

        result
      end

      # Translates data in batches for improved performance with larger datasets.
      # This method first extracts all translatable strings, processes them in batches of 10,
      # and then reinserts the translations back into the original structure.
      #
      # @param data [Hash, Array, String] The data structure to translate
      # @param service [BetterTranslate::Service] The service instance to use for translation
      # @param target_lang_code [String] The target language code (e.g., 'fr', 'es')
      # @param target_lang_name [String] The target language name (e.g., 'French', 'Spanish')
      # @param progress [ProgressBar] A progress bar instance to track translation progress
      # @return [Hash, Array, String] The translated data structure with the same structure as the input
      def batch_translate_with_progress(data, service, target_lang_code, target_lang_name, progress)
        texts = extract_translatable_texts(data)
        translations = {}

        texts.each_slice(10).each_with_index do |batch, index|
          batch_start = Time.now
          
          batch_translations = batch.map do |text|
            translated = service.translate(text, target_lang_code, target_lang_name)
            progress.increment
            [text, translated]
          end.to_h

          translations.merge!(batch_translations)
          
          batch_duration = Time.now - batch_start
          BetterTranslate::Utils.track_metric("batch_translation_duration", {
            batch_number: index + 1,
            size: batch.size,
            duration: batch_duration
          })
        end

        replace_translations(data, translations)
      end

      # Extracts all unique translatable strings from a data structure.
      # This is used by the batch translation method to collect all strings for efficient processing.
      # Only non-empty strings are included in the result.
      #
      # @param data [Hash, Array, String] The data structure to extract strings from
      # @return [Array<String>] An array of unique strings found in the data structure
      def extract_translatable_texts(data)
        texts = Set.new
        traverse_structure(data) do |value|
          texts.add(value) if value.is_a?(String) && !value.strip.empty?
        end
        texts.to_a
      end

      # Replaces strings in the original data structure with their translations.
      # Used by the batch translation method to reinsert translated strings into the original structure.
      # Only non-empty strings that have translations in the provided hash are replaced.
      #
      # @param data [Hash, Array, String] The original data structure
      # @param translations [Hash] A hash mapping original strings to their translations
      # @return [Hash, Array, String] The data structure with strings replaced by translations
      def replace_translations(data, translations)
        traverse_structure(data) do |value|
          if value.is_a?(String) && !value.strip.empty? && translations.key?(value)
            translations[value]
          else
            value
          end
        end
      end

      # Traverses a nested data structure and applies a block to each element.
      # This is a utility method used by extract_translatable_texts and replace_translations.
      # Handles Hash, Array, and scalar values recursively.
      #
      # @param data [Hash, Array, Object] The data structure to traverse
      # @yield [Object] Yields each value in the data structure to the block
      # @return [Hash, Array, Object] The transformed data structure after applying the block
      def traverse_structure(data, &block)
        case data
        when Hash
          data.transform_values { |v| traverse_structure(v, &block) }
        when Array
          data.map { |v| traverse_structure(v, &block) }
        else
          yield data
        end
      end

      # Counts the number of translatable strings in a data structure.
      # Used to determine the total number of strings for progress tracking and method selection.
      # Recursively traverses Hash and Array structures, counting each String as 1.
      #
      # @param data [Hash, Array, String, Object] The data structure to count strings in
      # @return [Integer] The total number of strings found in the data structure
      def count_strings(data)
        if data.is_a?(Hash)
          data.values.sum { |v| count_strings(v) }
        elsif data.is_a?(Array)
          data.sum { |item| count_strings(item) }
        elsif data.is_a?(String)
          1
        else
          0
        end
      end
    end
  end
end