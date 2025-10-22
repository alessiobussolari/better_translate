#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script to show how to use BetterTranslate with the dummy Rails app
#
# Usage:
#   ruby spec/dummy/demo_translation.rb

require "bundler/setup"
require_relative "../../lib/better_translate"
require "dotenv/load"
require "fileutils"

puts "\n#{"=" * 80}"
puts "BetterTranslate Demo - Dummy Rails App"
puts "#{"=" * 80}\n"

# Paths
dummy_app_path = __dir__
input_file = File.join(dummy_app_path, "config/locales/en.yml")
output_folder = File.join(dummy_app_path, "config/locales")

puts "📂 Input file: #{input_file}"
puts "📂 Output folder: #{output_folder}\n\n"

# Show source content
puts "📄 Source file content (en.yml):"
puts "-" * 80
puts File.read(input_file)
puts "#{"-" * 80}\n\n"

# Configure BetterTranslate
config = BetterTranslate::Configuration.new
config.provider = :chatgpt
config.openai_key = ENV.fetch("OPENAI_API_KEY", nil)
config.source_language = "en"
config.target_languages = [
  { short_name: "it", name: "Italian" },
  { short_name: "fr", name: "French" }
]
config.input_file = input_file
config.output_folder = output_folder
config.cache_enabled = false
config.verbose = true
config.translation_mode = :override

puts "⚙️  Configuration:"
puts "   Provider: #{config.provider}"
puts "   Source: #{config.source_language}"
puts "   Targets: #{config.target_languages.map { |l| l[:name] }.join(", ")}"
puts "   API Key: #{config.openai_key ? "✓ Set" : "✗ Not set"}\n\n"

unless config.openai_key
  puts "❌ ERROR: OPENAI_API_KEY not found in environment"
  puts "\nPlease set your API key:"
  puts "  export OPENAI_API_KEY='your_key_here'"
  puts "  # or create a .env file with: OPENAI_API_KEY=your_key_here\n\n"
  exit 1
end

config.validate!

# Create translator and translate
puts "🚀 Starting translation...\n\n"

translator = BetterTranslate::Translator.new(config)
results = translator.translate_all

puts "\n#{"=" * 80}"
puts "Translation Results"
puts "=" * 80

puts "\n✅ Success: #{results[:success_count]} language(s)"
puts "❌ Failures: #{results[:failure_count]} language(s)"

if results[:errors].any?
  puts "\n🚨 Errors:"
  results[:errors].each do |error|
    puts "  - #{error[:language]}: #{error[:error]}"
  end
end

# Show generated files
puts "\n#{"=" * 80}"
puts "Generated Files"
puts "#{"=" * 80}\n"

config.target_languages.each do |lang|
  output_file = File.join(output_folder, "#{lang[:short_name]}.yml")

  if File.exist?(output_file)
    puts "✓ #{output_file}"
    puts "  Size: #{File.size(output_file)} bytes"

    # Show first few lines
    content = YAML.load_file(output_file)
    puts "  Sample translations:"
    puts "    hello: #{content.dig(lang[:short_name], "hello")}"
    puts "    world: #{content.dig(lang[:short_name], "world")}"
    puts "    messages.success: #{content.dig(lang[:short_name], "messages", "success")}\n\n"
  else
    puts "✗ #{output_file} - NOT FOUND"
  end
end

# Show Italian translation in detail
italian_file = File.join(output_folder, "it.yml")
if File.exist?(italian_file)
  puts "=" * 80
  puts "Italian Translation (it.yml) - Full Content"
  puts "#{"=" * 80}\n"
  puts File.read(italian_file)
end

puts "\n#{"=" * 80}"
puts "Demo Complete!"
puts "#{"=" * 80}\n"

puts "💡 Next steps:"
puts "   1. Check the generated files in: #{output_folder}"
puts "   2. Verify translations are correct"
puts "   3. Use in your Rails app: I18n.t('hello', locale: :it)"
puts "   4. Re-run with different providers (gemini, anthropic)\n\n"
