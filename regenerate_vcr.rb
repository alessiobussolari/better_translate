#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "dotenv/load"
require "vcr"
require "webmock/rspec"
require_relative "lib/better_translate"
require "tmpdir"

# Setup VCR
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV["GEMINI_API_KEY"] }
  config.default_cassette_options = { record: :all }
end

test_dir = Dir.mktmpdir("gemini_test")
puts "Test output dir: #{test_dir}"

VCR.use_cassette("rails/dummy_app_gemini_translation", record: :all) do
  config = BetterTranslate::Configuration.new
  config.provider = :gemini
  config.gemini_key = ENV["GEMINI_API_KEY"]
  config.source_language = "en"
  config.target_languages = [{ short_name: "fr", name: "French" }]
  config.input_file = "spec/dummy/config/locales/en.yml"
  config.output_folder = test_dir
  config.cache_enabled = false
  config.verbose = true
  config.validate!

  puts "Starting translation..."
  translator = BetterTranslate::Translator.new(config)
  results = translator.translate_all

  puts "\nResults: #{results.inspect}"
  puts "\nFiles created:"
  Dir.entries(test_dir).each { |f| puts "  - #{f}" unless f.start_with?(".") }

  if results[:success_count].positive?
    puts "\n✓ Successfully regenerated VCR cassette!"
  else
    puts "\n✗ Translation failed"
  end
end
