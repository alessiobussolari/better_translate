# frozen_string_literal: true

require "spec_helper"

RSpec.describe BetterTranslate::Service do
  let(:service) { described_class.new }
  let(:text) { "Hello, how are you?" }
  let(:target_lang_code) { "it" }
  let(:target_lang_name) { "Italian" }
  let(:translated_text) { "Ciao, come stai?" }
  let(:mock_provider) { instance_double("BetterTranslate::Providers::Base") }

  before do
    allow(service).to receive(:provider_instance).and_return(mock_provider)
    allow(mock_provider).to receive(:translate_text).and_return(translated_text)
  end

  describe "#translate" do
    it "translates text using the configured provider" do
      expect(mock_provider).to receive(:translate_text).with(text, target_lang_code, target_lang_name)
      result = service.translate(text, target_lang_code, target_lang_name)
      expect(result).to eq(translated_text)
    end

    it "caches the translation result" do
      service.translate(text, target_lang_code, target_lang_name)
      
      # La seconda chiamata non dovrebbe chiamare il provider
      expect(mock_provider).not_to receive(:translate_text)
      service.translate(text, target_lang_code, target_lang_name)
    end

    it "returns cached translation if available" do
      service.translate(text, target_lang_code, target_lang_name)
      result = service.translate(text, target_lang_code, target_lang_name)
      expect(result).to eq(translated_text)
    end

    it "translates text and returns the result" do
      result = service.translate(text, target_lang_code, target_lang_name)
      expect(result).to eq(translated_text)
    end
  end

  describe "caching behavior" do
    let(:max_cache_size) { BetterTranslate::Service::MAX_CACHE_SIZE }
    
    it "maintains cache size within MAX_CACHE_SIZE limit" do
      # Riempi la cache fino al limite
      (max_cache_size + 1).times do |i|
        allow(mock_provider).to receive(:translate_text).and_return("translation #{i}")
        service.translate("text #{i}", target_lang_code, target_lang_name)
      end
      
      cache = service.instance_variable_get(:@translation_cache)
      expect(cache.size).to be <= max_cache_size
    end
    
    it "implements LRU cache behavior" do
      # Riempi la cache
      max_cache_size.times do |i|
        allow(mock_provider).to receive(:translate_text).and_return("translation #{i}")
        service.translate("text #{i}", target_lang_code, target_lang_name)
      end
      
      # Accedi al primo elemento per renderlo il più recente
      allow(mock_provider).to receive(:translate_text).and_return("translation 0")
      service.translate("text 0", target_lang_code, target_lang_name)
      
      # Aggiungi un nuovo elemento che dovrebbe far scadere il secondo più vecchio
      allow(mock_provider).to receive(:translate_text).and_return("translation new")
      service.translate("text new", target_lang_code, target_lang_name)
      
      cache = service.instance_variable_get(:@translation_cache)
      cache_order = service.instance_variable_get(:@cache_order)
      
      expect(cache.keys).to include("text 0:#{target_lang_code}")
      expect(cache.keys).to include("text new:#{target_lang_code}")
      expect(cache.keys).not_to include("text 1:#{target_lang_code}")
    end
  end

  describe "#provider_instance" do
    context "with chatgpt provider" do
      it "creates a ChatgptProvider instance" do
        BetterTranslate.configure do |config|
          config.provider = :chatgpt
          config.openai_key = "test_key"
        end
        # Creiamo un nuovo service dopo la configurazione
        new_service = BetterTranslate::Service.new
        expect(new_service.send(:provider_instance)).to be_a(BetterTranslate::Providers::ChatgptProvider)
      end
    end

    context "with gemini provider" do
      it "creates a GeminiProvider instance" do
        BetterTranslate.configure do |config|
          config.provider = :gemini
          config.gemini_key = "test_key"
        end
        # Creiamo un nuovo service dopo la configurazione
        new_service = BetterTranslate::Service.new
        expect(new_service.send(:provider_instance)).to be_a(BetterTranslate::Providers::GeminiProvider)
      end
    end

    context "with unsupported provider" do
      it "raises an error" do
        BetterTranslate.configure do |config|
          config.provider = :unsupported
        end
        # Creiamo un nuovo service dopo la configurazione
        new_service = BetterTranslate::Service.new
        expect { new_service.send(:provider_instance) }.to raise_error(RuntimeError, /Provider non supportato/)
      end
    end
  end
end
