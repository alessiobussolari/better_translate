module BetterTranslate
  class Translator
    class << self
      # Esegue il processo di traduzione per tutte le lingue target configurate.
      #
      # Questo metodo è il punto di ingresso principale per il processo di traduzione.
      # Legge il file di input, applica le esclusioni globali e poi traduce il contenuto
      # in ciascuna delle lingue target configurate.
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

      # Legge il file YAML di origine delle traduzioni.
      #
      # Questo metodo legge il file YAML specificato nella configurazione e lo carica
      # in una struttura dati Ruby. Verifica l'esistenza del file prima di tentare
      # di leggerlo e solleva un'eccezione se il file non esiste.
      #
      # @return [Hash] Struttura dati contenente le traduzioni dal file YAML
      # @raise [StandardError] Se il file specificato non esiste
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
      # Traduce una struttura dati utilizzando un approccio ricorsivo profondo.
      #
      # Questo metodo attraversa ricorsivamente la struttura dati e traduce
      # ogni stringa individualmente. È più adatto per dataset di piccole dimensioni
      # o quando è necessaria una traduzione più precisa di ogni elemento.
      #
      # @param data [Hash, Array, String] La struttura dati da tradurre
      # @param service [BetterTranslate::Service] Il servizio da utilizzare per la traduzione
      # @param target_lang_code [String] Il codice della lingua di destinazione
      # @param target_lang_name [String] Il nome della lingua di destinazione
      # @param progress [ProgressBar] L'oggetto barra di progresso per monitorare l'avanzamento
      # @return [Hash, Array, String] La struttura dati tradotta
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

      # Traduce una struttura dati completa con monitoraggio del progresso.
      #
      # Questo metodo è responsabile della traduzione di una struttura dati completa,
      # che può essere un hash, un array o una stringa. Seleziona automaticamente
      # il metodo di traduzione più appropriato in base alla dimensione dei dati:
      # - Per dataset grandi (> 50 stringhe) utilizza il metodo batch
      # - Per dataset piccoli utilizza il metodo deep
      #
      # Mostra una barra di progresso durante la traduzione e registra metriche
      # sulla durata e il metodo utilizzato.
      #
      # @param data [Hash, Array, String] La struttura dati da tradurre
      # @param service [BetterTranslate::Service] Il servizio da utilizzare per la traduzione
      # @param target_lang_code [String] Il codice della lingua di destinazione (es. 'it', 'fr')
      # @param target_lang_name [String] Il nome della lingua di destinazione (es. 'Italian', 'French')
      # @return [Hash, Array, String] La struttura dati tradotta
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

      # Traduce una struttura dati utilizzando un approccio a batch.
      #
      # Questo metodo estrae tutte le stringhe traducibili dalla struttura dati,
      # le raggruppa in batch e le invia per la traduzione. Questo approccio è
      # più efficiente per dataset di grandi dimensioni poiché riduce il numero
      # di chiamate API necessarie.
      #
      # @param data [Hash, Array, String] La struttura dati da tradurre
      # @param service [BetterTranslate::Service] Il servizio da utilizzare per la traduzione
      # @param target_lang_code [String] Il codice della lingua di destinazione
      # @param target_lang_name [String] Il nome della lingua di destinazione
      # @param progress [ProgressBar] L'oggetto barra di progresso per monitorare l'avanzamento
      # @return [Hash, Array, String] La struttura dati tradotta
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

      # Estrae tutte le stringhe traducibili da una struttura dati complessa.
      #
      # Questo metodo utilizza traverse_structure per attraversare ricorsivamente
      # una struttura dati e raccoglie tutte le stringhe non vuote che devono
      # essere tradotte. Le stringhe vengono raccolte in un Set per eliminare
      # i duplicati e poi convertite in un array.
      #
      # @param data [Hash, Array, String] La struttura dati da cui estrarre le stringhe
      # @return [Array<String>] Un array di stringhe traducibili uniche
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
      # Conta il numero totale di stringhe traducibili in una struttura dati.
      #
      # Questo metodo è utilizzato per determinare la dimensione del dataset
      # e scegliere il metodo di traduzione più appropriato (batch o deep).
      #
      # @param data [Hash, Array, String] La struttura dati da analizzare
      # @return [Integer] Il numero totale di stringhe traducibili trovate
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