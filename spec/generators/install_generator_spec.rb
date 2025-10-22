# frozen_string_literal: true

require "spec_helper"
require "generator_spec"
require "generators/better_translate/install/install_generator"

RSpec.describe BetterTranslate::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  before(:all) do
    prepare_destination
  end

  before do
    prepare_destination
  end

  after(:all) do
    FileUtils.rm_rf(destination_root)
  end

  it "creates initializer file" do
    run_generator

    expect(destination_root).to(have_structure do
      directory "config" do
        directory "initializers" do
          file "better_translate.rb"
        end
      end
    end)
  end

  it "generates valid initializer content" do
    run_generator

    initializer = File.read(File.join(destination_root, "config/initializers/better_translate.rb"))

    expect(initializer).to include("BetterTranslate.configure")
    expect(initializer).to include("config.provider")
    expect(initializer).to include("config.source_language")
    expect(initializer).to include("config.target_languages")
  end

  it "includes all three providers in comments" do
    run_generator

    initializer = File.read(File.join(destination_root, "config/initializers/better_translate.rb"))

    expect(initializer).to include("chatgpt")
    expect(initializer).to include("gemini")
    expect(initializer).to include("anthropic")
  end

  it "includes configuration examples" do
    run_generator

    initializer = File.read(File.join(destination_root, "config/initializers/better_translate.rb"))

    expect(initializer).to include("input_file")
    expect(initializer).to include("output_folder")
    expect(initializer).to include("verbose")
  end

  it "creates YAML config file" do
    run_generator

    expect(destination_root).to(have_structure do
      directory "config" do
        file "better_translate.yml"
      end
    end)
  end

  it "generates valid YAML config" do
    run_generator

    yaml_content = YAML.load_file(File.join(destination_root, "config/better_translate.yml"))

    expect(yaml_content.key?("provider")).to be true
    expect(yaml_content.key?("source_language")).to be true
    expect(yaml_content.key?("target_languages")).to be true
  end

  it "runs without errors" do
    expect { run_generator }.not_to raise_error
  end
end
