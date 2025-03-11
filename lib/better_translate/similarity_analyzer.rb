# frozen_string_literal: true

require "yaml"
require "set"
require "json"
require "time"

module BetterTranslate
  # Analyzes translation YAML files to find similar content across keys.
  # Uses the Levenshtein distance algorithm to identify strings that are similar
  # but not identical, which could indicate redundant translations.
  #
  # @example
  #   analyzer = BetterTranslate::SimilarityAnalyzer.new(["config/locales/en.yml", "config/locales/fr.yml"])
  #   analyzer.analyze
  class SimilarityAnalyzer
    # Default threshold for considering two strings similar (75%)
    # @return [Float] The similarity threshold as a decimal between 0 and 1
    SIMILARITY_THRESHOLD = 0.75 # Abbassiamo la soglia per trovare più similarità
    
    # Default filename for the detailed JSON report
    # @return [String] The filename for the JSON report
    REPORT_FILE = "translation_similarities.json"

    # Initializes a new SimilarityAnalyzer with the specified YAML files.
    #
    # @param yaml_files [Array<String>] An array of paths to YAML translation files
    # @return [SimilarityAnalyzer] A new instance of the analyzer
    def initialize(yaml_files)
      @yaml_files = yaml_files
      @similarities = {}
    end

    # Performs the complete analysis process:
    # 1. Loads all translation files
    # 2. Finds similarities between translations
    # 3. Generates JSON and text reports
    #
    # @return [void]
    def analyze
      translations_by_language = load_translations
      find_similarities(translations_by_language)
      generate_report
    end

    private

    # Loads all YAML translation files specified during initialization.
    # Parses each file and organizes translations by language code.
    #
    # @return [Hash] A hash mapping language codes to their translation data structures
    def load_translations
      translations = {}
      puts "Loading YAML files..."
      
      @yaml_files.each do |file|
        lang_code = File.basename(file, ".yml")
        translations[lang_code] = YAML.load_file(file)
        puts "  - Loaded #{lang_code}.yml"
      end

      translations
    end

    # Finds similar translations within each language file.
    # For each language, flattens the translation structure and compares each pair of strings
    # to identify similarities based on the Levenshtein distance algorithm.
    #
    # @param translations_by_language [Hash] A hash mapping language codes to their translation data
    # @return [void]
    def find_similarities(translations_by_language)
      translations_by_language.each do |lang, translations|
        puts "\nAnalyzing #{lang} translations..."
        flattened = flatten_translations(translations)
        keys = flattened.keys
        similar_found = 0
        
        keys.each_with_index do |key1, i|
          value1 = flattened[key1]
          
          # Confronta solo con le chiavi successive per evitare duplicati
          keys[(i + 1)..-1].each do |key2|
            value2 = flattened[key2]
            
            similarity = calculate_similarity(value1.to_s, value2.to_s)
            if similarity >= SIMILARITY_THRESHOLD
              record_similarity(lang, key1, key2, value1, value2, similarity)
              similar_found += 1
            end
          end
        end
        
        puts "  Found #{similar_found} similar translations"
      end
    end

    # Flattens a nested translation hash into a single-level hash with dot-notation keys.
    # For example, {"en" => {"hello" => "world"}} becomes {"en.hello" => "world"}.
    #
    # @param hash [Hash] The nested hash to flatten
    # @param prefix [String] The current key prefix (used recursively)
    # @param result [Hash] The accumulator for flattened key-value pairs
    # @return [Hash] A flattened hash with dot-notation keys
    def flatten_translations(hash, prefix = "", result = {})
      hash.each do |key, value|
        current_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
        
        if value.is_a?(Hash)
          flatten_translations(value, current_key, result)
        else
          result[current_key] = value
        end
      end
      
      result
    end

    # Calculates the similarity between two strings using normalized Levenshtein distance.
    # Returns a value between 0 (completely different) and 1 (identical).
    # The normalization accounts for the length of the strings.
    #
    # @param str1 [String] The first string to compare
    # @param str2 [String] The second string to compare
    # @return [Float] A similarity score between 0 and 1
    def calculate_similarity(str1, str2)
      # Implementazione della distanza di Levenshtein normalizzata
      matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }
      
      (0..str1.length).each { |i| matrix[i][0] = i }
      (0..str2.length).each { |j| matrix[0][j] = j }
      
      (1..str1.length).each do |i|
        (1..str2.length).each do |j|
          cost = str1[i-1] == str2[j-1] ? 0 : 1
          matrix[i][j] = [
            matrix[i-1][j] + 1,
            matrix[i][j-1] + 1,
            matrix[i-1][j-1] + cost
          ].min
        end
      end
      
      max_length = [str1.length, str2.length].max
      1 - (matrix[str1.length][str2.length].to_f / max_length)
    end

    # Records a similarity finding in the internal data structure.
    # Organizes findings by language and stores all relevant information about the similar strings.
    #
    # @param lang [String] The language code
    # @param key1 [String] The first translation key
    # @param key2 [String] The second translation key
    # @param value1 [String] The first translation value
    # @param value2 [String] The second translation value
    # @param similarity [Float] The calculated similarity score
    # @return [void]
    def record_similarity(lang, key1, key2, value1, value2, similarity)
      @similarities[lang] ||= []
      @similarities[lang] << {
        key1: key1,
        key2: key2,
        value1: value1,
        value2: value2,
        similarity: similarity.round(2)
      }
    end

    # Generates both JSON and human-readable reports of the similarity findings.
    # The JSON report contains detailed information about each similarity found.
    # The text summary provides a more readable format for quick review.
    #
    # @return [void]
    def generate_report
      puts "\nGenerating reports..."
      report = {
        generated_at: Time.now.iso8601,
        similarity_threshold: SIMILARITY_THRESHOLD,
        findings: @similarities
      }

      File.write(REPORT_FILE, JSON.pretty_generate(report))
      puts "  - Generated #{REPORT_FILE}"
      
      summary = generate_summary(report)
      File.write("translation_similarities_summary.txt", summary)
      puts "  - Generated translation_similarities_summary.txt"
    end

    # Generates a human-readable summary of the similarity findings.
    # Creates a formatted text report organized by language, showing each pair of similar strings
    # with their keys, values, and similarity percentage.
    #
    # @param report [Hash] The complete similarity report data
    # @return [String] A formatted text summary
    def generate_summary(report)
      summary = ["Translation Similarities Report", "=" * 30, ""]
      
      report[:findings].each do |lang, similarities|
        summary << "Language: #{lang}"
        summary << "-" * 20
        
        similarities.each do |sim|
          summary << "Similar translations found:"
          summary << "  Key 1: #{sim[:key1]}"
          summary << "  Value 1: #{sim[:value1]}"
          summary << "  Key 2: #{sim[:key2]}"
          summary << "  Value 2: #{sim[:value2]}"
          summary << "  Similarity: #{(sim[:similarity] * 100).round(1)}%"
          summary << ""
        end
        
        summary << ""
      end
      
      summary.join("\n")
    end
  end
end
