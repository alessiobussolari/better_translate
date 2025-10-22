# frozen_string_literal: true

require "tmpdir"
require "webmock/rspec"

RSpec.describe BetterTranslate::Providers::ChatGPTProvider do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :chatgpt
    config.openai_key = "test_key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = __FILE__
    config.output_folder = Dir.tmpdir
    config.cache_enabled = false
    config.verbose = false
    config
  end

  subject(:provider) { described_class.new(config) }

  describe "#translate_text" do
    let(:api_url) { "https://api.openai.com/v1/chat/completions" }
    let(:response_body) do
      {
        choices: [
          {
            message: {
              content: "Ciao"
            }
          }
        ]
      }.to_json
    end

    before do
      stub_request(:post, api_url)
        .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
    end

    it "translates text successfully" do
      result = provider.translate_text("Hello", "it", "Italian")
      expect(result).to eq("Ciao")
    end

    it "validates text input" do
      expect do
        provider.translate_text("", "it", "Italian")
      end.to raise_error(BetterTranslate::ValidationError)
    end

    it "validates language code" do
      expect do
        provider.translate_text("Hello", "invalid", "Italian")
      end.to raise_error(BetterTranslate::ValidationError)
    end

    it "sends correct request to OpenAI API" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url).with do |req|
        body = JSON.parse(req.body)
        body["model"] == "gpt-5-nano" &&
          body["temperature"] == 1.0 &&
          body["messages"].is_a?(Array)
      end)
    end

    it "includes authorization header" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to have_requested(:post, api_url).with(
        headers: { "Authorization" => "Bearer test_key" }
      )
    end

    it "includes translation context if provided" do
      config.translation_context = "Technical documentation"
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url).with do |req|
        body = JSON.parse(req.body)
        system_message = body["messages"].find { |m| m["role"] == "system" }
        system_message["content"].include?("Technical documentation")
      end)
    end

    it "raises TranslationError on API error" do
      stub_request(:post, api_url).to_return(status: 500, body: "Error")

      expect do
        provider.translate_text("Hello", "it", "Italian")
      end.to raise_error(BetterTranslate::TranslationError, /Failed to translate/)
    end

    it "raises TranslationError on invalid JSON response" do
      stub_request(:post, api_url).to_return(status: 200, body: "invalid json")

      expect do
        provider.translate_text("Hello", "it", "Italian")
      end.to raise_error(BetterTranslate::TranslationError, /Failed to parse/)
    end

    it "raises TranslationError when no translation in response" do
      stub_request(:post, api_url).to_return(
        status: 200,
        body: { choices: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect do
        provider.translate_text("Hello", "it", "Italian")
      end.to raise_error(BetterTranslate::TranslationError, /No translation/)
    end
  end

  describe "#translate_batch" do
    let(:api_url) { "https://api.openai.com/v1/chat/completions" }

    before do
      stub_request(:post, api_url)
        .to_return(
          { status: 200, body: { choices: [{ message: { content: "Ciao" } }] }.to_json },
          { status: 200, body: { choices: [{ message: { content: "Mondo" } }] }.to_json }
        )
    end

    it "translates multiple texts" do
      results = provider.translate_batch(%w[Hello World], "it", "Italian")
      expect(results).to eq(%w[Ciao Mondo])
    end
  end
end
