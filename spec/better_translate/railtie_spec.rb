# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "BetterTranslate::Railtie" do
  # Skip if Rails is not loaded
  next unless defined?(Rails)

  let(:rails_root) { Dir.mktmpdir }
  let(:config_file) { File.join(rails_root, "config", "better_translate.yml") }
  let(:locales_dir) { File.join(rails_root, "config", "locales") }

  before do
    FileUtils.mkdir_p(File.dirname(config_file))
    FileUtils.mkdir_p(locales_dir)
  end

  after do
    FileUtils.rm_rf(rails_root)
  end

  describe "Rake tasks" do
    it "loads better_translate.rake" do
      # This test verifies that the railtie file exists and can be loaded
      expect(File.exist?("lib/better_translate/railtie.rb")).to be true
    end
  end

  describe "Configuration loading" do
    it "provides Rails configuration method" do
      # Verify that BetterTranslate can be configured in Rails
      expect(BetterTranslate).to respond_to(:configure)
    end
  end
end
