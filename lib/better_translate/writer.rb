module BetterTranslate
  class Writer
    class << self
      # Scrive il file di traduzione per una lingua target.
      # Se il metodo di traduzione è :override, il file viene riscritto da zero;
      # se è :incremental, il file esistente viene aggiornato inserendo le nuove traduzioni nelle posizioni corrette.
      #
      # @param translated_data [Hash] La struttura dati tradotta (ad es. { "sample" => { "valid" => "tradotto", "new_key" => "nuova traduzione" } }).
      # @param target_lang_code [String] Codice della lingua target (es. "ru").
      def write_translations(translated_data, target_lang_code)
        output_folder = BetterTranslate.configuration.output_folder
        output_file = File.join(output_folder, "#{target_lang_code}.yml")

        # Riformatta la struttura per utilizzare il codice target come chiave principale.
        output_content = if translated_data.is_a?(Hash) && translated_data.key?(BetterTranslate.configuration.source_language)
                           # Sostituisce la chiave della lingua di partenza con quella target.
                           { target_lang_code => translated_data[BetterTranslate.configuration.source_language] }
                         else
                           { target_lang_code => translated_data }
                         end

        if BetterTranslate.configuration.translation_method.to_sym == :incremental && File.exist?(output_file)
          existing_data = YAML.load_file(output_file)
          merged = deep_merge(existing_data, output_content)
          File.write(output_file, merged.to_yaml(line_width: -1))
          puts "File aggiornato in modalità incremental: #{output_file}"
        else
          FileUtils.mkdir_p(output_folder) unless Dir.exist?(output_folder)
          File.write(output_file, output_content.to_yaml(line_width: -1))
          puts "File riscritto in modalità override: #{output_file}"
        end
      end

      private

      # Metodo di deep merge: unisce in modo ricorsivo i due hash.
      # Se una chiave esiste in entrambi gli hash e i valori sono hash, li unisce ricorsivamente.
      # Altrimenti, se la chiave esiste già nell'hash esistente, la mantiene e non la sovrascrive.
      # Se la chiave non esiste, la aggiunge.
      #
      # @param existing [Hash] hash esistente (file corrente)
      # @param new_data [Hash] nuovo hash con le traduzioni da unire
      # @return [Hash] hash unito
      def deep_merge(existing, new_data)
        merged = existing.dup
        new_data.each do |key, value|
          if merged.key?(key)
            if merged[key].is_a?(Hash) && value.is_a?(Hash)
              merged[key] = deep_merge(merged[key], value)
            else
              # Se la chiave esiste già, non sovrascrivo il valore (modalità incrementale)
              # oppure potresti decidere di aggiornare comunque, a seconda delle esigenze.
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