# frozen_string_literal: true

require "tmpdir"
require "webmock/rspec"

RSpec.describe BetterTranslate::Providers::GeminiProvider do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :gemini
    config.google_gemini_key = "test_key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = __FILE__
    config.output_folder = Dir.tmpdir
    config.cache_enabled = false
    config.verbose = false
    config
  end

  subject(:provider) { described_class.new(config) }

  describe "constants" do
    it "has correct API_URL" do
      expect(described_class::API_URL).to eq(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"
      )
    end

    it "has correct MODEL" do
      expect(described_class::MODEL).to eq("gemini-2.5-flash-lite")
    end
  end

  describe "#translate_text" do
    let(:api_url_pattern) { %r{https://generativelanguage.googleapis.com/v1beta/models/.*\?key=test_key} }
    let(:response_body) do
      {
        candidates: [
          {
            content: {
              parts: [
                { text: "Ciao" }
              ]
            }
          }
        ]
      }.to_json
    end

    before do
      stub_request(:post, api_url_pattern)
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

    it "includes API key in URL" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to have_requested(:post, api_url_pattern)
    end

    it "sends correct request body structure" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url_pattern).with do |req|
        body = JSON.parse(req.body)
        body["contents"].is_a?(Array) &&
          body["contents"][0]["parts"].is_a?(Array) &&
          body["contents"][0]["parts"][0]["text"].is_a?(String)
      end)
    end

    it "includes translation context if provided" do
      config.translation_context = "Technical documentation"
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url_pattern).with do |req|
        body = JSON.parse(req.body)
        prompt = body["contents"][0]["parts"][0]["text"]
        prompt.include?("Technical documentation")
      end)
    end

    it "includes placeholder instructions in prompt" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url_pattern).with do |req|
        body = JSON.parse(req.body)
        prompt = body["contents"][0]["parts"][0]["text"]
        prompt.include?("VARIABLE_") && prompt.include?("placeholder")
      end)
    end

    it "includes target language in prompt" do
      provider.translate_text("Hello", "it", "Italian")

      expect(WebMock).to(have_requested(:post, api_url_pattern).with do |req|
        body = JSON.parse(req.body)
        prompt = body["contents"][0]["parts"][0]["text"]
        prompt.include?("Italian")
      end)
    end

    it "raises TranslationError on API error" do
      stub_request(:post, api_url_pattern).to_return(status: 500, body: "Error")

      expect do
        provider.translate_text("Hello", "it", "Italian")
      end.to raise_error(BetterTranslate::TranslationError, /Failed to translate/)
    end

    it "raises TranslationError on invalid JSON response" do
      stub_request(:post, api_url_pattern).to_return(status: 200, body: "invalid json")

      expect do
        provider.translate_text("Hello", "it", "Italian")
      end.to raise_error(BetterTranslate::TranslationError, /Failed to parse/)
    end

    it "raises TranslationError when no translation in response" do
      stub_request(:post, api_url_pattern).to_return(
        status: 200,
        body: { candidates: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect do
        provider.translate_text("Hello", "it", "Italian")
      end.to raise_error(BetterTranslate::TranslationError, /No translation/)
    end
  end

  describe "#translate_batch" do
    let(:api_url_pattern) { %r{https://generativelanguage.googleapis.com/v1beta/models/.*\?key=test_key} }

    before do
      stub_request(:post, api_url_pattern)
        .to_return(
          { status: 200, body: { candidates: [{ content: { parts: [{ text: "Ciao" }] } }] }.to_json },
          { status: 200, body: { candidates: [{ content: { parts: [{ text: "Mondo" }] } }] }.to_json }
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

    it "translates single text in array" do
      stub_request(:post, api_url_pattern)
        .to_return(status: 200, body: { candidates: [{ content: { parts: [{ text: "Ciao" }] } }] }.to_json)

      results = provider.translate_batch(["Hello"], "it", "Italian")
      expect(results).to eq(["Ciao"])
    end
  end

  describe "#build_prompt" do
    it "creates correct prompt structure" do
      prompt = provider.send(:build_prompt, "Hello", "Italian")

      expect(prompt).to include("Italian")
      expect(prompt).to include("Hello")
      expect(prompt).to include("Text:")
    end

    it "includes context when provided" do
      config.translation_context = "Medical terminology"
      prompt = provider.send(:build_prompt, "Hello", "Italian")

      expect(prompt).to include("Medical terminology")
      expect(prompt).to include("Context:")
    end

    it "does not include context when not provided" do
      config.translation_context = nil
      prompt = provider.send(:build_prompt, "Hello", "Italian")

      expect(prompt).not_to include("Context:")
    end

    it "includes placeholder instructions" do
      prompt = provider.send(:build_prompt, "Hello", "Italian")

      expect(prompt).to include("VARIABLE_")
      expect(prompt).to include("placeholder")
    end
  end

  describe "#extract_translation" do
    it "extracts translation from valid response" do
      response = double("response", body: {
        candidates: [{ content: { parts: [{ text: "Ciao" }] } }]
      }.to_json)

      result = provider.send(:extract_translation, response)
      expect(result).to eq("Ciao")
    end

    it "strips whitespace from translation" do
      response = double("response", body: {
        candidates: [{ content: { parts: [{ text: "  Ciao  \n" }] } }]
      }.to_json)

      result = provider.send(:extract_translation, response)
      expect(result).to eq("Ciao")
    end

    it "raises error for empty translation" do
      response = double("response", body: {
        candidates: [{ content: { parts: [{ text: "" }] } }]
      }.to_json)

      expect do
        provider.send(:extract_translation, response)
      end.to raise_error(BetterTranslate::TranslationError, /No translation/)
    end

    it "raises error for nil translation" do
      response = double("response", body: {
        candidates: [{ content: { parts: [{ text: nil }] } }]
      }.to_json)

      expect do
        provider.send(:extract_translation, response)
      end.to raise_error(BetterTranslate::TranslationError, /No translation/)
    end

    it "raises error for missing candidates" do
      response = double("response", body: {}.to_json)

      expect do
        provider.send(:extract_translation, response)
      end.to raise_error(BetterTranslate::TranslationError, /No translation/)
    end

    it "raises error for empty candidates array" do
      response = double("response", body: { candidates: [] }.to_json)

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
    let(:api_url_pattern) { %r{https://generativelanguage.googleapis.com/v1beta/models/.*\?key=test_key} }

    before do
      config.cache_enabled = true
      stub_request(:post, api_url_pattern)
        .to_return(status: 200, body: {
          candidates: [{ content: { parts: [{ text: "Ciao" }] } }]
        }.to_json)
    end

    it "caches translation results" do
      # First call
      provider.translate_text("Hello", "it", "Italian")

      # Second call should use cache (no new request)
      result = provider.translate_text("Hello", "it", "Italian")

      expect(result).to eq("Ciao")
      expect(WebMock).to have_requested(:post, api_url_pattern).once
    end

    it "uses different cache keys for different languages" do
      stub_request(:post, api_url_pattern)
        .to_return(
          { status: 200, body: { candidates: [{ content: { parts: [{ text: "Ciao" }] } }] }.to_json },
          { status: 200, body: { candidates: [{ content: { parts: [{ text: "Bonjour" }] } }] }.to_json }
        )

      provider.translate_text("Hello", "it", "Italian")
      provider.translate_text("Hello", "fr", "French")

      expect(WebMock).to have_requested(:post, api_url_pattern).twice
    end
  end

  describe "error handling with context" do
    let(:api_url_pattern) { %r{https://generativelanguage.googleapis.com/v1beta/models/.*\?key=test_key} }

    it "includes original error context in TranslationError" do
      stub_request(:post, api_url_pattern).to_return(status: 500, body: "Server error")

      begin
        provider.translate_text("Hello", "it", "Italian")
      rescue BetterTranslate::TranslationError => e
        expect(e.message).to include("Failed to translate text with Gemini")
        expect(e.context[:text]).to eq("Hello")
        expect(e.context[:target_lang]).to eq("it")
        expect(e.context[:original_error]).to be_a(BetterTranslate::ApiError)
      end
    end
  end
end
