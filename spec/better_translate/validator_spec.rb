# frozen_string_literal: true

require "tmpdir"

RSpec.describe BetterTranslate::Validator do
  describe ".validate_language_code!" do
    it "accepts valid 2-letter codes" do
      expect(described_class.validate_language_code!("en")).to be true
      expect(described_class.validate_language_code!("it")).to be true
      expect(described_class.validate_language_code!("fr")).to be true
    end

    it "accepts uppercase codes" do
      expect(described_class.validate_language_code!("EN")).to be true
    end

    it "raises error for nil" do
      expect do
        described_class.validate_language_code!(nil)
      end.to raise_error(BetterTranslate::ValidationError, /Language code cannot be nil/)
    end

    it "raises error for non-string" do
      expect do
        described_class.validate_language_code!(123)
      end.to raise_error(BetterTranslate::ValidationError, /Language code must be a String/)
    end

    it "raises error for empty string" do
      expect do
        described_class.validate_language_code!("")
      end.to raise_error(BetterTranslate::ValidationError, /Language code cannot be empty/)
    end

    it "raises error for invalid format" do
      expect do
        described_class.validate_language_code!("eng")
      end.to raise_error(BetterTranslate::ValidationError, /Language code must be 2 letters/)
    end

    it "raises error for single letter" do
      expect do
        described_class.validate_language_code!("e")
      end.to raise_error(BetterTranslate::ValidationError, /Language code must be 2 letters/)
    end

    it "raises error for codes with numbers" do
      expect do
        described_class.validate_language_code!("e1")
      end.to raise_error(BetterTranslate::ValidationError, /Language code must be 2 letters/)
    end
  end

  describe ".validate_text!" do
    it "accepts valid text" do
      expect(described_class.validate_text!("Hello world")).to be true
    end

    it "raises error for nil" do
      expect do
        described_class.validate_text!(nil)
      end.to raise_error(BetterTranslate::ValidationError, /Text cannot be nil/)
    end

    it "raises error for non-string" do
      expect do
        described_class.validate_text!(123)
      end.to raise_error(BetterTranslate::ValidationError, /Text must be a String/)
    end

    it "raises error for empty string" do
      expect do
        described_class.validate_text!("")
      end.to raise_error(BetterTranslate::ValidationError, /Text cannot be empty/)
    end

    it "raises error for whitespace-only string" do
      expect do
        described_class.validate_text!("   ")
      end.to raise_error(BetterTranslate::ValidationError, /Text cannot be empty/)
    end
  end

  describe ".validate_file_exists!" do
    it "accepts existing files" do
      expect(described_class.validate_file_exists!(__FILE__)).to be true
    end

    it "raises error for nil" do
      expect do
        described_class.validate_file_exists!(nil)
      end.to raise_error(BetterTranslate::FileError, /File path cannot be nil/)
    end

    it "raises error for non-string" do
      expect do
        described_class.validate_file_exists!(123)
      end.to raise_error(BetterTranslate::FileError, /File path must be a String/)
    end

    it "raises error for non-existent file" do
      expect do
        described_class.validate_file_exists!("/nonexistent/file.yml")
      end.to raise_error(BetterTranslate::FileError, /File does not exist/)
    end
  end

  describe ".validate_api_key!" do
    it "accepts valid API keys" do
      expect(described_class.validate_api_key!("sk-test123", provider: :chatgpt)).to be true
    end

    it "raises error for nil" do
      expect do
        described_class.validate_api_key!(nil, provider: :chatgpt)
      end.to raise_error(BetterTranslate::ConfigurationError, /API key for chatgpt cannot be nil/)
    end

    it "raises error for non-string" do
      expect do
        described_class.validate_api_key!(123, provider: :gemini)
      end.to raise_error(BetterTranslate::ConfigurationError, /API key for gemini must be a String/)
    end

    it "raises error for empty string" do
      expect do
        described_class.validate_api_key!("", provider: :anthropic)
      end.to raise_error(BetterTranslate::ConfigurationError, /API key for anthropic cannot be empty/)
    end

    it "raises error for whitespace-only string" do
      expect do
        described_class.validate_api_key!("   ", provider: :chatgpt)
      end.to raise_error(BetterTranslate::ConfigurationError, /API key for chatgpt cannot be empty/)
    end
  end
end
