# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe BetterTranslate do
  let(:input_file) { File.join(Dir.tmpdir, "test_en.yml") }
  let(:output_folder) { Dir.tmpdir }
  let(:config_block) do
    proc do |config|
      config.provider = :chatgpt
      config.openai_key = "test_key"
      config.source_language = "en"
      config.target_languages = [{ short_name: "it", name: "Italian" }]
      config.input_file = input_file
      config.output_folder = output_folder
      config.verbose = false
      config.dry_run = true
    end
  end

  before do
    # Create test input file
    File.write(input_file, { "en" => { "greeting" => "Hello" } }.to_yaml)
  end

  after do
    FileUtils.rm_f(input_file)
    FileUtils.rm_f(File.join(output_folder, "it.yml"))
  end

  it "has a version number" do
    expect(BetterTranslate::VERSION).not_to be nil
  end

  it "loads all core components" do
    expect(defined?(BetterTranslate::Error)).to be_truthy
    expect(defined?(BetterTranslate::Configuration)).to be_truthy
    expect(defined?(BetterTranslate::Cache)).to be_truthy
    expect(defined?(BetterTranslate::RateLimiter)).to be_truthy
    expect(defined?(BetterTranslate::Validator)).to be_truthy
    expect(defined?(BetterTranslate::Utils::HashFlattener)).to be_truthy
  end

  describe ".configure" do
    it "yields configuration object" do
      expect do |block|
        described_class.configure(&block)
      end.to yield_with_args(BetterTranslate::Configuration)
    end

    it "sets configuration" do
      described_class.configure do |config|
        config.provider = :chatgpt
        config.openai_key = "my_key"
      end

      expect(described_class.configuration.provider).to eq(:chatgpt)
      expect(described_class.configuration.openai_key).to eq("my_key")
    end

    it "returns the configuration" do
      result = described_class.configure(&config_block)
      expect(result).to be_a(BetterTranslate::Configuration)
    end
  end

  describe ".configuration" do
    it "returns current configuration" do
      described_class.configure(&config_block)
      expect(described_class.configuration).to be_a(BetterTranslate::Configuration)
    end

    it "returns same instance across calls" do
      described_class.configure(&config_block)
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to eq(config2)
    end
  end

  describe ".translate_files" do
    it "performs translation with current configuration" do
      described_class.configure(&config_block)

      # Mock provider to avoid actual API calls
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Ciao")

      results = described_class.translate_files

      expect(results).to have_key(:success_count)
      expect(results).to have_key(:failure_count)
      expect(results).to have_key(:errors)
    end

    it "raises error if not configured" do
      # Reset configuration
      described_class.instance_variable_set(:@configuration, nil)

      expect do
        described_class.translate_files
      end.to raise_error(BetterTranslate::ConfigurationError, /not configured/)
    end

    it "returns success results" do
      described_class.configure(&config_block)

      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Ciao")

      results = described_class.translate_files

      expect(results[:success_count]).to eq(1)
      expect(results[:failure_count]).to eq(0)
    end
  end

  describe ".reset!" do
    it "clears configuration" do
      described_class.configure(&config_block)
      expect(described_class.configuration).not_to be_nil

      described_class.reset!

      # Next call should create new config
      new_config = described_class.configuration
      expect(new_config).to be_a(BetterTranslate::Configuration)
      expect(new_config.provider).to be_nil
    end
  end

  describe ".version" do
    it "returns version string" do
      expect(described_class.version).to eq(BetterTranslate::VERSION)
    end

    it "returns semantic version format" do
      expect(described_class.version).to match(/\d+\.\d+\.\d+/)
    end
  end
end
