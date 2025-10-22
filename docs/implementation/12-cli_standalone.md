# 12 - CLI Standalone

[← Previous: 11-Quality Security](./11-quality_security.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md)

---

## CLI Standalone Tool

**PRIORITY: HIGH** - Enables BetterTranslate usage from command line without Ruby code.

### Overview

A standalone command-line interface for BetterTranslate that works:
- **Outside Rails**: Use in any Ruby project or standalone
- **CI/CD Integration**: Automate translations in pipelines
- **Quick Testing**: Test translations without writing code
- **Batch Operations**: Process multiple files easily

---

## 12.1 `exe/better_translate`

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "better_translate"
require_relative "../lib/better_translate/cli"

BetterTranslate::CLI.start(ARGV)
```

Make executable:
```bash
chmod +x exe/better_translate
```

---

## 12.2 `lib/better_translate/cli.rb`

```ruby
# frozen_string_literal: true

require "optparse"

module BetterTranslate
  # Command-line interface for BetterTranslate
  #
  # Provides commands for translation, analysis, and configuration.
  #
  # @example
  #   better_translate translate config/locales/en.yml --to it,fr
  #   better_translate text "Hello world" --from en --to it
  #   better_translate analyze config/locales/*.yml
  #
  class CLI
    # CLI version
    VERSION = BetterTranslate::VERSION

    # Available commands
    COMMANDS = %w[translate text analyze version help].freeze

    # Start CLI with arguments
    #
    # @param args [Array<String>] Command-line arguments
    # @return [void]
    def self.start(args)
      new(args).execute
    end

    # Initialize CLI
    #
    # @param args [Array<String>] Command-line arguments
    def initialize(args)
      @args = args
      @options = {}
    end

    # Execute the CLI command
    #
    # @return [void]
    def execute
      return show_help if @args.empty?

      command = @args.shift
      return show_help unless COMMANDS.include?(command)

      send("command_#{command}")
    rescue StandardError => e
      error "Error: #{e.message}"
      exit 1
    end

    private

    # Command: translate
    #
    # Translate YAML file(s)
    def command_translate
      parse_translate_options

      # Load configuration file if exists
      load_config_file

      # Configure BetterTranslate
      BetterTranslate.configure do |config|
        config.provider = @options[:provider]&.to_sym || :chatgpt
        config.source_language = @options[:from] || "en"
        config.target_languages = build_target_languages(@options[:to])
        config.input_file = @options[:input]
        config.output_folder = @options[:output] || File.dirname(@options[:input])
        config.verbose = @options[:verbose]
        config.dry_run = @options[:dry_run]

        # Set API keys from environment
        config.openai_key = ENV["OPENAI_API_KEY"]
        config.google_gemini_key = ENV["GEMINI_API_KEY"]
        config.anthropic_key = ENV["ANTHROPIC_API_KEY"]

        # Optional settings
        config.translation_context = @options[:context] if @options[:context]
        config.cache_enabled = !@options[:no_cache]
      end

      # Run translation
      success "Translating #{@options[:input]}..."
      results = BetterTranslate.translate_all

      # Show results
      success "✓ Successfully translated #{results[:success_count]} language(s)"
      if results[:failure_count] > 0
        error "✗ Failed to translate #{results[:failure_count]} language(s)"
        results[:errors].each do |err|
          error "  - #{err[:language]}: #{err[:error]}"
        end
      end
    end

    # Command: text
    #
    # Translate text directly
    def command_text
      parse_text_options

      text = @args.shift
      return error("Error: Text argument required") unless text

      success "Translating text..."
      result = BetterTranslate.translate_text(
        text,
        from: @options[:from] || "en",
        to: @options[:to].split(","),
        provider: @options[:provider]&.to_sym,
        context: @options[:context]
      )

      # Display results
      if result.is_a?(String)
        puts "\n#{result}"
      else
        puts "\nTranslations:"
        result.each do |lang, translation|
          puts "  #{lang}: #{translation}"
        end
      end
    end

    # Command: analyze
    #
    # Analyze translation quality
    def command_analyze
      parse_analyze_options

      files = @args
      return error("Error: No files specified") if files.empty?

      success "Analyzing translations..."

      # Load first file as source
      source_file = files.first
      source_data = YAML.load_file(source_file)
      source_lang = source_data.keys.first
      source_strings = flatten_hash(source_data[source_lang] || source_data)

      # Compare with other files
      files[1..].each do |file|
        target_data = YAML.load_file(file)
        target_lang = target_data.keys.first
        target_strings = flatten_hash(target_data[target_lang] || target_data)

        puts "\n#{File.basename(file)} (#{target_lang}):"
        analyze_similarity(source_strings, target_strings)
      end
    end

    # Command: version
    #
    # Show version
    def command_version
      puts "BetterTranslate version #{VERSION}"
    end

    # Command: help
    #
    # Show help
    def command_help
      show_help
    end

    # Parse options for translate command
    def parse_translate_options
      OptionParser.new do |opts|
        opts.banner = "Usage: better_translate translate FILE [options]"

        opts.on("-t", "--to LANGUAGES", "Target languages (comma-separated)") do |langs|
          @options[:to] = langs
        end

        opts.on("-f", "--from LANG", "Source language (default: en)") do |lang|
          @options[:from] = lang
        end

        opts.on("-o", "--output DIR", "Output directory") do |dir|
          @options[:output] = dir
        end

        opts.on("-p", "--provider PROVIDER", "Translation provider (chatgpt, gemini, anthropic)") do |provider|
          @options[:provider] = provider
        end

        opts.on("-c", "--context TEXT", "Translation context") do |context|
          @options[:context] = context
        end

        opts.on("-v", "--verbose", "Verbose output") do
          @options[:verbose] = true
        end

        opts.on("-d", "--dry-run", "Dry run (don't write files)") do
          @options[:dry_run] = true
        end

        opts.on("--no-cache", "Disable caching") do
          @options[:no_cache] = true
        end
      end.parse!(@args)

      @options[:input] = @args.shift
      return error("Error: Input file required") unless @options[:input]
      return error("Error: --to languages required") unless @options[:to]
    end

    # Parse options for text command
    def parse_text_options
      OptionParser.new do |opts|
        opts.banner = "Usage: better_translate text TEXT [options]"

        opts.on("-t", "--to LANGUAGES", "Target languages (comma-separated)") do |langs|
          @options[:to] = langs
        end

        opts.on("-f", "--from LANG", "Source language (default: en)") do |lang|
          @options[:from] = lang
        end

        opts.on("-p", "--provider PROVIDER", "Translation provider") do |provider|
          @options[:provider] = provider
        end

        opts.on("-c", "--context TEXT", "Translation context") do |context|
          @options[:context] = context
        end
      end.parse!(@args)

      return error("Error: --to languages required") unless @options[:to]
    end

    # Parse options for analyze command
    def parse_analyze_options
      OptionParser.new do |opts|
        opts.banner = "Usage: better_translate analyze FILES..."

        opts.on("-t", "--threshold PERCENT", Float, "Similarity threshold (default: 80)") do |threshold|
          @options[:threshold] = threshold
        end
      end.parse!(@args)
    end

    # Build target languages array from comma-separated string
    #
    # @param langs_str [String] Comma-separated language codes
    # @return [Array<Hash>] Array of language hashes
    def build_target_languages(langs_str)
      langs_str.split(",").map do |lang_code|
        {
          short_name: lang_code.strip,
          name: lang_code.strip.upcase
        }
      end
    end

    # Load configuration file if exists
    def load_config_file
      config_file = ".better_translate.yml"
      return unless File.exist?(config_file)

      success "Loading configuration from #{config_file}..."
      config_data = YAML.load_file(config_file)

      # Merge config file options with CLI options (CLI takes precedence)
      config_data.each do |key, value|
        @options[key.to_sym] ||= value
      end
    end

    # Flatten nested hash
    #
    # @param hash [Hash] Nested hash
    # @param prefix [String] Key prefix
    # @return [Hash] Flattened hash
    def flatten_hash(hash, prefix = "")
      result = {}
      hash.each do |key, value|
        full_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
        if value.is_a?(Hash)
          result.merge!(flatten_hash(value, full_key))
        else
          result[full_key] = value
        end
      end
      result
    end

    # Analyze similarity between source and target strings
    #
    # @param source [Hash] Source strings
    # @param target [Hash] Target strings
    def analyze_similarity(source, target)
      threshold = @options[:threshold] || 80.0
      suspicious = []

      source.each do |key, source_value|
        target_value = target[key]
        next unless target_value

        similarity = calculate_similarity(source_value.to_s, target_value.to_s)
        if similarity > threshold / 100.0
          suspicious << {
            key: key,
            source: source_value,
            target: target_value,
            similarity: (similarity * 100).round(1)
          }
        end
      end

      if suspicious.empty?
        success "  ✓ No suspicious translations found"
      else
        warning "  ⚠ Found #{suspicious.size} potentially untranslated strings:"
        suspicious.each do |item|
          puts "    #{item[:key]}: #{item[:similarity]}% similar"
        end
      end
    end

    # Calculate Levenshtein similarity
    #
    # @param str1 [String] First string
    # @param str2 [String] Second string
    # @return [Float] Similarity score (0.0 to 1.0)
    def calculate_similarity(str1, str2)
      return 1.0 if str1 == str2
      return 0.0 if str1.empty? || str2.empty?

      distance = levenshtein_distance(str1.downcase, str2.downcase)
      max_length = [str1.length, str2.length].max
      1.0 - (distance.to_f / max_length)
    end

    # Calculate Levenshtein distance
    #
    # @param str1 [String] First string
    # @param str2 [String] Second string
    # @return [Integer] Edit distance
    def levenshtein_distance(str1, str2)
      matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

      (0..str1.length).each { |i| matrix[i][0] = i }
      (0..str2.length).each { |j| matrix[0][j] = j }

      (1..str1.length).each do |i|
        (1..str2.length).each do |j|
          cost = str1[i - 1] == str2[j - 1] ? 0 : 1
          matrix[i][j] = [
            matrix[i - 1][j] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j - 1] + cost
          ].min
        end
      end

      matrix[str1.length][str2.length]
    end

    # Show help message
    def show_help
      puts <<~HELP
        BetterTranslate CLI - AI-powered YAML translation tool

        Usage: better_translate COMMAND [options]

        Commands:
          translate FILE        Translate YAML file to target languages
          text TEXT             Translate text directly
          analyze FILES         Analyze translation quality
          version               Show version
          help                  Show this help

        Examples:
          # Translate YAML file
          better_translate translate config/locales/en.yml --to it,fr,de

          # Translate text
          better_translate text "Hello world" --from en --to it,fr

          # Analyze translations
          better_translate analyze config/locales/*.yml

        Translate Options:
          -t, --to LANGUAGES       Target languages (comma-separated, required)
          -f, --from LANG          Source language (default: en)
          -o, --output DIR         Output directory
          -p, --provider PROVIDER  Provider: chatgpt, gemini, anthropic (default: chatgpt)
          -c, --context TEXT       Translation context for better accuracy
          -v, --verbose            Verbose output with progress
          -d, --dry-run            Preview changes without writing files
          --no-cache               Disable translation caching

        Text Options:
          -t, --to LANGUAGES       Target languages (comma-separated, required)
          -f, --from LANG          Source language (default: en)
          -p, --provider PROVIDER  Provider: chatgpt, gemini, anthropic
          -c, --context TEXT       Translation context

        Environment Variables:
          OPENAI_API_KEY          API key for ChatGPT provider
          GEMINI_API_KEY          API key for Google Gemini provider
          ANTHROPIC_API_KEY       API key for Anthropic Claude provider

        Configuration File:
          Create .better_translate.yml in project root for default settings.
          See: https://github.com/alessiobussolari/better_translate

        More info: https://github.com/alessiobussolari/better_translate
      HELP
    end

    # Print success message in green
    def success(message)
      puts "\e[32m#{message}\e[0m"
    end

    # Print error message in red
    def error(message)
      puts "\e[31m#{message}\e[0m"
    end

    # Print warning message in yellow
    def warning(message)
      puts "\e[33m#{message}\e[0m"
    end
  end
end
```

---

## 12.3 Update `better_translate.gemspec`

Add executable specification:

```ruby
spec.bindir = "exe"
spec.executables = ["better_translate"]
```

---

## 12.4 Test: `spec/better_translate/cli_spec.rb`

```ruby
# frozen_string_literal: true

RSpec.describe BetterTranslate::CLI do
  describe ".start" do
    it "shows help when no arguments" do
      expect { described_class.start([]) }.to output(/Usage/).to_stdout
    end

    it "shows version" do
      expect { described_class.start(["version"]) }.to output(/BetterTranslate version/).to_stdout
    end

    it "shows help for help command" do
      expect { described_class.start(["help"]) }.to output(/Usage/).to_stdout
    end
  end

  describe "translate command" do
    let(:temp_file) { create_temp_yaml("en" => { "hello" => "Hello" }) }

    it "requires input file" do
      expect {
        described_class.start(["translate", "--to", "it"])
      }.to output(/Error: Input file required/).to_stdout.and raise_error(SystemExit)
    end

    it "requires --to option" do
      expect {
        described_class.start(["translate", temp_file])
      }.to output(/Error: --to languages required/).to_stdout.and raise_error(SystemExit)
    end

    it "translates file", :vcr do
      ENV["OPENAI_API_KEY"] = "test-key"

      expect {
        described_class.start(["translate", temp_file, "--to", "it", "--verbose"])
      }.to output(/Successfully translated/).to_stdout
    end
  end

  describe "text command" do
    it "requires text argument" do
      expect {
        described_class.start(["text", "--to", "it"])
      }.to output(/Error: Text argument required/).to_stdout.and raise_error(SystemExit)
    end

    it "requires --to option" do
      expect {
        described_class.start(["text", "Hello"])
      }.to output(/Error: --to languages required/).to_stdout.and raise_error(SystemExit)
    end

    it "translates text", :vcr do
      ENV["OPENAI_API_KEY"] = "test-key"

      expect {
        described_class.start(["text", "Hello", "--from", "en", "--to", "it"])
      }.to output(/Ciao/).to_stdout
    end
  end
end
```

---

## Usage Examples

### Example 1: Translate YAML File

```bash
# Basic translation
better_translate translate config/locales/en.yml --to it,fr,de

# With custom output directory
better_translate translate config/locales/en.yml --to it --output locales/

# Dry run to preview
better_translate translate config/locales/en.yml --to it --dry-run

# With context for better accuracy
better_translate translate config/locales/en.yml --to it \
  --context "Medical terminology for healthcare app"

# Verbose output
better_translate translate config/locales/en.yml --to it,fr --verbose
```

### Example 2: Translate Text Directly

```bash
# Single language
better_translate text "Hello world" --from en --to it

# Multiple languages
better_translate text "Good morning" --from en --to it,fr,de,es

# With context
better_translate text "The patient presents with symptoms" \
  --from en --to it --context "Medical terminology"

# Using different provider
better_translate text "Hello" --from en --to it --provider anthropic
```

### Example 3: Analyze Translation Quality

```bash
# Analyze all locale files
better_translate analyze config/locales/*.yml

# With custom similarity threshold
better_translate analyze config/locales/*.yml --threshold 90
```

### Example 4: Using Configuration File

Create `.better_translate.yml`:
```yaml
provider: chatgpt
source_language: en
output_folder: config/locales
verbose: true
cache_enabled: true
```

Then simply:
```bash
better_translate translate config/locales/en.yml --to it,fr
# Loads settings from .better_translate.yml
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Translate Locales

on:
  push:
    paths:
      - 'config/locales/en.yml'

jobs:
  translate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2

      - name: Install BetterTranslate
        run: gem install better_translate

      - name: Translate locales
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          better_translate translate config/locales/en.yml \
            --to it,fr,de,es \
            --verbose

      - name: Commit translations
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add config/locales/*.yml
          git commit -m "Auto-translate locales [skip ci]"
          git push
```

---

## Benefits

1. **No Code Required**: Use without writing Ruby code
2. **CI/CD Ready**: Easy integration into automation pipelines
3. **Quick Testing**: Test translations instantly
4. **Standalone**: Works outside Rails/Bundler
5. **Scriptable**: Perfect for automation scripts
6. **Configuration File**: Reusable settings via `.better_translate.yml`

---

## Implementation Checklist

- [ ] Create `exe/better_translate` executable
- [ ] Create `lib/better_translate/cli.rb` with all commands
- [ ] Update gemspec to include executable
- [ ] Create comprehensive CLI tests
- [ ] Update README with CLI documentation
- [ ] Add CI/CD integration examples
- [ ] Test on multiple Ruby versions

---

[← Previous: 11-Quality Security](./11-quality_security.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md)
