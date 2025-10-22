# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe BetterTranslate::Translator do
  let(:input_file) { File.join(Dir.tmpdir, "test_en.yml") }
  let(:output_folder) { Dir.tmpdir }

  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :chatgpt
    config.openai_key = "test_key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = input_file
    config.output_folder = output_folder
    config.verbose = false
    config.dry_run = true # Don't actually write files in tests
    config
  end

  before do
    # Create test input file
    File.write(input_file, { "en" => { "greeting" => "Hello" } }.to_yaml)
  end

  after do
    FileUtils.rm_f(input_file)
    FileUtils.rm_f(File.join(output_folder, "it.yml"))
  end

  describe "#initialize" do
    it "validates configuration" do
      expect { described_class.new(config) }.not_to raise_error
    end

    it "raises error for invalid config" do
      invalid_config = BetterTranslate::Configuration.new
      expect { described_class.new(invalid_config) }.to raise_error(BetterTranslate::ConfigurationError)
    end

    it "creates provider from factory" do
      translator = described_class.new(config)
      expect(translator.config).to eq(config)
    end
  end

  describe "#translate_all" do
    let(:translator) { described_class.new(config) }

    it "returns results hash" do
      # Mock the provider to avoid actual API calls
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Ciao")

      results = translator.translate_all

      expect(results).to have_key(:success_count)
      expect(results).to have_key(:failure_count)
      expect(results).to have_key(:errors)
    end

    it "counts successes" do
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Ciao")

      results = translator.translate_all

      expect(results[:success_count]).to eq(1)
      expect(results[:failure_count]).to eq(0)
    end

    it "handles errors and continues" do
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_raise(StandardError.new("API error"))

      results = translator.translate_all

      expect(results[:success_count]).to eq(0)
      expect(results[:failure_count]).to eq(1)
      expect(results[:errors]).not_to be_empty
    end

    it "includes error details" do
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_raise(StandardError.new("API error"))

      results = translator.translate_all

      error = results[:errors].first
      expect(error[:language]).to eq("Italian")
      expect(error[:error]).to include("API error")
    end
  end
end
