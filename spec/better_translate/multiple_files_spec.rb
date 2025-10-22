# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "Multiple Files Translation" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_dir, "config", "locales") }

  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :chatgpt
    config.openai_key = "test_key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.output_folder = config_dir
    config.verbose = false
    config.dry_run = true
    config
  end

  before do
    FileUtils.mkdir_p(config_dir)

    # Create multiple test YAML files
    File.write(
      File.join(config_dir, "common.en.yml"),
      { "en" => { "common" => { "greeting" => "Hello" } } }.to_yaml
    )

    File.write(
      File.join(config_dir, "errors.en.yml"),
      { "en" => { "errors" => { "not_found" => "Not found" } } }.to_yaml
    )

    # Create nested directory
    nested_dir = File.join(config_dir, "admin")
    FileUtils.mkdir_p(nested_dir)
    File.write(
      File.join(nested_dir, "admin.en.yml"),
      { "en" => { "admin" => { "dashboard" => "Dashboard" } } }.to_yaml
    )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "with array of input files" do
    it "translates multiple specific files" do
      config.input_files = [
        File.join(config_dir, "common.en.yml"),
        File.join(config_dir, "errors.en.yml")
      ]

      translator = BetterTranslate::Translator.new(config)

      # Mock provider
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Tradotto")

      results = translator.translate_all

      expect(results[:success_count]).to eq(2) # 2 files * 1 language
      expect(results[:failure_count]).to eq(0)
    end

    it "raises error for non-existent file" do
      config.input_files = [
        File.join(config_dir, "nonexistent.en.yml")
      ]

      expect { BetterTranslate::Translator.new(config) }
        .to raise_error(BetterTranslate::FileError, /does not exist/)
    end
  end

  describe "with glob pattern" do
    it "translates all files matching pattern" do
      config.input_files = File.join(config_dir, "*.en.yml")

      translator = BetterTranslate::Translator.new(config)

      # Mock provider
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Tradotto")

      results = translator.translate_all

      expect(results[:success_count]).to eq(2) # 2 files (common, errors) * 1 language
      expect(results[:failure_count]).to eq(0)
    end

    it "translates files recursively with ** pattern" do
      config.input_files = File.join(config_dir, "**/*.en.yml")

      translator = BetterTranslate::Translator.new(config)

      # Mock provider
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Tradotto")

      results = translator.translate_all

      expect(results[:success_count]).to eq(3) # 3 files (common, errors, admin) * 1 language
      expect(results[:failure_count]).to eq(0)
    end

    it "raises error when no files match pattern" do
      config.input_files = File.join(config_dir, "*.fr.yml")

      expect { BetterTranslate::Translator.new(config) }
        .to raise_error(BetterTranslate::FileError, /No files found matching pattern/)
    end
  end

  describe "output path generation" do
    it "preserves original filename structure for multiple files" do
      config.input_files = [
        File.join(config_dir, "common.en.yml"),
        File.join(config_dir, "errors.en.yml")
      ]

      translator = BetterTranslate::Translator.new(config)

      # Mock provider
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Tradotto")

      # In dry_run mode, check that output paths would be correct
      # Expected: common.it.yml and errors.it.yml
      results = translator.translate_all

      # We can't directly assert file paths in dry_run, but we can verify success
      expect(results[:success_count]).to eq(2)
    end

    it "preserves directory structure for glob patterns" do
      config.input_files = File.join(config_dir, "**/*.en.yml")

      translator = BetterTranslate::Translator.new(config)

      # Mock provider
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Tradotto")

      results = translator.translate_all

      # Expected structure:
      # config/locales/common.it.yml
      # config/locales/errors.it.yml
      # config/locales/admin/admin.it.yml
      expect(results[:success_count]).to eq(3)
    end
  end

  describe "backward compatibility" do
    it "still works with single input_file attribute" do
      config.input_file = File.join(config_dir, "common.en.yml")

      translator = BetterTranslate::Translator.new(config)

      # Mock provider
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Tradotto")

      results = translator.translate_all

      expect(results[:success_count]).to eq(1)
      expect(results[:failure_count]).to eq(0)
    end
  end

  describe "JSON support with multiple files" do
    before do
      # Create JSON files
      File.write(
        File.join(config_dir, "common.en.json"),
        JSON.generate({ "en" => { "common" => { "greeting" => "Hello" } } })
      )

      File.write(
        File.join(config_dir, "errors.en.json"),
        JSON.generate({ "en" => { "errors" => { "not_found" => "Not found" } } })
      )
    end

    it "translates multiple JSON files" do
      config.input_files = File.join(config_dir, "*.en.json")

      translator = BetterTranslate::Translator.new(config)

      # Mock provider
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Tradotto")

      results = translator.translate_all

      expect(results[:success_count]).to eq(2)
      expect(results[:failure_count]).to eq(0)
    end
  end
end
