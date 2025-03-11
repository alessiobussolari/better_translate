# frozen_string_literal: true

require "spec_helper"

RSpec.describe BetterTranslate::Service do
  let(:service) { described_class.new }
  let(:text) { "Hello, world!" }
  let(:target_lang_code) { "it" }
  let(:target_lang_name) { "Italian" }
  let(:translated_text) { "Ciao, mondo!" }

  before do
    BetterTranslate.configure do |config|
      config.provider = :chatgpt
      config.openai_key = "test_key"
    end
  end

  describe "#translate" do
    let(:provider_instance) { instance_double(BetterTranslate::Providers::ChatgptProvider) }
    let(:cache_key) { "#{text}:#{target_lang_code}" }

    before do
      allow(BetterTranslate::Providers::ChatgptProvider).to receive(:new).and_return(provider_instance)
      allow(provider_instance).to receive(:translate_text).and_return(translated_text)
      allow(BetterTranslate::Utils).to receive(:track_metric)
    end

    it "translates text using the configured provider" do
      expect(provider_instance).to receive(:translate_text).with(text, target_lang_code, target_lang_name)
      service.send(:translate, text, target_lang_code, target_lang_name)
    end

    it "caches the translation result" do
      service.send(:translate, text, target_lang_code, target_lang_name)
      cached_result = service.instance_variable_get(:@translation_cache)[cache_key]
      expect(cached_result).to eq(translated_text)
    end

    it "returns cached translation if available" do
      service.send(:translate, text, target_lang_code, target_lang_name)
      expect(provider_instance).not_to receive(:translate)
      result = service.send(:translate, text, target_lang_code, target_lang_name)
      expect(result).to eq(translated_text)
    end

    it "tracks translation metrics" do
      expect(BetterTranslate::Utils).to receive(:track_metric).with(
        "translation_request_duration",
        hash_including(
          provider: :chatgpt,
          text_length: text.length
        )
      )
      service.send(:translate, text, target_lang_code, target_lang_name)
    end
  end

  describe "caching behavior" do
    it "maintains cache size within MAX_CACHE_SIZE limit" do
      (described_class::MAX_CACHE_SIZE + 1).times do |i|
        service.send(:cache_set, "key#{i}", "value#{i}")
      end

      cache = service.instance_variable_get(:@translation_cache)
      expect(cache.size).to eq(described_class::MAX_CACHE_SIZE)
    end

    it "implements LRU cache behavior" do
      service.send(:cache_set, "key1", "value1")
      service.send(:cache_set, "key2", "value2")
      service.send(:cache_get, "key1") # Access key1 to make it most recently used
      cache_order = service.instance_variable_get(:@cache_order)
      expect(cache_order.last).to eq("key1") # key1 should be most recent after access
      
      service.send(:cache_set, "key3", "value3")
      cache_order = service.instance_variable_get(:@cache_order)
      expect(cache_order.last).to eq("key3") # key3 should now be most recent
      expect(cache_order).to include("key1", "key2")
    end
  end

  describe "#provider_instance" do
    context "with chatgpt provider" do
      it "creates a ChatgptProvider instance" do
        expect(service.send(:provider_instance)).to be_a(BetterTranslate::Providers::ChatgptProvider)
      end
    end

    context "with gemini provider" do
      before do
        BetterTranslate.configure do |config|
          config.provider = :gemini
          config.google_gemini_key = "test_key"
        end
      end

      it "creates a GeminiProvider instance" do
        expect(service.send(:provider_instance)).to be_a(BetterTranslate::Providers::GeminiProvider)
      end
    end

    context "with unsupported provider" do
      before do
        BetterTranslate.configure do |config|
          config.provider = :unsupported
        end
      end

      it "raises an error" do
        expect { service.send(:provider_instance) }.to raise_error(/Provider non supportato/)
      end
    end
  end
end
