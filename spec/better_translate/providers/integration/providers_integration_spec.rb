# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Provider Integration Tests", type: :integration, api_key: true do
  include TranslationHelper
  
  let(:test_text) { BetterTranslate::TestCases::STANDARD_CASES[:simple] }
  let(:target_languages) { BetterTranslate::TestCases::BASIC_LANGUAGES }

  context "with ChatGPT provider" do
    before(:each) do
      configure_provider(:chatgpt)
      WebMock.disable_net_connect!
      stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
        status: 200,
        body: {
          choices: [{
            message: {
              content: "Testo tradotto di esempio"
            }
          }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    after(:each) do
      WebMock.allow_net_connect!
    end

    let(:service) { BetterTranslate::Service.new }

    it "successfully translates text to multiple languages" do
      target_languages.each do |lang|
        result = service.translate(test_text, lang[:code], lang[:name])
        expect(valid_translation?(result)).to be true
        expect(result).not_to eq(test_text)
      end
    end

    it "handles special characters" do
      text = BetterTranslate::TestCases::STANDARD_CASES[:special_chars]
      result = service.translate(text, "it", "Italian")
      expect(valid_translation?(result)).to be true
      expect(result).not_to eq(text)
    end
  end

  context "with Gemini provider" do
    before(:each) do
      configure_provider(:gemini)
      WebMock.disable_net_connect!
      # Stub generico per qualsiasi richiesta al provider Gemini
      stub_request(:post, /https:\/\/generativelanguage\.googleapis\.com\/v1beta\/models\/gemini-2\.0-flash:generateContent.*/).to_return(
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

    after(:each) do
      WebMock.allow_net_connect!
    end

    let(:service) { BetterTranslate::Service.new }

    it "successfully translates text to multiple languages" do
      target_languages.each do |lang|
        result = service.translate(test_text, lang[:code], lang[:name])
        expect(valid_translation?(result)).to be true
        expect(result).not_to eq(test_text)
      end
    end

    it "handles special characters" do
      text = BetterTranslate::TestCases::STANDARD_CASES[:special_chars]
      result = service.translate(text, "it", "Italian")
      expect(valid_translation?(result)).to be true
      expect(result).not_to eq(text)
    end
  end
end
