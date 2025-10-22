# frozen_string_literal: true

RSpec.describe BetterTranslate::Analyzer::CodeScanner do
  let(:fixtures_path) { File.join(__dir__, "../../fixtures/analyzer/code") }

  describe "#scan" do
    it "finds i18n keys in Ruby files" do
      scanner = described_class.new(fixtures_path)
      keys = scanner.scan

      expect(keys).to be_a(Set)
      expect(keys).to include("users.greeting")
      expect(keys).to include("users.welcome")
      expect(keys).to include("products.list")
      expect(keys).to include("users.profile.title")
    end

    it "finds i18n keys in ERB files" do
      scanner = described_class.new(fixtures_path)
      keys = scanner.scan

      expect(keys).to include("users.profile.title")
      expect(keys).to include("products.show")
      expect(keys).to include("users.profile.edit")
    end

    it "supports different i18n patterns" do
      scanner = described_class.new(fixtures_path)
      keys = scanner.scan

      # t('key')
      expect(keys).to include("users.greeting")

      # I18n.t('key')
      expect(keys).to include("users.welcome")

      # t("key")
      expect(keys).to include("products.list")
    end

    it "does not include commented keys" do
      scanner = described_class.new(fixtures_path)
      keys = scanner.scan

      expect(keys).not_to include("commented.key")
    end

    it "scans recursively through directories" do
      scanner = described_class.new(fixtures_path)
      keys = scanner.scan

      # Should find keys from both controller.rb and view.erb
      expect(keys.size).to be >= 5
    end

    it "raises error if directory does not exist" do
      scanner = described_class.new("nonexistent_dir")

      expect { scanner.scan }.to raise_error(BetterTranslate::FileError, /does not exist/)
    end

    it "handles single file path" do
      file_path = File.join(fixtures_path, "controller.rb")
      scanner = described_class.new(file_path)
      keys = scanner.scan

      expect(keys).to include("users.greeting")
      expect(keys).not_to include("products.show") # from view.erb
    end
  end

  describe "#key_count" do
    it "returns total number of unique keys found" do
      scanner = described_class.new(fixtures_path)
      scanner.scan

      expect(scanner.key_count).to be >= 5
    end
  end

  describe "#files_scanned" do
    it "returns list of scanned files" do
      scanner = described_class.new(fixtures_path)
      scanner.scan

      files = scanner.files_scanned
      expect(files).to be_an(Array)
      expect(files.any? { |f| f.end_with?("controller.rb") }).to be true
      expect(files.any? { |f| f.end_with?("view.erb") }).to be true
    end
  end
end
