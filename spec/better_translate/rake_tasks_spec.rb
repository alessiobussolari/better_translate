# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "rake"

RSpec.describe "Rake tasks" do
  let(:rails_root) { Dir.mktmpdir }
  let(:config_file) { File.join(rails_root, "config", "better_translate.yml") }
  let(:locales_dir) { File.join(rails_root, "config", "locales") }
  let(:source_file) { File.join(locales_dir, "en.yml") }

  before do
    # Reset BetterTranslate configuration
    BetterTranslate.reset!

    # Clear existing tasks
    Rake::Task.clear if Rake::Task.tasks.any?
    FileUtils.mkdir_p(File.dirname(config_file))
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

    # Set Rails.root if Rails is defined
    stub_const("Rails", Class.new) unless defined?(Rails)
    allow(Rails).to receive(:root).and_return(Pathname.new(rails_root))

    # Load rake tasks after Rails mock is set
    load File.expand_path("../../lib/tasks/better_translate.rake", __dir__)
  end

  after do
    FileUtils.rm_rf(rails_root)
    Rake::Task.clear
  end

  describe "better_translate:translate" do
    it "exists as a rake task" do
      expect(Rake::Task.task_defined?("better_translate:translate")).to be true
    end

    it "loads configuration from Rails config file" do
      # Mock the translator to avoid actual API calls
      allow_any_instance_of(BetterTranslate::Translator)
        .to receive(:translate_all).and_return({
                                                 success_count: 1,
                                                 failure_count: 0,
                                                 errors: []
                                               })

      expect do
        Rake::Task["better_translate:translate"].execute
      end.not_to raise_error
    end

    it "reports success" do
      allow_any_instance_of(BetterTranslate::Translator)
        .to receive(:translate_all).and_return({
                                                 success_count: 1,
                                                 failure_count: 0,
                                                 errors: []
                                               })

      expect do
        Rake::Task["better_translate:translate"].execute
      end.to output(/Success: 1/).to_stdout
    end

    it "reports failures" do
      allow_any_instance_of(BetterTranslate::Translator)
        .to receive(:translate_all).and_return({
                                                 success_count: 0,
                                                 failure_count: 1,
                                                 errors: [{ language: "Italian", error: "API error" }]
                                               })

      expect do
        Rake::Task["better_translate:translate"].execute
      end.to output(/Failure: 1/).to_stdout
    end

    context "with initializer configuration" do
      before do
        # Configure via initializer (not YAML file)
        BetterTranslate.reset!
        BetterTranslate.configure do |config|
          config.provider = :chatgpt
          config.openai_key = "test_key"
          config.source_language = "en"
          config.target_languages = [{ short_name: "it", name: "Italian" }]
          config.input_file = source_file
          config.output_folder = locales_dir
        end

        # Remove YAML config file to ensure initializer takes precedence
        FileUtils.rm_f(config_file)
      end

      it "uses initializer configuration when YAML file does not exist" do
        allow_any_instance_of(BetterTranslate::Translator)
          .to receive(:translate_all).and_return({
                                                   success_count: 1,
                                                   failure_count: 0,
                                                   errors: []
                                                 })

        expect do
          Rake::Task["better_translate:translate"].execute
        end.not_to raise_error
      end

      it "validates initializer configuration" do
        # Set invalid configuration (missing required fields)
        BetterTranslate.reset!
        BetterTranslate.configure do |config|
          config.provider = :chatgpt
          # Missing openai_key and other required fields
        end

        expect do
          expect do
            Rake::Task["better_translate:translate"].execute
          end.to raise_error(SystemExit)
        end.to output(/Invalid configuration/).to_stdout
      end
    end

    context "without any configuration" do
      before do
        BetterTranslate.reset!
        FileUtils.rm_f(config_file)
      end

      it "shows helpful error message when no configuration found" do
        expect do
          expect do
            Rake::Task["better_translate:translate"].execute
          end.to raise_error(SystemExit)
        end.to output(/No configuration found/).to_stdout
      end

      it "suggests configuration options" do
        expect do
          expect do
            Rake::Task["better_translate:translate"].execute
          end.to raise_error(SystemExit)
        end.to output(%r{Create config/initializers/better_translate.rb}).to_stdout
      end
    end
  end

  describe "better_translate:config:generate" do
    let(:generated_config) { File.join(rails_root, "config", "better_translate.yml") }

    before do
      FileUtils.rm_f(generated_config)
    end

    it "exists as a rake task" do
      expect(Rake::Task.task_defined?("better_translate:config:generate")).to be true
    end

    it "creates config file" do
      Rake::Task["better_translate:config:generate"].execute

      expect(File.exist?(generated_config)).to be true
    end

    it "creates valid YAML config" do
      Rake::Task["better_translate:config:generate"].execute

      config = YAML.load_file(generated_config)
      expect(config).to have_key("provider")
      expect(config).to have_key("source_language")
      expect(config).to have_key("target_languages")
    end

    it "does not overwrite existing config" do
      existing_content = "# Custom config\nprovider: gemini"
      File.write(generated_config, existing_content)

      expect do
        Rake::Task["better_translate:config:generate"].execute
      end.to output(/already exists/).to_stdout

      expect(File.read(generated_config)).to eq(existing_content)
    end
  end
end
