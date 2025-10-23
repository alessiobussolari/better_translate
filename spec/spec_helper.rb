# frozen_string_literal: true

# SimpleCov must be loaded before any application code
require "simplecov"
require "simplecov-cobertura"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
  add_filter "/gemfiles/"

  # Exclude non-testable framework files
  add_filter "lib/better_translate/version.rb"
  add_filter "lib/better_translate/railtie.rb"

  # Generate both HTML (for local viewing) and Cobertura (for Codecov)
  formatter SimpleCov::Formatter::MultiFormatter.new([
                                                       SimpleCov::Formatter::HTMLFormatter,
                                                       SimpleCov::Formatter::CoberturaFormatter
                                                     ])

  # Require 93% minimum coverage
  minimum_coverage 93

  # Track all files in lib/
  track_files "lib/**/*.rb"
end

require "better_translate"
require "vcr"
require "webmock/rspec"
require "dotenv/load"
require "json"

# Configure JSON generation options for consistent formatting
JSON::Ext::Generator::State.new(quirks_mode: true)

# Configure VCR for recording API interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data from cassettes
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV.fetch("OPENAI_API_KEY", nil) }
  config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV.fetch("GEMINI_API_KEY", nil) }
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { ENV.fetch("ANTHROPIC_API_KEY", nil) }

  # Default to :once mode (use existing cassettes, record new ones)
  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[method uri body]
  }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
