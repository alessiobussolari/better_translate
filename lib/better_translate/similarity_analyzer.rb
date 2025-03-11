# frozen_string_literal: true

require "yaml"
require "set"
require "json"
require "time"

module BetterTranslate
  class SimilarityAnalyzer
    SIMILARITY_THRESHOLD = 0.75 # Abbassiamo la soglia per trovare più similarità
    REPORT_FILE = "translation_similarities.json"

    def initialize(yaml_files)
      @yaml_files = yaml_files
      @similarities = {}
    end

    def analyze
      translations_by_language = load_translations
      find_similarities(translations_by_language)
      generate_report
    end

    private

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
