# frozen_string_literal: true

require "spec_helper"

RSpec.describe BetterTranslate::Providers::GeminiProvider, type: :provider do
  include TranslationHelper
  
  let(:api_key) { ENV.fetch("GEMINI_API_KEY", "test_gemini_key") }
  let(:provider) { described_class.new(api_key) }
  let(:text) { BetterTranslate::TestCases::STANDARD_CASES[:simple] }
  let(:target_lang_code) { "it" }
  let(:target_lang_name) { "Italian" }
  let(:gemini_api_url) { "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent" }

  before do
    # Configura BetterTranslate
    BetterTranslate.configure do |config|
      config.provider = :gemini
      config.gemini_api_key = api_key
      config.source_language = "en"
    end
  end

  describe "#translate_text" do
    context "when the API returns a successful response" do
      before do
        # Stub generico per qualsiasi richiesta al provider Gemini
        stub_request(:post, /#{Regexp.escape(gemini_api_url)}.*/).to_return(
          status: 200,
          body: {
            candidates: [
              {
                content: {
                  parts: [
                    {
                      text: "Ciao! Come stai? Sto benissimo!"
                    }
                  ]
                }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "returns the translated text" do
        result = provider.translate_text(text, target_lang_code, target_lang_name)
        expect(result).to eq("Ciao! Come stai? Sto benissimo!")
      end
    end

    context "when the API returns a response with multiple translation options" do
      before do
        # Stub generico per qualsiasi richiesta al provider Gemini
        stub_request(:post, /#{Regexp.escape(gemini_api_url)}.*/).to_return(
          status: 200,
          body: {
            candidates: [
              {
                content: {
                  parts: [
                    {
                      text: "Opzione 1: Ciao! Come stai? Sto benissimo!\nOpzione 2: Salve! Come va? Sto molto bene!"
                    }
                  ]
                }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "returns the first translation option" do
        result = provider.translate_text(text, target_lang_code, target_lang_name)
        expect(result).to include("Ciao! Come stai? Sto benissimo!")
      end
    end

    context "when the API returns a response without asterisks" do
      before do
        # Stub generico per qualsiasi richiesta al provider Gemini
        stub_request(:post, /#{Regexp.escape(gemini_api_url)}.*/).to_return(
          status: 200,
          body: {
            candidates: [
              {
                content: {
                  parts: [
                    {
                      text: "\"Ciao! Come stai? Sto benissimo!\""
                    }
                  ]
                }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "cleans the text correctly" do
        result = provider.translate_text(text, target_lang_code, target_lang_name)
        expect(result).not_to include("\"")
        expect(result).to eq("Ciao! Come stai? Sto benissimo!")
      end
    end

    context "when the API returns an error response" do
      before do
        # Stub generico per qualsiasi richiesta al provider Gemini
        stub_request(:post, /#{Regexp.escape(gemini_api_url)}.*/).to_return(
          status: 400,
          body: {
            error: {
              message: "Invalid API key"
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "raises an error with the response details" do
        expect {
          provider.translate_text(text, target_lang_code, target_lang_name)
        }.to raise_error(RuntimeError, /Errore durante la traduzione con Gemini/)
      end
    end

    context "when there is a network error" do
      before do
        # Stub generico per qualsiasi richiesta al provider Gemini
        stub_request(:post, /#{Regexp.escape(gemini_api_url)}.*/).to_timeout
      end

      it "raises an error with the exception details" do
        expect {
          provider.translate_text(text, target_lang_code, target_lang_name)
        }.to raise_error(RuntimeError, /Errore durante la traduzione con Gemini/)
      end
    end
  end

  describe "integration tests" do
    before(:each) do
      # Stub generico per qualsiasi richiesta al provider Gemini
      stub_request(:post, /#{Regexp.escape(gemini_api_url)}.*/).to_return(
        status: 200,
        body: {
          candidates: [{
            content: {
              parts: [{
                text: "Testo tradotto di esempio"
              }]
            }
          }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "translates text correctly" do
      result = provider.translate_text(text, target_lang_code, target_lang_name)
      expect(valid_translation?(result)).to be true
    end

    it "handles special characters" do
      special_text = BetterTranslate::TestCases::STANDARD_CASES[:special_chars]
      result = provider.translate_text(special_text, target_lang_code, target_lang_name)
      expect(valid_translation?(result)).to be true
    end

    it "translates longer text" do
      long_text = BetterTranslate::TestCases::STANDARD_CASES[:long_text]
      result = provider.translate_text(long_text, target_lang_code, target_lang_name)
      expect(valid_translation?(result)).to be true
    end
  end
end
