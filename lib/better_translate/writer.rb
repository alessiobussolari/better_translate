module BetterTranslate
  class Writer
    class << self
      # Writes the translation file for a target language.
      # If the translation method is :override, the file is rewritten from scratch;
      # if it's :incremental, the existing file is updated by inserting new translations in the correct positions.
      #
      # @param translated_data [Hash] The translated data structure (e.g. { "sample" => { "valid" => "translated", "new_key" => "new translation" } }).
      # @param target_lang_code [String] Target language code (e.g. "ru").
      def write_translations(translated_data, target_lang_code)
        output_folder = BetterTranslate.configuration.output_folder
        output_file = File.join(output_folder, "#{target_lang_code}.yml")

        # Reformats the structure to use the target code as the main key.
        output_content = if translated_data.is_a?(Hash) && translated_data.key?(BetterTranslate.configuration.source_language)
                           # Replaces the source language key with the target one.
                           { target_lang_code => translated_data[BetterTranslate.configuration.source_language] }
                         else
                           { target_lang_code => translated_data }
                         end

        if BetterTranslate.configuration.translation_method.to_sym == :incremental && File.exist?(output_file)
          existing_data = YAML.load_file(output_file)
          merged = deep_merge(existing_data, output_content)
          File.write(output_file, merged.to_yaml(line_width: -1))
          message = "File updated in incremental mode: #{output_file}"
          BetterTranslate::Utils.logger(message: message)
        else
          FileUtils.mkdir_p(output_folder) unless Dir.exist?(output_folder)
          File.write(output_file, output_content.to_yaml(line_width: -1))
          message = "File rewritten in override mode: #{output_file}"
          BetterTranslate::Utils.logger(message: message)
        end
      end

      private

      # Metodo di deep merge: unisce in modo ricorsivo i due hash.
      # Se una chiave esiste in entrambi gli hash e i valori sono hash, li unisce ricorsivamente.
      # Otherwise, if the key already exists in the existing hash, it keeps it and doesn't overwrite it.
      # Se la chiave non esiste, la aggiunge.
      #
      # @param existing [Hash] existing hash (current file)
      # @param new_data [Hash] new hash with translations to merge
      # @return [Hash] merged hash
      def deep_merge(existing, new_data)
        merged = existing.dup
        new_data.each do |key, value|
          if merged.key?(key)
            if merged[key].is_a?(Hash) && value.is_a?(Hash)
              merged[key] = deep_merge(merged[key], value)
            else
              # If the key already exists, don't overwrite the value (incremental mode)
              # or you might decide to update anyway, depending on the requirements.
              merged[key] = merged[key]
            end
          else
            merged[key] = value
          end
        end
        merged
      end

    end
  end
end