# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe BetterTranslate::YAMLHandler do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :chatgpt
    config.openai_key = "test_key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = File.join(Dir.tmpdir, "en.yml")
    config.output_folder = Dir.tmpdir
    config.global_exclusions = []
    config.exclusions_per_language = {}
    config.dry_run = false
    config
  end

  subject(:handler) { described_class.new(config) }

  before do
    # Create test input file
    File.write(config.input_file, { "en" => { "greeting" => "Hello", "farewell" => "Goodbye" } }.to_yaml)
  end

  after do
    FileUtils.rm_f(config.input_file)
  end

  describe "#read_yaml" do
    it "reads and parses YAML file" do
      result = handler.read_yaml(config.input_file)
      expect(result).to eq({ "en" => { "greeting" => "Hello", "farewell" => "Goodbye" } })
    end

    it "raises FileError for non-existent file" do
      expect do
        handler.read_yaml("/nonexistent/file.yml")
      end.to raise_error(BetterTranslate::FileError, /File does not exist/)
    end

    it "raises YamlError for invalid YAML" do
      File.write(config.input_file, "invalid: yaml: content:")
      expect do
        handler.read_yaml(config.input_file)
      end.to raise_error(BetterTranslate::YamlError, /Invalid YAML syntax/)
    end

    it "returns empty hash for empty file" do
      File.write(config.input_file, "")
      expect(handler.read_yaml(config.input_file)).to eq({})
    end
  end

  describe "#write_yaml" do
    let(:output_path) { File.join(Dir.tmpdir, "it.yml") }
    let(:data) { { "it" => { "greeting" => "Ciao" } } }

    after do
      FileUtils.rm_f(output_path)
    end

    it "writes data to YAML file" do
      handler.write_yaml(output_path, data)
      result = YAML.load_file(output_path)
      expect(result).to eq(data)
    end

    it "creates directory if not exists" do
      nested_path = File.join(Dir.tmpdir, "nested", "deep", "it.yml")
      handler.write_yaml(nested_path, data)
      expect(File.exist?(nested_path)).to be true
      FileUtils.rm_rf(File.join(Dir.tmpdir, "nested"))
    end

    it "does not write in dry run mode" do
      config.dry_run = true
      handler.write_yaml(output_path, data)
      expect(File.exist?(output_path)).to be false
    end
  end

  describe "#get_source_strings" do
    it "returns flattened source strings" do
      result = handler.get_source_strings
      expect(result).to eq({ "greeting" => "Hello", "farewell" => "Goodbye" })
    end

    it "removes root language key if present" do
      File.write(config.input_file, { "en" => { "nested" => { "key" => "value" } } }.to_yaml)
      result = handler.get_source_strings
      expect(result).to eq({ "nested.key" => "value" })
    end

    it "handles file without language key" do
      File.write(config.input_file, { "greeting" => "Hello" }.to_yaml)
      result = handler.get_source_strings
      expect(result).to eq({ "greeting" => "Hello" })
    end
  end

  describe "#filter_exclusions" do
    let(:strings) { { "greeting" => "Hello", "farewell" => "Goodbye", "admin.title" => "Admin" } }

    it "filters global exclusions" do
      config.global_exclusions = ["admin.title"]
      result = handler.filter_exclusions(strings, "it")
      expect(result).to eq({ "greeting" => "Hello", "farewell" => "Goodbye" })
    end

    it "filters language-specific exclusions" do
      config.exclusions_per_language = { "it" => ["farewell"] }
      result = handler.filter_exclusions(strings, "it")
      expect(result).to eq({ "greeting" => "Hello", "admin.title" => "Admin" })
    end

    it "combines global and language-specific exclusions" do
      config.global_exclusions = ["admin.title"]
      config.exclusions_per_language = { "it" => ["farewell"] }
      result = handler.filter_exclusions(strings, "it")
      expect(result).to eq({ "greeting" => "Hello" })
    end

    it "returns all strings if no exclusions" do
      result = handler.filter_exclusions(strings, "it")
      expect(result).to eq(strings)
    end
  end

  describe "#merge_translations" do
    let(:file_path) { File.join(Dir.tmpdir, "existing.yml") }
    let(:new_translations) { { "new_key" => "New value", "existing" => "Updated" } }

    after do
      FileUtils.rm_f(file_path)
    end

    it "merges with existing file" do
      File.write(file_path, { "existing" => "Old value", "keep" => "Keep this" }.to_yaml)
      result = handler.merge_translations(file_path, new_translations)
      expect(result).to eq({ "new_key" => "New value", "existing" => "Old value", "keep" => "Keep this" })
    end

    it "handles non-existent file" do
      result = handler.merge_translations("/nonexistent.yml", new_translations)
      expect(result).to eq({ "new_key" => "New value", "existing" => "Updated" })
    end
  end

  describe "#build_output_path" do
    it "builds correct output path" do
      path = handler.build_output_path("it")
      expect(path).to eq(File.join(Dir.tmpdir, "it.yml"))
    end
  end
end
