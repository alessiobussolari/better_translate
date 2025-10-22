# frozen_string_literal: true

RSpec.describe BetterTranslate::Analyzer::KeyScanner do
  let(:fixture_file) { File.join(__dir__, "../../fixtures/analyzer/locales/en.yml") }

  describe "#scan" do
    it "extracts all flatten keys from YAML file" do
      scanner = described_class.new(fixture_file)
      keys = scanner.scan

      expect(keys).to be_a(Hash)
      expect(keys.keys).to include(
        "users.greeting",
        "users.welcome",
        "users.profile.title",
        "users.profile.edit",
        "products.list",
        "products.show",
        "orphan_key",
        "another.orphan"
      )
    end

    it "returns hash with key paths and their values" do
      scanner = described_class.new(fixture_file)
      keys = scanner.scan

      expect(keys["users.greeting"]).to eq("Hello")
      expect(keys["users.welcome"]).to eq("Welcome %<name>s")
      expect(keys["users.profile.title"]).to eq("User Profile")
    end

    it "handles nested structures correctly" do
      scanner = described_class.new(fixture_file)
      keys = scanner.scan

      expect(keys["users.profile.title"]).to eq("User Profile")
      expect(keys["users.profile.edit"]).to eq("Edit Profile")
    end

    it "raises error if file does not exist" do
      scanner = described_class.new("nonexistent.yml")

      expect { scanner.scan }.to raise_error(BetterTranslate::FileError, /does not exist/)
    end

    it "raises error if file is not valid YAML" do
      invalid_file = File.join(__dir__, "../../fixtures/analyzer/locales/invalid.yml")
      File.write(invalid_file, "invalid: yaml: content:")

      scanner = described_class.new(invalid_file)

      expect { scanner.scan }.to raise_error(BetterTranslate::YamlError)

      File.delete(invalid_file) if File.exist?(invalid_file)
    end

    it "skips root language key (en, it, etc.)" do
      scanner = described_class.new(fixture_file)
      keys = scanner.scan

      expect(keys.keys).not_to include("en")
      expect(keys.keys).to all(start_with(/^[^e]|^e[^n]/)) # Not starting with "en"
    end

    it "returns empty hash for empty YAML file" do
      empty_file = File.join(__dir__, "../../fixtures/analyzer/locales/empty.yml")
      File.write(empty_file, "en:\n")

      scanner = described_class.new(empty_file)
      keys = scanner.scan

      expect(keys).to be_empty

      File.delete(empty_file) if File.exist?(empty_file)
    end
  end

  describe "#key_count" do
    it "returns total number of keys" do
      scanner = described_class.new(fixture_file)
      scanner.scan

      expect(scanner.key_count).to eq(8)
    end
  end
end
