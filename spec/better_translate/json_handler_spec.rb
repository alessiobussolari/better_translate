# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "json"

RSpec.describe BetterTranslate::JsonHandler do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :chatgpt
    config.openai_key = "test_key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = File.join(Dir.tmpdir, "en.json")
    config.output_folder = Dir.tmpdir
    config.global_exclusions = []
    config.exclusions_per_language = {}
    config.dry_run = false
    config
  end

  subject(:handler) { described_class.new(config) }

  before do
    # Create test input file
    File.write(config.input_file, JSON.generate({ "en" => { "greeting" => "Hello", "farewell" => "Goodbye" } }))
  end

  after do
    FileUtils.rm_f(config.input_file)
  end

  describe "#read_json" do
    it "reads and parses JSON file" do
      result = handler.read_json(config.input_file)
      expect(result).to eq({ "en" => { "greeting" => "Hello", "farewell" => "Goodbye" } })
    end

    it "raises FileError for non-existent file" do
      expect do
        handler.read_json("/nonexistent/file.json")
      end.to raise_error(BetterTranslate::FileError, /File does not exist/)
    end

    it "raises JsonError for invalid JSON" do
      File.write(config.input_file, "invalid json content {")
      expect do
        handler.read_json(config.input_file)
      end.to raise_error(BetterTranslate::JsonError, /Invalid JSON syntax/)
    end

    it "returns empty hash for empty file" do
      File.write(config.input_file, "")
      expect(handler.read_json(config.input_file)).to eq({})
    end
  end

  describe "#write_json" do
    let(:output_path) { File.join(Dir.tmpdir, "it.json") }
    let(:data) { { "it" => { "greeting" => "Ciao" } } }

    after do
      FileUtils.rm_f(output_path)
      FileUtils.rm_f("#{output_path}.bak")
    end

    it "writes data to JSON file" do
      handler.write_json(output_path, data)
      result = JSON.parse(File.read(output_path))
      expect(result).to eq(data)
    end

    it "formats JSON with proper indentation" do
      handler.write_json(output_path, data)
      content = File.read(output_path)
      expect(content).to include("  \"it\"")
      expect(content).to include("    \"greeting\"")
    end

    it "creates directory if not exists" do
      nested_path = File.join(Dir.tmpdir, "nested", "deep", "it.json")
      handler.write_json(nested_path, data)
      expect(File.exist?(nested_path)).to be true
      FileUtils.rm_rf(File.join(Dir.tmpdir, "nested"))
    end

    it "does not write in dry run mode" do
      config.dry_run = true
      handler.write_json(output_path, data)
      expect(File.exist?(output_path)).to be false
    end

    context "with backup enabled" do
      before { config.create_backup = true }

      it "creates backup file when overwriting existing file" do
        # Create existing file
        existing_data = { "it" => { "greeting" => "Salve" } }
        File.write(output_path, JSON.generate(existing_data))

        # Overwrite with new data
        handler.write_json(output_path, data)

        # Check backup was created with original content
        backup_path = "#{output_path}.bak"
        expect(File.exist?(backup_path)).to be true
        backup_content = JSON.parse(File.read(backup_path))
        expect(backup_content).to eq(existing_data)
      end
    end
  end

  describe "#get_source_strings" do
    it "returns flattened source strings" do
      result = handler.get_source_strings
      expect(result).to eq({ "greeting" => "Hello", "farewell" => "Goodbye" })
    end

    it "removes root language key if present" do
      File.write(config.input_file, JSON.generate({ "en" => { "nested" => { "key" => "value" } } }))
      result = handler.get_source_strings
      expect(result).to eq({ "nested.key" => "value" })
    end

    it "handles file without language key" do
      File.write(config.input_file, JSON.generate({ "greeting" => "Hello" }))
      result = handler.get_source_strings
      expect(result).to eq({ "greeting" => "Hello" })
    end

    it "preserves variable placeholders" do
      File.write(config.input_file, JSON.generate({ "en" => { "msg" => "Hello %<name>s" } }))
      result = handler.get_source_strings
      expect(result).to eq({ "msg" => "Hello %<name>s" })
    end
  end

  describe "#filter_exclusions" do
    it "filters global exclusions" do
      config.global_exclusions = ["greeting"]
      strings = { "greeting" => "Hello", "farewell" => "Goodbye" }
      result = handler.filter_exclusions(strings, "it")
      expect(result).to eq({ "farewell" => "Goodbye" })
    end

    it "filters language-specific exclusions" do
      config.exclusions_per_language = { "it" => ["farewell"] }
      strings = { "greeting" => "Hello", "farewell" => "Goodbye" }
      result = handler.filter_exclusions(strings, "it")
      expect(result).to eq({ "greeting" => "Hello" })
    end
  end

  describe "#merge_translations" do
    let(:output_path) { File.join(Dir.tmpdir, "it.json") }

    after do
      FileUtils.rm_f(output_path)
    end

    it "merges with existing translations" do
      existing = { "it" => { "greeting" => "Salve", "custom" => "Custom" } }
      File.write(output_path, JSON.generate(existing))

      new_translations = { "greeting" => "Ciao", "farewell" => "Addio" }
      result = handler.merge_translations(output_path, new_translations)

      expect(result).to eq({
                             "greeting" => "Salve", # Existing preserved
                             "farewell" => "Addio",  # New added
                             "custom" => "Custom"    # Existing preserved
                           })
    end

    it "returns unflattened translations for new file" do
      new_translations = { "nested.key" => "value" }
      result = handler.merge_translations("/nonexistent.json", new_translations)
      expect(result).to eq({ "nested" => { "key" => "value" } })
    end
  end

  describe "#build_output_path" do
    it "builds path with output folder" do
      path = handler.build_output_path("it")
      expect(path).to eq(File.join(Dir.tmpdir, "it.json"))
    end

    it "builds path without output folder" do
      config.output_folder = nil
      path = handler.build_output_path("it")
      expect(path).to eq("it.json")
    end
  end
end
