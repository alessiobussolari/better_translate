require "yaml"
require "net/http"
require "json"

module BetterTranslate
  class Translator
    def initialize(config)
      @config = config
    end

    # Legge il file YAML da tradurre e genera le traduzioni secondo la modalità specificata
    #
    # mode: :override => rigenera tutte le traduzioni
    #       :incremental => aggiorna solo le chiavi mancanti o sovrascritte partendo dal file incremental_file
    def translate_file(file_path, mode: :override, incremental_file: nil)
      original = YAML.load_file(file_path)
      translations = {}

      case mode
      when :override
        translations = generate_translations(original)
      when :incremental
        incremental_values = incremental_file && File.exist?(incremental_file) ? YAML.load_file(incremental_file) : {}
        translations = merge_translations(original, incremental_values)
      else
        raise "Modalità di traduzione non supportata: #{mode}"
      end

      # Scrittura su file. Potreste decidere di generare file separati per ogni lingua.
      @config.target_languages.each do |lang|
        output = apply_translations(original, translations, lang)
        File.write("translated_#{lang}.yml", output.to_yaml)
        puts "File translated_#{lang}.yml generato."
      end
    end

    private

    # Metodo che genera le traduzioni per ogni chiave
    def generate_translations(yml_data)
      # Questo metodo percorre il file YML e traduce ogni stringa
      # Utilizza il provider definito nella configurazione
      translations = {}

      yml_data.each do |key, value|
        if value.is_a?(String)
          translations[key] = translate_text(value)
        elsif value.is_a?(Hash)
          translations[key] = generate_translations(value)
        end
      end

      translations
    end

    # Metodo che unisce le traduzioni esistenti (incremental) con il file originale
    def merge_translations(original, incremental)
      # Se incremental contiene traduzioni, le utilizza. Altrimenti, genera la traduzione.
      merged = {}

      original.each do |key, value|
        if value.is_a?(String)
          merged[key] = incremental[key] || translate_text(value)
        elsif value.is_a?(Hash)
          merged[key] = merge_translations(value, incremental[key] || {})
        end
      end

      merged
    end

    # Applica le traduzioni alla struttura YML originale per una determinata lingua.
    # In questo esempio, simuliamo la sostituzione (in una situazione reale la struttura potrebbe essere più complessa).
    def apply_translations(original, translations, lang)
      # In questo esempio, semplicemente sostituisce i valori con la traduzione.
      # Potreste voler strutturare il file in modo diverso, ad esempio creando un file per lingua.
      result = {}

      original.each do |key, value|
        if value.is_a?(String)
          result[key] = "[#{lang}] #{translations[key]}"
        elsif value.is_a?(Hash)
          result[key] = apply_translations(value, translations[key], lang)
        end
      end

      result
    end

    # Metodo per tradurre il testo utilizzando il provider selezionato.
    def translate_text(text)
      case @config.provider
      when :google
        translate_with_google(text)
      when :openai
        translate_with_openai(text)
      else
        raise "Provider non supportato: #{@config.provider}"
      end
    end

    # Esempio di implementazione per il provider Google
    def translate_with_google(text)
      # Simulazione di chiamata API per Google Translate.
      # In una implementazione reale, qui si effettuerebbe una chiamata HTTP.
      "Google_Translated(#{text})"
    end

    # Esempio di implementazione per il provider OpenAI
    def translate_with_openai(text)
      # Simulazione di chiamata API per OpenAI.
      # In una implementazione reale, qui si effettuerebbe una chiamata HTTP.
      "OpenAI_Translated(#{text})"
    end
  end
end
