# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe BetterTranslate::SimilarityAnalyzer do
  let(:temp_files) { [] }
  let(:analyzer) { described_class.new(temp_files.map(&:path)) }

  before do
    # Create temporary YAML files for testing
    temp_files << create_temp_yaml("en.yml", {
      welcome: {
        greeting: "Hello, welcome to our site!",
        intro: "Hi, welcome to our website!"
      },
      about: {
        title: "About Us",
        description: "We are a company"
      }
    })

    temp_files << create_temp_yaml("it.yml", {
      welcome: {
        greeting: "Ciao, benvenuto nel nostro sito!",
        intro: "Ciao, benvenuto nel nostro website!"
      },
      about: {
        title: "Chi Siamo",
        description: "Siamo un'azienda"
      }
    })
  end

  after do
    # Cleanup temporary files
    temp_files.each do |file|
      file.close
      file.unlink
    end
    
    # Cleanup generated report files
    [
      described_class::REPORT_FILE,
      "translation_similarities_summary.txt"
    ].each do |file|
      File.unlink(file) if File.exist?(file)
    end
  end

  describe "#analyze" do
    it "generates similarity reports" do
      analyzer.analyze

      # Check JSON report
      expect(File.exist?(described_class::REPORT_FILE)).to be true
      json_report = JSON.parse(File.read(described_class::REPORT_FILE))
      
      expect(json_report["similarity_threshold"]).to eq(described_class::SIMILARITY_THRESHOLD)
      expect(json_report["findings"]).to be_a(Hash)
      expect(json_report["findings"]["en"]).to be_an(Array)
      expect(json_report["findings"]["it"]).to be_an(Array)

      # Check summary file
      expect(File.exist?("translation_similarities_summary.txt")).to be true
      summary = File.read("translation_similarities_summary.txt")
      
      expect(summary).to include("Translation Similarities Report")
      expect(summary).to include("Language: en")
      expect(summary).to include("Language: it")
    end

    it "identifies similar translations" do
      analyzer.analyze
      
      json_report = JSON.parse(File.read(described_class::REPORT_FILE))
      
      # Check English similarities
      en_similarities = json_report["findings"]["en"]
      expect(en_similarities).not_to be_empty
      
      similar_en = en_similarities.find do |sim|
        sim["key1"].include?("greeting") && sim["key2"].include?("intro")
      end
      
      expect(similar_en).not_to be_nil
      expect(similar_en["similarity"]).to be >= 0.85

      # Check Italian similarities
      it_similarities = json_report["findings"]["it"]
      expect(it_similarities).not_to be_empty
      
      similar_it = it_similarities.find do |sim|
        sim["key1"].include?("greeting") && sim["key2"].include?("intro")
      end
      
      expect(similar_it).not_to be_nil
      expect(similar_it["similarity"]).to be >= 0.85
    end
  end

  private

  def create_temp_yaml(filename, content)
    file = Tempfile.new(filename)
    file.write(content.to_yaml)
    file.rewind
    file
  end
end
