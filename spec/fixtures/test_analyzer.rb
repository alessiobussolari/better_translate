#!/usr/bin/env ruby
# frozen_string_literal: true

# Aggiungi la directory lib al load path
$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

# Carica i file necessari
require "better_translate/version"
require "better_translate/similarity_analyzer"

# Directory corrente dello script
script_dir = File.dirname(__FILE__)

# Percorsi dei file YAML di test
yaml_files = [
  File.join(script_dir, "en.yml"),
  File.join(script_dir, "it.yml"),
  File.join(script_dir, "fr.yml"),
  File.join(script_dir, "es.yml")
]

# Verifica che i file esistano
yaml_files.each do |file|
  unless File.exist?(file)
    puts "Errore: File non trovato: #{file}"
    exit 1
  end
end

# Crea e esegui l'analizzatore
analyzer = BetterTranslate::SimilarityAnalyzer.new(yaml_files)
analyzer.analyze

# Mostra i file generati
puts "\nFile generati:"
Dir.glob("*.{json,txt}").each do |file|
  puts "  - #{file} (#{File.size(file)} bytes)"
end
