# frozen_string_literal: true

require "tmpdir"

RSpec.describe "Anthropic Provider Integration", :vcr do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :anthropic
    # Use ENV var if available, otherwise use placeholder (VCR will use cassettes)
    config.anthropic_key = ENV.fetch("ANTHROPIC_API_KEY", "test_api_key_for_vcr")
    config.source_language = "en"
    config.target_languages = [
      { short_name: "it", name: "Italian" },
      { short_name: "fr", name: "French" }
    ]
    config.input_file = __FILE__
    config.output_folder = Dir.tmpdir
    config.cache_enabled = false
    config.verbose = false
    config
  end

  subject(:provider) { BetterTranslate::Providers::AnthropicProvider.new(config) }

  describe "real API translation", :integration do
    it "translates simple text to Italian", vcr: { cassette_name: "anthropic/translate_hello_to_italian" } do
      result = provider.translate_text("Hello", "it", "Italian")

      expect(result).to be_a(String)
      expect(result).not_to be_empty
      expect(result.downcase).to include("ciao").or include("salve")
    end

    it "translates simple text to French", vcr: { cassette_name: "anthropic/translate_hello_to_french" } do
      result = provider.translate_text("Hello", "fr", "French")

      expect(result).to be_a(String)
      expect(result).not_to be_empty
      expect(result.downcase).to include("bonjour").or include("salut")
    end

    it "translates with context", vcr: { cassette_name: "anthropic/translate_with_medical_context" } do
      config.translation_context = "Medical terminology"
      result = provider.translate_text("patient", "it", "Italian")

      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it "translates batch of texts", vcr: { cassette_name: "anthropic/translate_batch" } do
      texts = %w[Hello World Goodbye]
      results = provider.translate_batch(texts, "it", "Italian")

      expect(results).to be_an(Array)
      expect(results.size).to eq(3)
      results.each do |result|
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      end
    end

    it "preserves variables in translation", vcr: { cassette_name: "anthropic/translate_with_variables" } do
      text_with_var = "Hello VARIABLE_0, welcome!"
      result = provider.translate_text(text_with_var, "it", "Italian")

      expect(result).to include("VARIABLE_0")
      expect(result).to be_a(String)
    end

    it "handles technical terminology", vcr: { cassette_name: "anthropic/translate_technical_term" } do
      config.translation_context = "Software development"
      result = provider.translate_text("authentication", "it", "Italian")

      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end
  end

  describe "error handling with real API" do
    it "raises error with invalid API key", vcr: { cassette_name: "anthropic/invalid_api_key" } do
      config.anthropic_key = "invalid_key_12345"
      provider_with_bad_key = BetterTranslate::Providers::AnthropicProvider.new(config)

      expect do
        provider_with_bad_key.translate_text("Hello", "it", "Italian")
      end.to raise_error(BetterTranslate::TranslationError)
    end
  end
end
