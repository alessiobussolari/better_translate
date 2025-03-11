# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe BetterTranslate::SimilarityAnalyzer do
  include TranslationHelper
  
  let(:temp_files) { create_temp_yaml_files }
  let(:yaml_files) { temp_files.map(&:path) }
  let(:analyzer) { described_class.new(yaml_files) }

  after do
    # Pulizia dei file temporanei
    temp_files.each do |file|
      file.close
      file.unlink
    end

    # Pulizia dei file di report
    File.delete(described_class::REPORT_FILE) if File.exist?(described_class::REPORT_FILE)
    File.delete("translation_similarities_summary.txt") if File.exist?("translation_similarities_summary.txt")
  end

  describe "#analyze" do
    it "generates similarity reports" do
      analyzer.analyze

      # Verifica del report JSON
      expect(File.exist?(described_class::REPORT_FILE)).to be true
      json_report = JSON.parse(File.read(described_class::REPORT_FILE))
      
      expect(json_report["similarity_threshold"]).to eq(described_class::SIMILARITY_THRESHOLD)
      expect(json_report["findings"]).to be_a(Hash)
      
      # Verifichiamo che ci sia almeno una lingua con similarità
      expect(json_report["findings"].keys.size).to be > 0
      
      # Prendiamo la prima lingua disponibile nel report
      first_lang = json_report["findings"].keys.first
      expect(json_report["findings"][first_lang]).to be_an(Array)

      # Verifica del file di riepilogo
      expect(File.exist?("translation_similarities_summary.txt")).to be true
      summary = File.read("translation_similarities_summary.txt")
      
      expect(summary).to include("Translation Similarities Report")
      expect(summary).to include("Language: ")
    end

    it "identifies similar translations" do
      analyzer.analyze
      
      json_report = JSON.parse(File.read(described_class::REPORT_FILE))
      
      # Verifichiamo che ci sia almeno una lingua con similarità
      expect(json_report["findings"].keys.size).to be > 0
      
      # Prendiamo la prima lingua disponibile nel report che ha similarità
      lang_with_similarities = json_report["findings"].find { |_, similarities| !similarities.empty? }
      expect(lang_with_similarities).not_to be_nil
      
      lang_code = lang_with_similarities[0]
      similarities = lang_with_similarities[1]
      
      expect(similarities).to be_an(Array)
      expect(similarities).not_to be_empty
      
      # Verifichiamo che ci sia almeno una similarità con un valore di similarità valido
      similar_item = similarities.first
      expect(similar_item).to be_a(Hash)
      expect(similar_item).to have_key("similarity")
      expect(similar_item["similarity"]).to be >= described_class::SIMILARITY_THRESHOLD
    end
  end
end
