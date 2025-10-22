# frozen_string_literal: true

require "tmpdir"

RSpec.describe BetterTranslate::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.translation_mode).to eq(:override)
      expect(config.max_concurrent_requests).to eq(3)
      expect(config.request_timeout).to eq(30)
      expect(config.max_retries).to eq(3)
      expect(config.retry_delay).to eq(2.0)
      expect(config.cache_enabled).to be true
      expect(config.cache_size).to eq(1000)
      expect(config.cache_ttl).to be_nil
      expect(config.verbose).to be false
      expect(config.dry_run).to be false
      expect(config.global_exclusions).to eq([])
      expect(config.exclusions_per_language).to eq({})
      expect(config.target_languages).to eq([])
      expect(config.preserve_variables).to be true
    end
  end

  describe "#validate!" do
    context "with valid configuration" do
      before do
        config.provider = :chatgpt
        config.openai_key = "test_key"
        config.source_language = "en"
        config.target_languages = [{ short_name: "it", name: "Italian" }]
        config.input_file = __FILE__ # Use this spec file as test input
        config.output_folder = Dir.tmpdir
      end

      it "returns true" do
        expect(config.validate!).to be true
      end
    end

    context "provider validation" do
      it "raises error when provider is nil" do
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Provider must be set/)
      end

      it "raises error when provider is not a Symbol" do
        config.provider = "chatgpt"
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Provider must be a Symbol/)
      end
    end

    context "API key validation" do
      before do
        config.source_language = "en"
        config.target_languages = [{ short_name: "it", name: "Italian" }]
        config.input_file = __FILE__
        config.output_folder = Dir.tmpdir
      end

      it "requires openai_key for chatgpt provider" do
        config.provider = :chatgpt
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /OpenAI API key is required/)
      end

      it "requires google_gemini_key for gemini provider" do
        config.provider = :gemini
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Google Gemini API key is required/)
      end

      it "requires anthropic_key for anthropic provider" do
        config.provider = :anthropic
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Anthropic API key is required/)
      end
    end

    context "language validation" do
      before do
        config.provider = :chatgpt
        config.openai_key = "test_key"
        config.input_file = __FILE__
        config.output_folder = Dir.tmpdir
      end

      it "requires source_language" do
        config.target_languages = [{ short_name: "it", name: "Italian" }]
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Source language must be set/)
      end

      it "requires target_languages to be an array" do
        config.source_language = "en"
        config.target_languages = "it"
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Target languages must be an array/)
      end

      it "requires at least one target language" do
        config.source_language = "en"
        config.target_languages = []
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /At least one target language is required/)
      end

      it "requires target languages to be hashes" do
        config.source_language = "en"
        config.target_languages = ["it"]
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Each target language must be a Hash/)
      end

      it "requires :short_name in target languages" do
        config.source_language = "en"
        config.target_languages = [{ name: "Italian" }]
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Target language must have :short_name/)
      end

      it "requires :name in target languages" do
        config.source_language = "en"
        config.target_languages = [{ short_name: "it" }]
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Target language must have :name/)
      end
    end

    context "file validation" do
      before do
        config.provider = :chatgpt
        config.openai_key = "test_key"
        config.source_language = "en"
        config.target_languages = [{ short_name: "it", name: "Italian" }]
      end

      it "requires input_file" do
        config.output_folder = Dir.tmpdir
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Input file must be set/)
      end

      it "requires output_folder" do
        config.input_file = __FILE__
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Output folder must be set/)
      end

      it "requires input file to exist" do
        config.input_file = "/nonexistent/file.yml"
        config.output_folder = Dir.tmpdir
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Input file does not exist/)
      end
    end

    context "optional settings validation" do
      before do
        config.provider = :chatgpt
        config.openai_key = "test_key"
        config.source_language = "en"
        config.target_languages = [{ short_name: "it", name: "Italian" }]
        config.input_file = __FILE__
        config.output_folder = Dir.tmpdir
      end

      it "validates translation mode" do
        config.translation_mode = :invalid
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Translation mode must be :override or :incremental/)
      end

      it "validates max_concurrent_requests" do
        config.max_concurrent_requests = 0
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Max concurrent requests must be positive/)
      end

      it "validates request_timeout" do
        config.request_timeout = 0
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Request timeout must be positive/)
      end

      it "validates max_retries" do
        config.max_retries = -1
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Max retries must be non-negative/)
      end

      it "validates cache_size" do
        config.cache_size = 0
        expect do
          config.validate!
        end.to raise_error(BetterTranslate::ConfigurationError, /Cache size must be positive/)
      end
    end
  end
end
