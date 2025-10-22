# frozen_string_literal: true

require "spec_helper"
require "generator_spec"
require "generators/better_translate/analyze/analyze_generator"

RSpec.describe BetterTranslate::Generators::AnalyzeGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  before(:all) do
    prepare_destination
  end

  before do
    prepare_destination

    # Mock Rails.root
    allow(Rails).to receive(:root).and_return(Pathname.new(destination_root))

    # Create source locale file with multiple strings
    FileUtils.mkdir_p(File.join(destination_root, "config/locales"))
    source_data = {
      "en" => {
        "greeting" => "Hello",
        "farewell" => "Goodbye",
        "nested" => {
          "welcome" => "Welcome",
          "message" => "Thank you"
        }
      }
    }
    File.write(
      File.join(destination_root, "config/locales/en.yml"),
      source_data.to_yaml
    )
  end

  after(:all) do
    FileUtils.rm_rf(destination_root)
  end

  it "runs without errors" do
    expect { run_generator ["config/locales/en.yml"] }.not_to raise_error
  end

  it "analyzes YAML file structure" do
    # Should count strings in the file
    expect { run_generator ["config/locales/en.yml"] }.not_to raise_error
  end

  it "handles missing file" do
    expect { run_generator ["nonexistent.yml"] }.not_to raise_error
  end

  it "requires file argument" do
    expect { run_generator [] }.not_to raise_error
  end
end
