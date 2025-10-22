# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe BetterTranslate::CLI do
  let(:config_file) { File.join(Dir.tmpdir, "test_config.yml") }
  let(:locales_dir) { File.join(Dir.tmpdir, "locales") }
  let(:source_file) { File.join(locales_dir, "en.yml") }

  before do
    FileUtils.mkdir_p(locales_dir)

    # Create sample config file
    File.write(config_file, {
      "provider" => "chatgpt",
      "openai_key" => "test_key",
      "source_language" => "en",
      "target_languages" => [
        { "short_name" => "it", "name" => "Italian" }
      ],
      "input_file" => source_file,
      "output_folder" => locales_dir
    }.to_yaml)

    # Create sample source file
    File.write(source_file, { "en" => { "greeting" => "Hello" } }.to_yaml)
  end

  after do
    FileUtils.rm_f(config_file)
    FileUtils.rm_rf(locales_dir)
  end

  describe "#initialize" do
    it "accepts command line arguments" do
      cli = described_class.new(["translate", "--config", config_file])
      expect(cli).to be_a(BetterTranslate::CLI)
    end
  end

  describe "#run" do
    it "runs translate command" do
      cli = described_class.new(["translate", "--config", config_file])

      # Mock the translator
      allow_any_instance_of(BetterTranslate::Translator)
        .to receive(:translate_all).and_return({
                                                 success_count: 1,
                                                 failure_count: 0,
                                                 errors: []
                                               })

      expect { cli.run }.to output(/Success: 1/).to_stdout
    end

    it "shows help when no command provided" do
      cli = described_class.new([])
      expect { cli.run }.to output(/Usage:/).to_stdout
    end

    it "shows help with --help flag" do
      cli = described_class.new(["--help"])
      expect { cli.run }.to output(/Usage:/).to_stdout
    end

    it "shows version with --version flag" do
      cli = described_class.new(["--version"])
      expect { cli.run }.to output(/#{BetterTranslate::VERSION}/).to_stdout
    end

    it "exits with error for unknown command" do
      cli = described_class.new(["unknown"])
      expect { cli.run }.to output(/Unknown command/).to_stdout
    end

    it "requires config file for translate command" do
      cli = described_class.new(["translate"])
      expect { cli.run }.to output(/--config is required/).to_stdout
    end

    it "exits with error if config file not found" do
      cli = described_class.new(["translate", "--config", "/nonexistent/config.yml"])
      expect { cli.run }.to output(/Config file not found/).to_stdout
    end
  end

  describe "generate command" do
    let(:output_config) { File.join(Dir.tmpdir, "generated_config.yml") }

    before do
      FileUtils.rm_f(output_config)
    end

    after do
      FileUtils.rm_f(output_config)
    end

    it "generates config file" do
      cli = described_class.new(["generate", output_config])

      expect { cli.run }.to output(/Generated/).to_stdout
      expect(File.exist?(output_config)).to be true
    end

    it "generates valid YAML config" do
      cli = described_class.new(["generate", output_config])
      cli.run

      config = YAML.load_file(output_config)
      expect(config).to have_key("provider")
      expect(config).to have_key("source_language")
      expect(config).to have_key("target_languages")
    end

    it "does not overwrite existing config without force" do
      File.write(output_config, "existing: content")

      cli = described_class.new(["generate", output_config])
      expect { cli.run }.to output(/already exists/).to_stdout

      expect(File.read(output_config)).to eq("existing: content")
    end

    it "overwrites with --force flag" do
      File.write(output_config, "existing: content")

      cli = described_class.new(["generate", output_config, "--force"])
      expect { cli.run }.to output(/Generated/).to_stdout

      config = YAML.load_file(output_config)
      expect(config).to have_key("provider")
    end
  end

  describe "direct command" do
    it "translates single text" do
      cli = described_class.new([
                                  "direct",
                                  "Hello",
                                  "--to", "it",
                                  "--language-name", "Italian",
                                  "--provider", "chatgpt",
                                  "--api-key", "test_key"
                                ])

      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Ciao")

      expect { cli.run }.to output(/Ciao/).to_stdout
    end

    it "requires text argument" do
      cli = described_class.new(["direct"])
      expect { cli.run }.to output(/Text is required/).to_stdout
    end

    it "requires --to option" do
      cli = described_class.new(%w[direct Hello])
      expect { cli.run }.to output(/--to is required/).to_stdout
    end

    it "requires --provider option" do
      cli = described_class.new(["direct", "Hello", "--to", "it", "--language-name", "Italian"])
      expect { cli.run }.to output(/--provider is required/).to_stdout
    end
  end

  describe "analyze command" do
    let(:yaml_file) { File.join(locales_dir, "en.yml") }
    let(:scan_path) { File.join(Dir.tmpdir, "app") }
    let(:controller_file) { File.join(scan_path, "controllers", "users_controller.rb") }

    before do
      FileUtils.mkdir_p(File.dirname(controller_file))

      # Create sample YAML file
      File.write(yaml_file, {
        "en" => {
          "users" => {
            "greeting" => "Hello",
            "welcome" => "Welcome"
          },
          "orphan_key" => "Unused"
        }
      }.to_yaml)

      # Create sample controller
      File.write(controller_file, <<~RUBY)
        class UsersController < ApplicationController
          def index
            @greeting = t('users.greeting')
          end
        end
      RUBY
    end

    after do
      FileUtils.rm_rf(scan_path)
    end

    it "runs analyze command with text format" do
      cli = described_class.new([
                                  "analyze",
                                  "--source", yaml_file,
                                  "--scan-path", scan_path
                                ])

      output = capture_output { cli.run }

      expect(output).to include("Orphan Keys Analysis")
      expect(output).to include("orphan_key")
    end

    it "generates JSON format report" do
      cli = described_class.new([
                                  "analyze",
                                  "--source", yaml_file,
                                  "--scan-path", scan_path,
                                  "--format", "json"
                                ])

      output = capture_output { cli.run }

      expect(output).to include('"orphans"')
      expect(output).to include('"orphan_key"')
    end

    it "generates CSV format report" do
      cli = described_class.new([
                                  "analyze",
                                  "--source", yaml_file,
                                  "--scan-path", scan_path,
                                  "--format", "csv"
                                ])

      output = capture_output { cli.run }

      expect(output).to include("Key,Value")
      expect(output).to include("orphan_key")
    end

    it "saves report to file when --output specified" do
      output_file = File.join(Dir.tmpdir, "orphan_report.txt")

      cli = described_class.new([
                                  "analyze",
                                  "--source", yaml_file,
                                  "--scan-path", scan_path,
                                  "--output", output_file
                                ])

      begin
        expect { cli.run }.to output(/Report saved/).to_stdout
        expect(File.exist?(output_file)).to be true

        content = File.read(output_file)
        expect(content).to include("Orphan Keys Analysis")
      ensure
        FileUtils.rm_f(output_file)
      end
    end

    it "requires --source option" do
      cli = described_class.new(["analyze", "--scan-path", scan_path])
      expect { cli.run }.to output(/--source is required/).to_stdout
    end

    it "requires --scan-path option" do
      cli = described_class.new(["analyze", "--source", yaml_file])
      expect { cli.run }.to output(/--scan-path is required/).to_stdout
    end

    it "validates source file exists" do
      cli = described_class.new([
                                  "analyze",
                                  "--source", "/nonexistent/file.yml",
                                  "--scan-path", scan_path
                                ])

      expect { cli.run }.to output(/Source file not found/).to_stdout
    end

    it "validates scan path exists" do
      cli = described_class.new([
                                  "analyze",
                                  "--source", yaml_file,
                                  "--scan-path", "/nonexistent/path"
                                ])

      expect { cli.run }.to output(/Scan path not found/).to_stdout
    end

    def capture_output
      old_stdout = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
    end
  end
end
