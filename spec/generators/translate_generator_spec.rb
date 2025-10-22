# frozen_string_literal: true

require "spec_helper"
require "generator_spec"
require "generators/better_translate/translate/translate_generator"

RSpec.describe BetterTranslate::Generators::TranslateGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  before(:all) do
    prepare_destination
  end

  before do
    prepare_destination

    # Mock Rails.root
    allow(Rails).to receive(:root).and_return(Pathname.new(destination_root))

    # Create mock config file
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    config = {
      "provider" => "chatgpt",
      "openai_key" => "test_key",
      "source_language" => "en",
      "target_languages" => [{ "short_name" => "it", "name" => "Italian" }],
      "input_file" => "config/locales/en.yml",
      "output_folder" => "config/locales"
    }
    File.write(File.join(destination_root, "config/better_translate.yml"), config.to_yaml)

    # Create source locale file
    FileUtils.mkdir_p(File.join(destination_root, "config/locales"))
    File.write(
      File.join(destination_root, "config/locales/en.yml"),
      { "en" => { "greeting" => "Hello" } }.to_yaml
    )
  end

  after(:all) do
    FileUtils.rm_rf(destination_root)
  end

  it "runs translation task" do
    # Mock the translator to avoid actual API calls
    allow_any_instance_of(BetterTranslate::Translator)
      .to receive(:translate_all).and_return({
                                               success_count: 1,
                                               failure_count: 0,
                                               errors: []
                                             })

    expect { run_generator }.not_to raise_error
  end

  it "calls translator with correct configuration" do
    translator_double = instance_double(BetterTranslate::Translator)
    allow(BetterTranslate::Translator).to receive(:new).and_return(translator_double)
    allow(translator_double).to receive(:translate_all).and_return({
                                                                     success_count: 1,
                                                                     failure_count: 0,
                                                                     errors: []
                                                                   })

    run_generator

    expect(BetterTranslate::Translator).to have_received(:new)
    expect(translator_double).to have_received(:translate_all)
  end

  it "handles configuration file not found" do
    # Remove config file
    FileUtils.rm_f(File.join(destination_root, "config/better_translate.yml"))

    # Should not raise error, just return early
    expect { run_generator }.not_to raise_error
  end

  it "sets dry_run option when flag provided" do
    allow_any_instance_of(BetterTranslate::Translator)
      .to receive(:translate_all).and_return({
                                               success_count: 1,
                                               failure_count: 0,
                                               errors: []
                                             })

    run_generator ["--dry-run"]

    expect(BetterTranslate.configuration.dry_run).to be true
  end
end
