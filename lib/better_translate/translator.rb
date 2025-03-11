module BetterTranslate
  class Translator
    class << self
      def work
        message = "Starting file translation..."
        BetterTranslate::Utils.logger(message: message)

        translations = read_yml_source

        # Removes the keys to exclude (global_exclusions) from the read structure
        global_filtered_translations = remove_exclusions(
          translations, BetterTranslate.configuration.global_exclusions
        )

        start_time = Time.now
        threads = BetterTranslate.configuration.target_languages.map do |target_lang|
          Thread.new do

          # Phase 2: Apply the target language specific filter
          lang_exclusions = BetterTranslate.configuration.exclusions_per_language[target_lang[:short_name]] || []
          filtered_translations = remove_exclusions(
            global_filtered_translations, lang_exclusions
          )

          message = "Starting translation from #{BetterTranslate.configuration.source_language} to #{target_lang[:short_name]}"
          BetterTranslate::Utils.logger(message: message)
          service = BetterTranslate::Service.new
          translated_data = translate_with_progress(filtered_translations, service, target_lang[:short_name], target_lang[:name])
          BetterTranslate::Writer.write_translations(translated_data, target_lang[:short_name])
          end_time = Time.now
          duration = end_time - start_time
          BetterTranslate::Utils.track_metric("translation_duration", duration)
          
          message = "Translation completed from #{BetterTranslate.configuration.source_language} to #{target_lang[:short_name]} in #{duration.round(2)} seconds"
          BetterTranslate::Utils.logger(message: message)
        end
        end
      end

      private

      # Reads the YAML file based on the provided path.
      #
      # @param file_path [String] path of the YAML file to read
      # @return [Hash] data structure containing the translations
      # @raise [StandardError] if the file does not exist
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
      #
      # @param data [Hash, Array, Object] The data structure to filter.
      # @param global_exclusions [Array<String>] List of paths (in dot notation) to exclude globally.
      # @param current_path [Array] The current path (used recursively, default: []).
      # @return [Hash, Array, Object] The filtered data structure.
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
      # @param data [Hash, Array, String] The data structure to translate.
      # @param provider [Object] The provider that responds to the translate method.
      # @param target_lang_code [String] Target language code (e.g. "en").
      # @param target_lang_name [String] Target language name (e.g. "English").
      # @param progress [Hash] A hash with :count and :total keys to monitor progress.
      # @return [Hash, Array, String] The translated structure.
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

      # Main method to translate the entire data structure, with progress monitoring.
      #
      # @param data [Hash, Array, String] the data structure to translate
      # @param provider [Object] the provider to use for translation (must implement translate)
      # @param target_lang_code [String] target language code
      # @param target_lang_name [String] target language name
      # @return the translated structure
      def translate_with_progress(data, service, target_lang_code, target_lang_name)
        total = count_strings(data)
        progress = ProgressBar.create(total: total, format: '%a %B %p%% %t')

        start_time = Time.now
        result = if total > 50 # Usa il batch processing per dataset grandi
          batch_translate_with_progress(data, service, target_lang_code, target_lang_name, progress)
        else
          deep_translate_with_progress(data, service, target_lang_code, target_lang_name, progress)
        end

        duration = Time.now - start_time
        BetterTranslate::Utils.track_metric("translation_method_duration", {
          method: total > 50 ? 'batch' : 'deep',
          duration: duration,
          total_strings: total
        })

        result
      end

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

      def extract_translatable_texts(data)
        texts = Set.new
        traverse_structure(data) do |value|
          texts.add(value) if value.is_a?(String) && !value.strip.empty?
        end
        texts.to_a
      end

      def replace_translations(data, translations)
        traverse_structure(data) do |value|
          if value.is_a?(String) && !value.strip.empty? && translations.key?(value)
            translations[value]
          else
            value
          end
        end
      end

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

      # Recursively counts the number of translatable strings in the data structure.
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