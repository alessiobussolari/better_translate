# frozen_string_literal: true

RSpec.describe BetterTranslate::DirectTranslator do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :chatgpt
    config.openai_key = "test_key"
    config.source_language = "en"
    config
  end

  subject(:translator) { described_class.new(config) }

  describe "#initialize" do
    it "validates configuration" do
      expect { described_class.new(config) }.not_to raise_error
    end

    it "raises error for invalid config" do
      invalid_config = BetterTranslate::Configuration.new
      expect do
        described_class.new(invalid_config)
      end.to raise_error(BetterTranslate::ConfigurationError)
    end

    it "sets config" do
      expect(translator.config).to eq(config)
    end
  end

  describe "#translate" do
    before do
      # Mock provider to avoid actual API calls
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Ciao")
    end

    it "translates text to target language" do
      result = translator.translate("Hello", to: "it", language_name: "Italian")
      expect(result).to eq("Ciao")
    end

    it "accepts language code as symbol" do
      result = translator.translate("Hello", to: :it, language_name: "Italian")
      expect(result).to eq("Ciao")
    end

    it "requires :to parameter" do
      expect do
        translator.translate("Hello")
      end.to raise_error(ArgumentError, /missing keyword.*:to/)
    end

    it "requires :language_name parameter" do
      expect do
        translator.translate("Hello", to: "it")
      end.to raise_error(ArgumentError, /missing keyword.*:language_name/)
    end

    it "validates text parameter" do
      expect do
        translator.translate(nil, to: "it", language_name: "Italian")
      end.to raise_error(BetterTranslate::ValidationError)
    end

    it "validates language code" do
      expect do
        translator.translate("Hello", to: "", language_name: "Italian")
      end.to raise_error(BetterTranslate::ValidationError)
    end

    it "wraps provider errors in TranslationError" do
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_raise(StandardError.new("API error"))

      expect do
        translator.translate("Hello", to: "it", language_name: "Italian")
      end.to raise_error(BetterTranslate::TranslationError, /API error/)
    end
  end

  describe "#translate_batch" do
    before do
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text)
        .and_return("Ciao", "Arrivederci", "Grazie")
    end

    it "translates multiple texts" do
      texts = ["Hello", "Goodbye", "Thank you"]
      results = translator.translate_batch(texts, to: "it", language_name: "Italian")

      expect(results).to eq(%w[Ciao Arrivederci Grazie])
    end

    it "accepts empty array" do
      results = translator.translate_batch([], to: "it", language_name: "Italian")
      expect(results).to eq([])
    end

    it "requires array parameter" do
      expect do
        translator.translate_batch("Hello", to: "it", language_name: "Italian")
      end.to raise_error(ArgumentError, /must be an Array/)
    end

    it "validates each text in array" do
      expect do
        translator.translate_batch(["Hello", nil, "Bye"], to: "it", language_name: "Italian")
      end.to raise_error(BetterTranslate::ValidationError)
    end

    it "continues on error and returns partial results" do
      call_count = 0
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text) do
        call_count += 1
        case call_count
        when 1
          "Ciao"
        when 2
          raise StandardError, "API error"
        when 3
          "Grazie"
        end
      end

      results = translator.translate_batch(
        ["Hello", "Goodbye", "Thank you"],
        to: "it",
        language_name: "Italian",
        skip_errors: true
      )

      expect(results).to eq(["Ciao", nil, "Grazie"])
    end

    it "raises on first error by default" do
      call_count = 0
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text) do
        call_count += 1
        call_count == 1 ? "Ciao" : raise(StandardError, "API error")
      end

      expect do
        translator.translate_batch(%w[Hello Goodbye], to: "it", language_name: "Italian")
      end.to raise_error(BetterTranslate::TranslationError)
    end
  end
end
