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

    context "with backup enabled" do
      before { config.create_backup = true }

      it "creates backup file when overwriting existing file" do
        # Create existing file
        existing_data = { "it" => { "greeting" => "Salve" } }
        File.write(output_path, existing_data.to_yaml)

        # Overwrite with new data
        handler.write_yaml(output_path, data)

        # Check backup was created with original content
        backup_path = "#{output_path}.bak"
        expect(File.exist?(backup_path)).to be true
        backup_content = YAML.load_file(backup_path)
        expect(backup_content).to eq(existing_data)

        FileUtils.rm_f(backup_path)
      end

      it "does not create backup for new file" do
        handler.write_yaml(output_path, data)

        backup_path = "#{output_path}.bak"
        expect(File.exist?(backup_path)).to be false
      end

      it "rotates backups when max_backups > 1" do
        config.max_backups = 3

        # First write
        data1 = { "it" => { "greeting" => "Salve" } }
        File.write(output_path, data1.to_yaml)

        # Second write (creates .bak)
        data2 = { "it" => { "greeting" => "Ciao" } }
        handler.write_yaml(output_path, data2)

        # Third write (creates .bak.1, moves .bak to .bak.2)
        data3 = { "it" => { "greeting" => "Buongiorno" } }
        handler.write_yaml(output_path, data3)

        # Check backups exist
        expect(File.exist?("#{output_path}.bak")).to be true
        expect(File.exist?("#{output_path}.bak.1")).to be true

        # Check content order (most recent backup is .bak)
        bak_content = YAML.load_file("#{output_path}.bak")
        expect(bak_content).to eq(data2)

        bak1_content = YAML.load_file("#{output_path}.bak.1")
        expect(bak1_content).to eq(data1)

        FileUtils.rm_f("#{output_path}.bak")
        FileUtils.rm_f("#{output_path}.bak.1")
      end

      it "deletes oldest backup when exceeding max_backups" do
        config.max_backups = 2

        # Create initial file
        File.write(output_path, { "it" => { "v" => "1" } }.to_yaml)

        # Write 3 times (should keep only 2 backups)
        3.times do |i|
          handler.write_yaml(output_path, { "it" => { "v" => (i + 2).to_s } })
        end

        # Should have only .bak and .bak.1
        expect(File.exist?("#{output_path}.bak")).to be true
        expect(File.exist?("#{output_path}.bak.1")).to be true
        expect(File.exist?("#{output_path}.bak.2")).to be false

        FileUtils.rm_f("#{output_path}.bak")
        FileUtils.rm_f("#{output_path}.bak.1")
      end
    end

    context "with backup disabled" do
      before { config.create_backup = false }

      it "does not create backup file" do
        # Create existing file
        File.write(output_path, { "it" => { "greeting" => "Salve" } }.to_yaml)

        # Overwrite
        handler.write_yaml(output_path, data)

        # No backup should be created
        backup_path = "#{output_path}.bak"
        expect(File.exist?(backup_path)).to be false
      end
    end

    it "returns diff summary when dry_run mode with diff_preview" do
      config.dry_run = true

      # Create a spy diff_preview
      diff_preview = instance_spy("DiffPreview") # rubocop:disable RSpec/VerifiedDoubleReference
      allow(diff_preview).to receive(:show_diff).with({}, data, output_path).and_return({ added: 1 })

      result = handler.write_yaml(output_path, data, diff_preview: diff_preview)
      expect(result).to eq({ added: 1 })
      expect(diff_preview).to have_received(:show_diff).with({}, data, output_path)
    end

    it "reads existing file when showing diff in dry_run mode" do
      config.dry_run = true

      # Create existing file
      existing_data = { "it" => { "greeting" => "Salve" } }
      File.write(output_path, existing_data.to_yaml)

      diff_preview = instance_spy("DiffPreview") # rubocop:disable RSpec/VerifiedDoubleReference
      allow(diff_preview).to receive(:show_diff).with(existing_data, data, output_path).and_return({ modified: 1 })

      result = handler.write_yaml(output_path, data, diff_preview: diff_preview)
      expect(result).to eq({ modified: 1 })
      expect(diff_preview).to have_received(:show_diff).with(existing_data, data, output_path)
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
