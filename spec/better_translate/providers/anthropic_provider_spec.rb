# frozen_string_literal: true

require "tmpdir"
require "webmock/rspec"

RSpec.describe BetterTranslate::Providers::AnthropicProvider do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :anthropic
    config.anthropic_key = "test_key"
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
    let(:api_url) { "https://api.anthropic.com/v1/messages" }
    let(:response_body) do
      {
        content: [
          {
            text: "Ciao"
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

    it "sends correct request to Anthropic API" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url).with do |req|
        body = JSON.parse(req.body)
        body["model"] == "claude-haiku-4-5" &&
          body["max_tokens"] == 1024 &&
          body["messages"].is_a?(Array)
      end)
    end

    it "includes x-api-key header" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to have_requested(:post, api_url).with(
        headers: { "x-api-key" => "test_key" }
      )
    end

    it "includes anthropic-version header" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to have_requested(:post, api_url).with(
        headers: { "anthropic-version" => "2023-06-01" }
      )
    end

    it "includes system message in request" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url).with do |req|
        body = JSON.parse(req.body)
        body["system"].include?("professional translator") &&
          body["system"].include?("Italian")
      end)
    end

    it "includes translation context if provided" do
      config.translation_context = "Technical documentation"
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url).with do |req|
        body = JSON.parse(req.body)
        body["system"].include?("Technical documentation")
      end)
    end

    it "includes placeholder instructions in system message" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url).with do |req|
        body = JSON.parse(req.body)
        body["system"].include?("VARIABLE_") &&
          body["system"].include?("placeholder")
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
        body: { content: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect do
        provider.translate_text("Hello", "it", "Italian")
      end.to raise_error(BetterTranslate::TranslationError, /No translation/)
    end

    it "strips whitespace from translation" do
      stub_request(:post, api_url).to_return(
        status: 200,
        body: { content: [{ text: "  Ciao  " }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      result = provider.translate_text("Hello", "it", "Italian")
      expect(result).to eq("Ciao")
    end
  end

  describe "#translate_batch" do
    let(:api_url) { "https://api.anthropic.com/v1/messages" }

    before do
      stub_request(:post, api_url)
        .to_return(
          { status: 200, body: { content: [{ text: "Ciao" }] }.to_json },
          { status: 200, body: { content: [{ text: "Mondo" }] }.to_json }
        )
    end

    it "translates multiple texts" do
      results = provider.translate_batch(%w[Hello World], "it", "Italian")
      expect(results).to eq(%w[Ciao Mondo])
    end

    it "handles empty array" do
      results = provider.translate_batch([], "it", "Italian")
      expect(results).to eq([])
    end
  end

  describe "constants" do
    it "has correct API_URL" do
      expect(described_class::API_URL).to eq("https://api.anthropic.com/v1/messages")
    end

    it "has correct MODEL" do
      expect(described_class::MODEL).to eq("claude-haiku-4-5")
    end

    it "has correct API_VERSION" do
      expect(described_class::API_VERSION).to eq("2023-06-01")
    end
  end

  describe "#build_messages" do
    it "creates correct message structure" do
      messages = provider.send(:build_messages, "Hello", "Italian")

      expect(messages).to be_a(Hash)
      expect(messages[:system]).to be_a(String)
      expect(messages[:messages]).to be_an(Array)
      expect(messages[:messages].size).to eq(1)
      expect(messages[:messages][0][:role]).to eq("user")
      expect(messages[:messages][0][:content]).to eq("Hello")
    end

    it "includes context in system message when provided" do
      config.translation_context = "Medical terminology"
      messages = provider.send(:build_messages, "Hello", "Italian")

      expect(messages[:system]).to include("Medical terminology")
    end

    it "does not include context when not provided" do
      config.translation_context = nil
      messages = provider.send(:build_messages, "Hello", "Italian")

      expect(messages[:system]).not_to include("Context:")
    end
  end

  describe "#extract_translation" do
    it "extracts translation from valid response" do
      response = double("response", body: {
        content: [{ text: "Ciao" }]
      }.to_json)

      result = provider.send(:extract_translation, response)
      expect(result).to eq("Ciao")
    end

    it "strips whitespace from translation" do
      response = double("response", body: {
        content: [{ text: "  Ciao  \n" }]
      }.to_json)

      result = provider.send(:extract_translation, response)
      expect(result).to eq("Ciao")
    end

    it "raises error for empty translation" do
      response = double("response", body: {
        content: [{ text: "" }]
      }.to_json)

      expect do
        provider.send(:extract_translation, response)
      end.to raise_error(BetterTranslate::TranslationError, /No translation/)
    end

    it "raises error for nil translation" do
      response = double("response", body: {
        content: [{ text: nil }]
      }.to_json)

      expect do
        provider.send(:extract_translation, response)
      end.to raise_error(BetterTranslate::TranslationError, /No translation/)
    end

    it "raises error for missing content" do
      response = double("response", body: {}.to_json)

      expect do
        provider.send(:extract_translation, response)
      end.to raise_error(BetterTranslate::TranslationError, /No translation/)
    end

    it "raises error for invalid JSON" do
      response = double("response", body: "not json")

      expect do
        provider.send(:extract_translation, response)
      end.to raise_error(BetterTranslate::TranslationError, /Failed to parse/)
    end

    it "includes context in parse error" do
      response = double("response", body: "invalid")

      begin
        provider.send(:extract_translation, response)
      rescue BetterTranslate::TranslationError => e
        expect(e.context[:body]).to eq("invalid")
        expect(e.context[:error]).not_to be_nil
      end
    end
  end

  describe "caching behavior" do
    let(:api_url) { "https://api.anthropic.com/v1/messages" }

    before do
      config.cache_enabled = true
      stub_request(:post, api_url)
        .to_return(status: 200, body: {
          content: [{ text: "Ciao" }]
        }.to_json)
    end

    it "caches translation results" do
      # First call
      provider.translate_text("Hello", "it", "Italian")

      # Second call should use cache (no new request)
      result = provider.translate_text("Hello", "it", "Italian")

      expect(result).to eq("Ciao")
      expect(WebMock).to have_requested(:post, api_url).once
    end

    it "uses different cache keys for different languages" do
      stub_request(:post, api_url)
        .to_return(
          { status: 200, body: { content: [{ text: "Ciao" }] }.to_json },
          { status: 200, body: { content: [{ text: "Bonjour" }] }.to_json }
        )

      provider.translate_text("Hello", "it", "Italian")
      provider.translate_text("Hello", "fr", "French")

      expect(WebMock).to have_requested(:post, api_url).twice
    end
  end

  describe "error handling with context" do
    let(:api_url) { "https://api.anthropic.com/v1/messages" }

    it "includes original error context in TranslationError" do
      stub_request(:post, api_url).to_return(status: 500, body: "Server error")

      begin
        provider.translate_text("Hello", "it", "Italian")
      rescue BetterTranslate::TranslationError => e
        expect(e.message).to include("Failed to translate text with Anthropic")
        expect(e.context[:text]).to eq("Hello")
        expect(e.context[:target_lang]).to eq("it")
        expect(e.context[:original_error]).to be_a(BetterTranslate::ApiError)
      end
    end
  end
end
