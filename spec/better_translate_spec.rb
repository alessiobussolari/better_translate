# frozen_string_literal: true

require "spec_helper"

RSpec.describe BetterTranslate do
  it "has a version number" do
    expect(BetterTranslate::VERSION).not_to be nil
  end

  describe ".configure" do
    it "allows configuration of provider and API keys" do
      BetterTranslate.configure do |config|
        config.provider = :chatgpt
        config.openai_api_key = "test_key"
        config.source_language = "en"
      end

      expect(BetterTranslate.configuration.provider).to eq(:chatgpt)
      expect(BetterTranslate.configuration.openai_api_key).to eq("test_key")
      expect(BetterTranslate.configuration.source_language).to eq("en")
    end
  end
end
