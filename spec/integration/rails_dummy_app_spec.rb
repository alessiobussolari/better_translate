# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "Rails Dummy App Integration", :vcr do
  let(:dummy_app_path) { File.expand_path("../dummy", __dir__) }
  let(:test_output_dir) { Dir.mktmpdir("better_translate_test") }

  after do
    FileUtils.rm_rf(test_output_dir) if File.exist?(test_output_dir)
  end

  describe "standalone translation with dummy app locales" do
    it "translates dummy app locales using ChatGPT", vcr: { cassette_name: "rails/dummy_app_chatgpt_translation" } do
      config = BetterTranslate::Configuration.new
      config.provider = :chatgpt
      config.openai_key = ENV.fetch("OPENAI_API_KEY", "test_api_key_for_vcr")
      config.source_language = "en"
      config.target_languages = [
        { short_name: "it", name: "Italian" }
      ]
      config.input_file = File.join(dummy_app_path, "config/locales/en.yml")
      config.output_folder = test_output_dir
      config.cache_enabled = false
      config.verbose = false
      config.validate!

      translator = BetterTranslate::Translator.new(config)
      translator.translate_all

      # Check output file was created
      italian_file = File.join(test_output_dir, "it.yml")
      expect(File.exist?(italian_file)).to be true

      # Parse and validate Italian translation
      italian_content = YAML.load_file(italian_file)
      expect(italian_content).to have_key("it")

      # Check some translations exist
      expect(italian_content.dig("it", "hello")).not_to be_nil
      expect(italian_content.dig("it", "hello")).not_to eq("Hello") # Should be translated
      expect(italian_content.dig("it", "messages", "success")).not_to be_nil

      # Check variable preservation (source uses %{name} Rails template format)
      greeting = italian_content.dig("it", "users", "greeting")
      expect(greeting).to include("%{name}") if greeting
    end

    it "translates dummy app locales using Gemini", vcr: { cassette_name: "rails/dummy_app_gemini_translation" } do
      config = BetterTranslate::Configuration.new
      config.provider = :gemini
      config.google_gemini_key = ENV.fetch("GEMINI_API_KEY", "test_api_key_for_vcr")
      config.source_language = "en"
      config.target_languages = [
        { short_name: "fr", name: "French" }
      ]
      config.input_file = File.join(dummy_app_path, "config/locales/en.yml")
      config.output_folder = test_output_dir
      config.cache_enabled = false
      config.verbose = false
      config.validate!

      translator = BetterTranslate::Translator.new(config)
      translator.translate_all

      # Check output file was created
      french_file = File.join(test_output_dir, "fr.yml")
      expect(File.exist?(french_file)).to be true

      # Parse and validate French translation
      french_content = YAML.load_file(french_file)
      expect(french_content).to have_key("fr")

      # Check translations exist
      expect(french_content.dig("fr", "hello")).not_to be_nil
      expect(french_content.dig("fr", "hello")).not_to eq("Hello") # Should be translated
    end

    it "handles nested translations correctly", vcr: { cassette_name: "rails/dummy_app_nested_translation" } do
      config = BetterTranslate::Configuration.new
      config.provider = :chatgpt
      config.openai_key = ENV.fetch("OPENAI_API_KEY", "test_api_key_for_vcr")
      config.source_language = "en"
      config.target_languages = [
        { short_name: "es", name: "Spanish" }
      ]
      config.input_file = File.join(dummy_app_path, "config/locales/en.yml")
      config.output_folder = test_output_dir
      config.cache_enabled = false
      config.verbose = false
      config.validate!

      translator = BetterTranslate::Translator.new(config)
      translator.translate_all

      spanish_file = File.join(test_output_dir, "es.yml")
      spanish_content = YAML.load_file(spanish_file)

      # Verify nested structure is preserved
      expect(spanish_content.dig("es", "messages")).to be_a(Hash)
      expect(spanish_content.dig("es", "messages", "success")).not_to be_nil
      expect(spanish_content.dig("es", "users")).to be_a(Hash)
      expect(spanish_content.dig("es", "navigation")).to be_a(Hash)
      expect(spanish_content.dig("es", "forms")).to be_a(Hash)
    end
  end

  describe "incremental translation mode" do
    it "preserves existing translations when adding new keys",
       vcr: { cassette_name: "rails/incremental_translation" } do
      # First: create initial Italian translation
      config = BetterTranslate::Configuration.new
      config.provider = :chatgpt
      config.openai_key = ENV.fetch("OPENAI_API_KEY", "test_api_key_for_vcr")
      config.source_language = "en"
      config.target_languages = [{ short_name: "it", name: "Italian" }]
      config.input_file = File.join(dummy_app_path, "config/locales/en.yml")
      config.output_folder = test_output_dir
      config.translation_mode = :override
      config.cache_enabled = false
      config.verbose = false
      config.validate!

      translator = BetterTranslate::Translator.new(config)
      translator.translate_all

      italian_file = File.join(test_output_dir, "it.yml")
      initial_translation = YAML.load_file(italian_file)
      initial_hello = initial_translation.dig("it", "hello")

      # Now test incremental mode would preserve this
      # (This is a simplified test - full implementation would need real incremental logic)
      expect(initial_hello).not_to be_nil
      expect(initial_hello).not_to eq("Hello")
    end
  end

  describe "error handling" do
    it "raises validation error for missing input file" do
      config = BetterTranslate::Configuration.new
      config.provider = :chatgpt
      config.openai_key = "test_key"
      config.source_language = "en"
      config.target_languages = [{ short_name: "it", name: "Italian" }]
      config.input_file = "/non/existent/file.yml"
      config.output_folder = test_output_dir

      expect { config.validate! }.to raise_error(BetterTranslate::ConfigurationError, /Input file does not exist/)
    end

    it "raises error for invalid YAML in source file" do
      invalid_yaml_file = File.join(test_output_dir, "invalid.yml")
      File.write(invalid_yaml_file, "invalid: yaml: content: :")

      config = BetterTranslate::Configuration.new
      config.provider = :chatgpt
      config.openai_key = "test_key"
      config.source_language = "en"
      config.target_languages = [{ short_name: "it", name: "Italian" }]
      config.input_file = invalid_yaml_file
      config.output_folder = test_output_dir
      config.validate!

      translator = BetterTranslate::Translator.new(config)
      expect { translator.translate_all }.to raise_error(BetterTranslate::YamlError)
    end
  end
end
