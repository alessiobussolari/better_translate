# frozen_string_literal: true

require "spec_helper"

RSpec.describe BetterTranslate::Providers::ChatgptProvider, type: :provider do
  include TranslationHelper
  
  let(:api_key) { ENV.fetch("OPENAI_API_KEY", "test_openai_key") }
  let(:provider) { described_class.new(api_key) }
  let(:text) { BetterTranslate::TestCases::STANDARD_CASES[:simple] }
  let(:target_lang_code) { "it" }
  let(:target_lang_name) { "Italian" }

  before do
    # Configura BetterTranslate per evitare errori di nil
    BetterTranslate.configure do |config|
      config.provider = :chatgpt
      config.openai_api_key = api_key
      config.source_language = "en"
    end
  end

  describe "#translate_text" do
    context "when the API returns a successful response" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with(
            headers: {
              "Authorization" => "Bearer #{api_key}",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {
              choices: [
                {
                  message: {
                    content: "Ciao! Come stai? Sto benissimo!"
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

    context "when the API returns an error response" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(
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
        }.to raise_error(RuntimeError, /Errore durante la traduzione con ChatGPT/)
      end
    end

    context "when there is a network error" do
      before do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_timeout
      end

      it "raises an error with the exception details" do
        expect {
          provider.translate_text(text, target_lang_code, target_lang_name)
        }.to raise_error(RuntimeError, /Errore durante la traduzione con ChatGPT/)
      end
    end
  end
end
