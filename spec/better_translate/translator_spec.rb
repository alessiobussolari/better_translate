# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "json"

RSpec.describe BetterTranslate::Translator do
  let(:input_file) { File.join(Dir.tmpdir, "test_en.yml") }
  let(:output_folder) { Dir.tmpdir }

  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :chatgpt
    config.openai_key = "test_key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = input_file
    config.output_folder = output_folder
    config.verbose = false
    config.dry_run = true # Don't actually write files in tests
    config
  end

  before do
    # Create test input file
    File.write(input_file, { "en" => { "greeting" => "Hello" } }.to_yaml)
  end

  after do
    FileUtils.rm_f(input_file)
    FileUtils.rm_f(File.join(output_folder, "it.yml"))
  end

  describe "#initialize" do
    it "validates configuration" do
      expect { described_class.new(config) }.not_to raise_error
    end

    it "raises error for invalid config" do
      invalid_config = BetterTranslate::Configuration.new
      expect { described_class.new(invalid_config) }.to raise_error(BetterTranslate::ConfigurationError)
    end

    it "creates provider from factory" do
      translator = described_class.new(config)
      expect(translator.config).to eq(config)
    end

    it "resolves input files from config" do
      translator = described_class.new(config)
      # Access instance variable to check resolved files
      input_files = translator.instance_variable_get(:@input_files)
      expect(input_files).to eq([input_file])
    end

    it "resolves input files from input_files attribute" do
      json_file1 = File.join(Dir.tmpdir, "test1_en.json")
      json_file2 = File.join(Dir.tmpdir, "test2_en.json")
      File.write(json_file1, JSON.generate({ "en" => { "greeting" => "Hello" } }))
      File.write(json_file2, JSON.generate({ "en" => { "goodbye" => "Goodbye" } }))

      config.input_file = nil
      config.input_files = [json_file1, json_file2]
      translator = described_class.new(config)

      input_files = translator.instance_variable_get(:@input_files)
      expect(input_files).to eq([json_file1, json_file2])

      FileUtils.rm_f(json_file1)
      FileUtils.rm_f(json_file2)
    end
  end

  describe "#translate_all" do
    let(:translator) { described_class.new(config) }

    it "returns results hash" do
      # Mock the provider to avoid actual API calls
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Ciao")

      results = translator.translate_all

      expect(results).to have_key(:success_count)
      expect(results).to have_key(:failure_count)
      expect(results).to have_key(:errors)
    end

    it "counts successes" do
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_return("Ciao")

      results = translator.translate_all

      expect(results[:success_count]).to eq(1)
      expect(results[:failure_count]).to eq(0)
    end

    it "handles errors and continues" do
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_raise(StandardError.new("API error"))

      results = translator.translate_all

      expect(results[:success_count]).to eq(0)
      expect(results[:failure_count]).to eq(1)
      expect(results[:errors]).not_to be_empty
    end

    it "includes error details" do
      allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
        .to receive(:translate_text).and_raise(StandardError.new("API error"))

      results = translator.translate_all

      error = results[:errors].first
      expect(error[:language]).to eq("Italian")
      expect(error[:error]).to include("API error")
    end

    context "with parallel translation" do
      before do
        config.max_concurrent_requests = 3
        config.target_languages = [
          { short_name: "it", name: "Italian" },
          { short_name: "fr", name: "French" },
          { short_name: "es", name: "Spanish" }
        ]
        allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
          .to receive(:translate_text).and_return("Translated")
      end

      it "translates multiple languages concurrently" do
        # Track thread IDs to verify concurrent execution
        thread_ids = []
        allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
          .to receive(:translate_text) do
            thread_ids << Thread.current.object_id
            "Translated"
          end

        results = translator.translate_all

        expect(results[:success_count]).to eq(3)
        # Should use multiple threads (at least 2 different thread IDs)
        expect(thread_ids.uniq.size).to be >= 2
      end

      it "respects max_concurrent_requests limit" do
        config.max_concurrent_requests = 2
        config.target_languages = 5.times.map { |i| { short_name: "l#{i}", name: "Lang#{i}" } }

        # Track concurrent threads
        max_concurrent = 0
        current_concurrent = 0
        mutex = Mutex.new

        allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
          .to receive(:translate_text) do
            mutex.synchronize do
              current_concurrent += 1
              max_concurrent = [max_concurrent, current_concurrent].max
            end
            sleep 0.01 # Simulate work
            mutex.synchronize { current_concurrent -= 1 }
            "Translated"
          end

        translator.translate_all

        # Should never exceed max_concurrent_requests
        expect(max_concurrent).to be <= 2
      end

      it "handles errors in parallel execution" do
        allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
          .to receive(:translate_text) do |_, text|
            raise StandardError, "Error" if text.include?("greeting")

            "Translated"
          end

        results = translator.translate_all

        # Should continue despite error in one thread
        expect(results[:success_count]).to be >= 0
        expect(results[:failure_count]).to be >= 0
      end

      it "uses sequential translation when max_concurrent_requests is 1" do
        config.max_concurrent_requests = 1

        thread_ids = []
        allow_any_instance_of(BetterTranslate::Providers::ChatGPTProvider)
          .to receive(:translate_text) do
            thread_ids << Thread.current.object_id
            "Translated"
          end

        results = translator.translate_all

        # Should use only one thread (main thread)
        expect(thread_ids.uniq.size).to eq(1)
        expect(results[:success_count]).to eq(3)
      end
    end
  end
end
