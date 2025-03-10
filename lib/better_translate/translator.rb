module BetterTranslate
  class Translator
    class << self
      def work
        puts "Avvio della traduzione dei file..."

        translations = read_yml_source

        # Rimuove le chiavi da escludere (global_exclusions) dalla struttura letta
        filtered_translations = remove_exclusions(
          translations, BetterTranslate.configuration.global_exclusions
        )

        BetterTranslate.configuration.target_languages.each do |target_lang|
          puts "Inizio traduzione da #{BetterTranslate.configuration.source_language} a #{target_lang[:short_name]}"
          service = BetterTranslate::Service.new
          translated_data = translate_with_progress(filtered_translations, service, target_lang[:short_name], target_lang[:name])
          BetterTranslate::Writer.write_translations(translated_data, target_lang[:short_name])
          puts "Traduzione completata da #{BetterTranslate.configuration.source_language} a #{target_lang[:short_name]}"
        end

        "Traduzione iniziata! #{filtered_translations.inspect}"
      end

      private

      # Legge il file YAML in base al percorso fornito.
      #
      # @param file_path [String] percorso del file YAML da leggere
      # @return [Hash] struttura dati contenente le traduzioni
      # @raise [StandardError] se il file non esiste
      def read_yml_source
        file_path = BetterTranslate.configuration.input_file
        unless File.exist?(file_path)
          raise "File non trovato: #{file_path}"
        end

        YAML.load_file(file_path)
      end

      # Rimuove le chiavi specificate in exclusion_list dalla struttura dati,
      # calcolando i percorsi a partire dal contenuto della lingua di partenza.
      #
      # Ad esempio, se il file YAML è:
      # { "en" => { "sample" => { "valid" => "valid", "excluded" => "Excluded" } } }
      # e exclusion_list = ["sample.excluded"],
      # il risultato sarà:
      # { "en" => { "sample" => { "valid" => "valid" } } }
      #
      # @param data [Hash, Array, Object] La struttura dati da filtrare.
      # @param exclusion_list [Array<String>] Lista dei percorsi (in dot notation) da escludere.
      # @param current_path [Array] Il percorso corrente (usato in maniera ricorsiva).
      # @return [Hash, Array, Object] La struttura dati filtrata.
      def remove_exclusions(data, exclusion_list, current_path = [])
        if data.is_a?(Hash)
          data.each_with_object({}) do |(key, value), result|
            # Se siamo al livello top-level e la chiave corrisponde alla lingua di partenza,
            # resettare il percorso (così da escludere "en" dal percorso finale)
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

      # Metodo ricorsivo che percorre la struttura, traducendo ogni stringa e aggiornando il progresso.
      #
      # @param data [Hash, Array, String] La struttura dati da tradurre.
      # @param provider [Object] Il provider che risponde al metodo translate.
      # @param target_lang_code [String] Codice della lingua target (es. "en").
      # @param target_lang_name [String] Nome della lingua target (es. "English").
      # @param progress [Hash] Un hash con le chiavi :count e :total per monitorare il progresso.
      # @return [Hash, Array, String] La struttura tradotta.
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

      # Metodo principale per tradurre l'intera struttura dati, con monitoraggio del progresso.
      #
      # @param data [Hash, Array, String] la struttura dati da tradurre
      # @param provider [Object] il provider da usare per tradurre (deve implementare translate)
      # @param target_lang_code [String] codice della lingua target
      # @param target_lang_name [String] nome della lingua target
      # @return la struttura tradotta
      def translate_with_progress(data, service, target_lang_code, target_lang_name)
        total = count_strings(data)
        progress = ProgressBar.create(total: total, format: '%a %B %p%% %t')
        deep_translate_with_progress(data, service, target_lang_code, target_lang_name, progress)
      end

      # Conta ricorsivamente il numero di stringhe traducibili nella struttura dati.
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