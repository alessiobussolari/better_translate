# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe "Analyzer Integration" do
  let(:test_dir) { File.join(Dir.tmpdir, "analyzer_integration_test") }
  let(:locales_dir) { File.join(test_dir, "config", "locales") }
  let(:app_dir) { File.join(test_dir, "app") }
  let(:yaml_file) { File.join(locales_dir, "en.yml") }

  before do
    # Create directory structure
    FileUtils.mkdir_p(locales_dir)
    FileUtils.mkdir_p(File.join(app_dir, "controllers"))
    FileUtils.mkdir_p(File.join(app_dir, "views", "users"))
    FileUtils.mkdir_p(File.join(app_dir, "models"))

    # Create locale file with some keys
    File.write(yaml_file, {
      "en" => {
        "users" => {
          "greeting" => "Hello",
          "welcome" => "Welcome %<name>s",
          "profile" => {
            "title" => "User Profile",
            "edit" => "Edit Profile"
          }
        },
        "products" => {
          "list" => "Product List",
          "show" => "Product Details"
        },
        "orphan_key" => "This is never used",
        "another" => {
          "orphan" => "Another unused key"
        }
      }
    }.to_yaml)

    # Create controller file
    File.write(File.join(app_dir, "controllers", "users_controller.rb"), <<~RUBY)
      class UsersController < ApplicationController
        def index
          @greeting = t('users.greeting')
          @welcome = I18n.t('users.welcome', name: current_user.name)
        end

        def show
          @title = t('users.profile.title')
        end
      end
    RUBY

    # Create view file
    File.write(File.join(app_dir, "views", "users", "edit.html.erb"), <<~ERB)
      <h1><%= t('users.profile.edit') %></h1>
      <p><%= t('users.welcome', name: @user.name) %></p>
    ERB

    # Create model file
    File.write(File.join(app_dir, "models", "product.rb"), <<~RUBY)
      class Product < ApplicationRecord
        def display_name
          I18n.translate('products.list')
        end
      end
    RUBY
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe "full analyzer flow" do
    it "detects orphan keys correctly" do
      # Scan keys from YAML
      key_scanner = BetterTranslate::Analyzer::KeyScanner.new(yaml_file)
      all_keys = key_scanner.scan

      expect(all_keys).to be_a(Hash)
      expect(all_keys.size).to eq(8)
      expect(all_keys).to have_key("users.greeting")
      expect(all_keys).to have_key("users.profile.title")
      expect(all_keys).to have_key("orphan_key")

      # Scan code for used keys
      code_scanner = BetterTranslate::Analyzer::CodeScanner.new(app_dir)
      used_keys = code_scanner.scan

      expect(used_keys).to be_a(Set)
      expect(used_keys).to include("users.greeting")
      expect(used_keys).to include("users.welcome")
      expect(used_keys).to include("users.profile.title")
      expect(used_keys).to include("users.profile.edit")
      expect(used_keys).to include("products.list")

      # Detect orphans
      detector = BetterTranslate::Analyzer::OrphanDetector.new(all_keys, used_keys)
      orphans = detector.detect

      expect(orphans).to be_an(Array)
      expect(orphans.size).to eq(3)
      expect(orphans).to include("orphan_key")
      expect(orphans).to include("another.orphan")
      expect(orphans).to include("products.show")

      # Check statistics
      expect(detector.usage_percentage).to eq(62.5) # 5 out of 8 keys used
      expect(detector.orphan_count).to eq(3)

      # Get orphan details
      details = detector.orphan_details
      expect(details["orphan_key"]).to eq("This is never used")
      expect(details["another.orphan"]).to eq("Another unused key")
    end

    it "generates text report correctly" do
      key_scanner = BetterTranslate::Analyzer::KeyScanner.new(yaml_file)
      all_keys = key_scanner.scan

      code_scanner = BetterTranslate::Analyzer::CodeScanner.new(app_dir)
      used_keys = code_scanner.scan

      detector = BetterTranslate::Analyzer::OrphanDetector.new(all_keys, used_keys)
      orphans = detector.detect

      reporter = BetterTranslate::Analyzer::Reporter.new(
        orphans: orphans,
        orphan_details: detector.orphan_details,
        total_keys: all_keys.size,
        used_keys: used_keys.size,
        usage_percentage: detector.usage_percentage,
        format: :text
      )

      report = reporter.generate

      expect(report).to include("Orphan Keys Analysis")
      expect(report).to include("Total keys: 8")
      expect(report).to include("Used keys: 5")
      expect(report).to include("Orphan keys: 3")
      expect(report).to include("Usage: 62.5%")
      expect(report).to include("orphan_key")
      expect(report).to include("another.orphan")
      expect(report).to include("products.show")
    end

    it "generates JSON report correctly" do
      key_scanner = BetterTranslate::Analyzer::KeyScanner.new(yaml_file)
      all_keys = key_scanner.scan

      code_scanner = BetterTranslate::Analyzer::CodeScanner.new(app_dir)
      used_keys = code_scanner.scan

      detector = BetterTranslate::Analyzer::OrphanDetector.new(all_keys, used_keys)
      orphans = detector.detect

      reporter = BetterTranslate::Analyzer::Reporter.new(
        orphans: orphans,
        orphan_details: detector.orphan_details,
        total_keys: all_keys.size,
        used_keys: used_keys.size,
        usage_percentage: detector.usage_percentage,
        format: :json
      )

      report = reporter.generate
      data = JSON.parse(report)

      expect(data["orphans"]).to be_an(Array)
      expect(data["orphans"].size).to eq(3)
      expect(data["total_keys"]).to eq(8)
      expect(data["used_keys"]).to eq(5)
      expect(data["orphan_count"]).to eq(3)
      expect(data["usage_percentage"]).to eq(62.5)
    end

    it "saves report to file" do
      output_file = File.join(test_dir, "orphan_report.txt")

      key_scanner = BetterTranslate::Analyzer::KeyScanner.new(yaml_file)
      all_keys = key_scanner.scan

      code_scanner = BetterTranslate::Analyzer::CodeScanner.new(app_dir)
      used_keys = code_scanner.scan

      detector = BetterTranslate::Analyzer::OrphanDetector.new(all_keys, used_keys)
      orphans = detector.detect

      reporter = BetterTranslate::Analyzer::Reporter.new(
        orphans: orphans,
        orphan_details: detector.orphan_details,
        total_keys: all_keys.size,
        used_keys: used_keys.size,
        usage_percentage: detector.usage_percentage,
        format: :text
      )

      reporter.save_to_file(output_file)

      expect(File.exist?(output_file)).to be true
      content = File.read(output_file)
      expect(content).to include("Orphan Keys Analysis")
      expect(content).to include("orphan_key")
    end

    it "handles case when no orphans found" do
      # Create YAML with only used keys
      minimal_yaml = File.join(locales_dir, "minimal.yml")
      File.write(minimal_yaml, {
        "en" => {
          "users" => {
            "greeting" => "Hello"
          }
        }
      }.to_yaml)

      key_scanner = BetterTranslate::Analyzer::KeyScanner.new(minimal_yaml)
      all_keys = key_scanner.scan

      code_scanner = BetterTranslate::Analyzer::CodeScanner.new(app_dir)
      used_keys = code_scanner.scan

      detector = BetterTranslate::Analyzer::OrphanDetector.new(all_keys, used_keys)
      orphans = detector.detect

      expect(orphans).to be_empty
      expect(detector.usage_percentage).to eq(100.0)

      reporter = BetterTranslate::Analyzer::Reporter.new(
        orphans: orphans,
        orphan_details: detector.orphan_details,
        total_keys: all_keys.size,
        used_keys: used_keys.size,
        usage_percentage: detector.usage_percentage,
        format: :text
      )

      report = reporter.generate
      expect(report).to include("No orphan keys found")
      expect(report).to include("100.0%")
    end

    it "handles nested directory structures" do
      # Create nested directories
      nested_controller_dir = File.join(app_dir, "controllers", "admin", "dashboard")
      FileUtils.mkdir_p(nested_controller_dir)

      File.write(File.join(nested_controller_dir, "stats_controller.rb"), <<~RUBY)
        class Admin::Dashboard::StatsController < ApplicationController
          def index
            @title = t('products.show')
          end
        end
      RUBY

      key_scanner = BetterTranslate::Analyzer::KeyScanner.new(yaml_file)
      all_keys = key_scanner.scan

      code_scanner = BetterTranslate::Analyzer::CodeScanner.new(app_dir)
      used_keys = code_scanner.scan

      # Now products.show should be found
      expect(used_keys).to include("products.show")

      detector = BetterTranslate::Analyzer::OrphanDetector.new(all_keys, used_keys)
      orphans = detector.detect

      # Should have only 2 orphans now instead of 3
      expect(orphans.size).to eq(2)
      expect(orphans).not_to include("products.show")
    end
  end
end
