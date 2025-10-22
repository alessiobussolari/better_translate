# frozen_string_literal: true

require "tmpdir"

RSpec.describe BetterTranslate::ProviderFactory do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = __FILE__
    config.output_folder = Dir.tmpdir
    config
  end

  describe ".create" do
    it "creates ChatGPTProvider" do
      config.provider = :chatgpt
      config.openai_key = "test_key"
      provider = described_class.create(:chatgpt, config)
      expect(provider).to be_a(BetterTranslate::Providers::ChatGPTProvider)
    end

    it "creates GeminiProvider" do
      config.provider = :gemini
      config.google_gemini_key = "test_key"
      provider = described_class.create(:gemini, config)
      expect(provider).to be_a(BetterTranslate::Providers::GeminiProvider)
    end

    it "creates AnthropicProvider" do
      config.provider = :anthropic
      config.anthropic_key = "test_key"
      provider = described_class.create(:anthropic, config)
      expect(provider).to be_a(BetterTranslate::Providers::AnthropicProvider)
    end

    it "raises ProviderNotFoundError for unknown provider" do
      expect do
        described_class.create(:unknown, config)
      end.to raise_error(
        BetterTranslate::ProviderNotFoundError,
        /Unknown provider: unknown. Supported: :chatgpt, :gemini, :anthropic/
      )
    end
  end
end
