# 05 - Translation Logic

[← Previous: 04-Provider Architecture](./04-provider_architecture.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 06-Main Module Api →](./06-main_module_api.md)

---

## Translation Logic

### 5.1 `lib/better_translate/yaml_handler.rb`

```ruby
# frozen_string_literal: true

require "yaml"

module BetterTranslate
  # Handles YAML file operations
  #
  # - Reading and parsing YAML files
  # - Writing YAML files with proper formatting
  # - Merging translations (incremental mode)
  # - Handling exclusions
  # - Flattening/unflattening nested structures
  class YAMLHandler
    # @return [Configuration] Configuration object
    attr_reader :config

    # Initialize YAML handler
    #
    # @param config [Configuration] Configuration object
    def initialize(config)
      @config = config
    end

    # Read and parse YAML file
    #
    # @param file_path [String] Path to YAML file
    # @return [Hash] Parsed YAML content
    # @raise [FileError] if file cannot be read
    # @raise [YamlError] if YAML is invalid
    def read_yaml(file_path)
      Validator.validate_file_exists!(file_path)

      content = File.read(file_path)
      YAML.safe_load(content) || {}
    rescue Errno::ENOENT => e
      raise FileError.new("File not found: #{file_path}", context: { error: e.message })
    rescue Psych::SyntaxError => e
      raise YamlError.new("Invalid YAML syntax in #{file_path}", context: { error: e.message })
    end

    # Write hash to YAML file
    #
    # @param file_path [String] Output file path
    # @param data [Hash] Data to write
    # @return [void]
    # @raise [FileError] if file cannot be written
    def write_yaml(file_path, data)
      return if config.dry_run

      # Ensure output directory exists
      FileUtils.mkdir_p(File.dirname(file_path))

      File.write(file_path, YAML.dump(data))
    rescue Errno::EACCES => e
      raise FileError.new("Permission denied: #{file_path}", context: { error: e.message })
    rescue StandardError => e
      raise FileError.new("Failed to write YAML: #{file_path}", context: { error: e.message })
    end

    # Get translatable strings from source YAML
    #
    # @return [Hash] Flattened hash of translatable strings
    def get_source_strings
      source_data = read_yaml(config.input_file)
      # Remove root language key if present (e.g., "en:")
      source_data = source_data[config.source_language] || source_data

      Utils::HashFlattener.flatten(source_data)
    end

    # Filter out excluded keys for a specific language
    #
    # @param strings [Hash] Flattened strings
    # @param target_lang_code [String] Target language code
    # @return [Hash] Filtered strings
    def filter_exclusions(strings, target_lang_code)
      excluded_keys = config.global_exclusions.dup
      excluded_keys += config.exclusions_per_language[target_lang_code] || []

      strings.reject { |key, _| excluded_keys.include?(key) }
    end

    # Merge translated strings with existing file (incremental mode)
    #
    # @param file_path [String] Existing file path
    # @param new_translations [Hash] New translations (flattened)
    # @return [Hash] Merged translations
    def merge_translations(file_path, new_translations)
      existing = File.exist?(file_path) ? read_yaml(file_path) : {}
      existing_flat = Utils::HashFlattener.flatten(existing)

      # Merge: existing takes precedence
      merged = new_translations.merge(existing_flat)

      Utils::HashFlattener.unflatten(merged)
    end

    # Build output file path for target language
    #
    # @param target_lang_code [String] Target language code
    # @return [String] Output file path
    def build_output_path(target_lang_code)
      File.join(config.output_folder, "#{target_lang_code}.yml")
    end
  end
end
```

### 5.2 `lib/better_translate/strategies/base_strategy.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  module Strategies
    # Base class for translation strategies
    #
    # @abstract Subclasses must implement {#translate}
    class BaseStrategy
      # @return [Configuration] Configuration object
      attr_reader :config

      # @return [Providers::BaseHttpProvider] Translation provider
      attr_reader :provider

      # @return [ProgressTracker] Progress tracker
      attr_reader :progress_tracker

      # Initialize the strategy
      #
      # @param config [Configuration] Configuration object
      # @param provider [Providers::BaseHttpProvider] Translation provider
      # @param progress_tracker [ProgressTracker] Progress tracker
      def initialize(config, provider, progress_tracker)
        @config = config
        @provider = provider
        @progress_tracker = progress_tracker
      end

      # Translate strings
      #
      # @param strings [Hash] Flattened hash of strings to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Hash] Translated strings (flattened)
      # @raise [NotImplementedError] Must be implemented by subclasses
      def translate(strings, target_lang_code, target_lang_name)
        raise NotImplementedError, "#{self.class} must implement #translate"
      end
    end
  end
end
```

### 5.3 `lib/better_translate/strategies/deep_strategy.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  module Strategies
    # Deep translation strategy
    #
    # Translates each string individually with detailed progress tracking.
    # Used for smaller files (< 50 strings) to provide more granular progress.
    class DeepStrategy < BaseStrategy
      # Translate strings individually
      #
      # @param strings [Hash] Flattened hash of strings to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Hash] Translated strings (flattened)
      def translate(strings, target_lang_code, target_lang_name)
        translated = {}
        total = strings.size

        strings.each_with_index do |(key, value), index|
          progress_tracker.update(
            language: target_lang_name,
            current_key: key,
            progress: ((index + 1).to_f / total * 100).round(1)
          )

          translated[key] = provider.translate_text(value, target_lang_code, target_lang_name)
        end

        translated
      end
    end
  end
end
```

### 5.4 `lib/better_translate/strategies/batch_strategy.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  module Strategies
    # Batch translation strategy
    #
    # Translates strings in batches for improved performance.
    # Used for larger files (>= 50 strings).
    class BatchStrategy < BaseStrategy
      BATCH_SIZE = 10

      # Translate strings in batches
      #
      # @param strings [Hash] Flattened hash of strings to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Hash] Translated strings (flattened)
      def translate(strings, target_lang_code, target_lang_name)
        translated = {}
        keys = strings.keys
        values = strings.values
        total_batches = (values.size.to_f / BATCH_SIZE).ceil

        values.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
          progress_tracker.update(
            language: target_lang_name,
            current_key: "Batch #{batch_index + 1}/#{total_batches}",
            progress: ((batch_index + 1).to_f / total_batches * 100).round(1)
          )

          translated_batch = provider.translate_batch(batch, target_lang_code, target_lang_name)

          # Map back to keys
          batch_keys = keys[batch_index * BATCH_SIZE, batch.size]
          batch_keys.each_with_index do |key, i|
            translated[key] = translated_batch[i]
          end
        end

        translated
      end
    end
  end
end
```

### 5.5 `lib/better_translate/strategies/strategy_selector.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  module Strategies
    # Selects the appropriate translation strategy based on content size
    class StrategySelector
      DEEP_STRATEGY_THRESHOLD = 50

      # Select the appropriate strategy
      #
      # @param strings_count [Integer] Number of strings to translate
      # @param config [Configuration] Configuration object
      # @param provider [Providers::BaseHttpProvider] Translation provider
      # @param progress_tracker [ProgressTracker] Progress tracker
      # @return [BaseStrategy] Selected strategy instance
      def self.select(strings_count, config, provider, progress_tracker)
        if strings_count < DEEP_STRATEGY_THRESHOLD
          DeepStrategy.new(config, provider, progress_tracker)
        else
          BatchStrategy.new(config, provider, progress_tracker)
        end
      end
    end
  end
end
```

### 5.6 `lib/better_translate/progress_tracker.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  # Tracks and displays translation progress
  #
  # Shows real-time progress updates with colored console output.
  class ProgressTracker
    # @return [Boolean] Whether to show progress
    attr_reader :enabled

    # Initialize progress tracker
    #
    # @param enabled [Boolean] Whether to show progress (default: true)
    def initialize(enabled: true)
      @enabled = enabled
      @start_time = Time.now
    end

    # Update progress
    #
    # @param language [String] Current language being translated
    # @param current_key [String] Current translation key
    # @param progress [Float] Progress percentage (0-100)
    # @return [void]
    def update(language:, current_key:, progress:)
      return unless enabled

      elapsed = Time.now - @start_time
      estimated_total = elapsed / (progress / 100.0)
      remaining = estimated_total - elapsed

      message = format(
        "\r[BetterTranslate] %s | %s | %.1f%% | Elapsed: %s | Remaining: ~%s",
        colorize(language, :cyan),
        truncate(current_key, 40),
        progress,
        format_time(elapsed),
        format_time(remaining)
      )

      print message
      $stdout.flush

      puts "" if progress >= 100.0 # New line when complete
    end

    # Mark translation as complete for a language
    #
    # @param language [String] Language name
    # @param total_strings [Integer] Total number of strings translated
    # @return [void]
    def complete(language, total_strings)
      return unless enabled

      elapsed = Time.now - @start_time
      puts colorize("✓ #{language}: #{total_strings} strings translated in #{format_time(elapsed)}", :green)
    end

    # Display an error
    #
    # @param language [String] Language name
    # @param error [StandardError] The error that occurred
    # @return [void]
    def error(language, error)
      return unless enabled

      puts colorize("✗ #{language}: #{error.message}", :red)
    end

    # Reset the progress tracker
    #
    # @return [void]
    def reset
      @start_time = Time.now
    end

    private

    def format_time(seconds)
      return "0s" if seconds <= 0

      minutes = (seconds / 60).to_i
      secs = (seconds % 60).to_i

      if minutes > 0
        "#{minutes}m #{secs}s"
      else
        "#{secs}s"
      end
    end

    def truncate(text, max_length)
      return text if text.length <= max_length

      "#{text[0...(max_length - 3)]}..."
    end

    def colorize(text, color)
      return text unless $stdout.tty?

      colors = {
        red: "\e[31m",
        green: "\e[32m",
        cyan: "\e[36m",
        reset: "\e[0m"
      }

      "#{colors[color]}#{text}#{colors[:reset]}"
    end
  end
end
```

### 5.7 `lib/better_translate/translator.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  # Main translator class
  #
  # Coordinates the translation process using configuration, providers,
  # strategies, and YAML handling.
  #
  # @example Basic usage
  #   translator = Translator.new(config)
  #   results = translator.translate_all
  #
  class Translator
    # @return [Configuration] Configuration object
    attr_reader :config

    # Initialize translator
    #
    # @param config [Configuration] Configuration object
    def initialize(config)
      @config = config
      @config.validate!
      @provider = ProviderFactory.create(config.provider, config)
      @yaml_handler = YAMLHandler.new(config)
      @progress_tracker = ProgressTracker.new(enabled: config.verbose)
    end

    # Translate to all target languages
    #
    # @return [Hash] Results hash with :success_count, :failure_count, :errors
    def translate_all
      source_strings = @yaml_handler.get_source_strings

      results = {
        success_count: 0,
        failure_count: 0,
        errors: []
      }

      config.target_languages.each do |lang|
        begin
          translate_language(source_strings, lang)
          results[:success_count] += 1
        rescue StandardError => e
          results[:failure_count] += 1
          results[:errors] << {
            language: lang[:name],
            error: e.message,
            context: e.respond_to?(:context) ? e.context : {}
          }
          @progress_tracker.error(lang[:name], e)
        end
      end

      results
    end

    private

    def translate_language(source_strings, lang)
      target_lang_code = lang[:short_name]
      target_lang_name = lang[:name]

      # Filter exclusions
      strings_to_translate = @yaml_handler.filter_exclusions(source_strings, target_lang_code)

      return if strings_to_translate.empty?

      # Select strategy
      strategy = Strategies::StrategySelector.select(
        strings_to_translate.size,
        config,
        @provider,
        @progress_tracker
      )

      # Translate
      @progress_tracker.reset
      translated = strategy.translate(strings_to_translate, target_lang_code, target_lang_name)

      # Save
      output_path = @yaml_handler.build_output_path(target_lang_code)

      if config.translation_mode == :incremental
        final_translations = @yaml_handler.merge_translations(output_path, translated)
      else
        final_translations = Utils::HashFlattener.unflatten(translated)
      end

      # Wrap in language key (e.g., "it:")
      wrapped = { target_lang_code => final_translations }
      @yaml_handler.write_yaml(output_path, wrapped)

      @progress_tracker.complete(target_lang_name, translated.size)
    end
  end
end
```

### 5.8 `lib/better_translate/diff_preview.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  # Displays colored diff preview of translation changes
  #
  # Shows what will be added, modified, or removed before writing files.
  # Works in conjunction with config.dry_run mode.
  #
  # @example
  #   preview = DiffPreview.new(config)
  #   preview.show_diff(existing_data, new_data, output_path)
  #   # Output:
  #   # === config/locales/it.yml ===
  #   # + welcome: "Benvenuto"
  #   # ~ greeting: "Ciao" (was: "Salve")
  #   # - old_key: "Vecchio valore"
  #
  class DiffPreview
    # @return [Configuration] Configuration object
    attr_reader :config

    # Initialize diff preview
    #
    # @param config [Configuration] Configuration object
    def initialize(config)
      @config = config
    end

    # Show diff between existing and new data
    #
    # @param existing_data [Hash] Existing YAML data (nested)
    # @param new_data [Hash] New YAML data (nested)
    # @param output_path [String] Output file path
    # @return [Hash] Summary with counts
    def show_diff(existing_data, new_data, output_path)
      return { added: 0, modified: 0, removed: 0 } unless config.dry_run

      existing_flat = Utils::HashFlattener.flatten(existing_data)
      new_flat = Utils::HashFlattener.flatten(new_data)

      changes = calculate_changes(existing_flat, new_flat)

      display_diff(output_path, changes)

      {
        added: changes[:added].size,
        modified: changes[:modified].size,
        removed: changes[:removed].size
      }
    end

    # Show summary for all language files
    #
    # @param summaries [Array<Hash>] Array of summary hashes with :file, :added, :modified, :removed
    # @return [void]
    def show_summary(summaries)
      return unless config.dry_run

      puts "\n" + colorize("=" * 60, :cyan)
      puts colorize("DRY RUN SUMMARY", :cyan)
      puts colorize("=" * 60, :cyan)

      total_added = 0
      total_modified = 0
      total_removed = 0

      summaries.each do |summary|
        total_added += summary[:added]
        total_modified += summary[:modified]
        total_removed += summary[:removed]

        puts "\n#{summary[:file]}:"
        puts "  #{colorize('+', :green)} #{summary[:added]} added"
        puts "  #{colorize('~', :yellow)} #{summary[:modified]} modified"
        puts "  #{colorize('-', :red)} #{summary[:removed]} removed"
      end

      puts "\n" + colorize("-" * 60, :cyan)
      puts "Total: #{colorize("+#{total_added}", :green)} | " \
           "#{colorize("~#{total_modified}", :yellow)} | " \
           "#{colorize("-#{total_removed}", :red)}"
      puts colorize("=" * 60, :cyan)
      puts "\n#{colorize('ℹ', :cyan)} No files were modified (dry run mode)"
    end

    private

    # Calculate changes between existing and new data
    #
    # @param existing [Hash] Existing flattened data
    # @param new_data [Hash] New flattened data
    # @return [Hash] Changes with :added, :modified, :removed keys
    def calculate_changes(existing, new_data)
      added = []
      modified = []
      removed = []

      # Find added and modified keys
      new_data.each do |key, new_value|
        if existing.key?(key)
          if existing[key] != new_value
            modified << { key: key, old_value: existing[key], new_value: new_value }
          end
        else
          added << { key: key, value: new_value }
        end
      end

      # Find removed keys
      existing.each_key do |key|
        removed << { key: key, value: existing[key] } unless new_data.key?(key)
      end

      { added: added, modified: modified, removed: removed }
    end

    # Display diff with colored output
    #
    # @param file_path [String] Output file path
    # @param changes [Hash] Changes hash
    # @return [void]
    def display_diff(file_path, changes)
      puts "\n" + colorize("=" * 60, :cyan)
      puts colorize("#{file_path}", :cyan)
      puts colorize("=" * 60, :cyan)

      # Show added keys
      changes[:added].each do |item|
        puts colorize("+ #{item[:key]}: #{format_value(item[:value])}", :green)
      end

      # Show modified keys
      changes[:modified].each do |item|
        puts colorize("~ #{item[:key]}: #{format_value(item[:new_value])}", :yellow)
        puts colorize("  (was: #{format_value(item[:old_value])})", :yellow)
      end

      # Show removed keys
      changes[:removed].each do |item|
        puts colorize("- #{item[:key]}: #{format_value(item[:value])}", :red)
      end

      # Show counts
      puts colorize("-" * 60, :cyan)
      puts "#{colorize('+', :green)} #{changes[:added].size} | " \
           "#{colorize('~', :yellow)} #{changes[:modified].size} | " \
           "#{colorize('-', :red)} #{changes[:removed].size}"
    end

    # Format value for display (truncate long strings)
    #
    # @param value [String] Value to format
    # @return [String] Formatted value
    def format_value(value)
      max_length = 60
      return value.inspect if value.length <= max_length

      "#{value[0...(max_length - 3)].inspect}..."
    end

    # Colorize text for terminal output
    #
    # @param text [String] Text to colorize
    # @param color [Symbol] Color name (:red, :green, :yellow, :cyan)
    # @return [String] Colorized text
    def colorize(text, color)
      return text unless $stdout.tty?

      colors = {
        red: "\e[31m",
        green: "\e[32m",
        yellow: "\e[33m",
        cyan: "\e[36m",
        reset: "\e[0m"
      }

      "#{colors[color]}#{text}#{colors[:reset]}"
    end
  end
end
```

### 5.9 Update `YAMLHandler` to integrate DiffPreview

Update the `write_yaml` method in `lib/better_translate/yaml_handler.rb`:

```ruby
# Write hash to YAML file with optional diff preview
#
# @param file_path [String] Output file path
# @param data [Hash] Data to write
# @param diff_preview [DiffPreview, nil] Optional diff preview instance
# @return [Hash, nil] Summary hash if dry_run, nil otherwise
# @raise [FileError] if file cannot be written
def write_yaml(file_path, data, diff_preview: nil)
  summary = nil

  # Show diff preview if in dry run mode
  if config.dry_run && diff_preview
    existing_data = File.exist?(file_path) ? read_yaml(file_path) : {}
    summary = diff_preview.show_diff(existing_data, data, file_path)
  end

  return summary if config.dry_run

  # Ensure output directory exists
  FileUtils.mkdir_p(File.dirname(file_path))

  File.write(file_path, YAML.dump(data))

  nil
rescue Errno::EACCES => e
  raise FileError.new("Permission denied: #{file_path}", context: { error: e.message })
rescue StandardError => e
  raise FileError.new("Failed to write YAML: #{file_path}", context: { error: e.message })
end
```

### 5.10 Update `Translator` to use DiffPreview

Update `lib/better_translate/translator.rb` to integrate the diff preview:

```ruby
# Initialize translator
#
# @param config [Configuration] Configuration object
def initialize(config)
  @config = config
  @config.validate!
  @provider = ProviderFactory.create(config.provider, config)
  @yaml_handler = YAMLHandler.new(config)
  @progress_tracker = ProgressTracker.new(enabled: config.verbose)
  @diff_preview = DiffPreview.new(config)
  @diff_summaries = []
end

# Translate to all target languages
#
# @return [Hash] Results hash with :success_count, :failure_count, :errors
def translate_all
  source_strings = @yaml_handler.get_source_strings

  results = {
    success_count: 0,
    failure_count: 0,
    errors: []
  }

  config.target_languages.each do |lang|
    begin
      summary = translate_language(source_strings, lang)
      @diff_summaries << summary if summary
      results[:success_count] += 1
    rescue StandardError => e
      results[:failure_count] += 1
      results[:errors] << {
        language: lang[:name],
        error: e.message,
        context: e.respond_to?(:context) ? e.context : {}
      }
      @progress_tracker.error(lang[:name], e)
    end
  end

  # Show summary if dry run
  @diff_preview.show_summary(@diff_summaries) if config.dry_run

  results
end

private

def translate_language(source_strings, lang)
  target_lang_code = lang[:short_name]
  target_lang_name = lang[:name]

  # Filter exclusions
  strings_to_translate = @yaml_handler.filter_exclusions(source_strings, target_lang_code)

  return nil if strings_to_translate.empty?

  # Select strategy
  strategy = Strategies::StrategySelector.select(
    strings_to_translate.size,
    config,
    @provider,
    @progress_tracker
  )

  # Translate
  @progress_tracker.reset
  translated = strategy.translate(strings_to_translate, target_lang_code, target_lang_name)

  # Save
  output_path = @yaml_handler.build_output_path(target_lang_code)

  if config.translation_mode == :incremental
    final_translations = @yaml_handler.merge_translations(output_path, translated)
  else
    final_translations = Utils::HashFlattener.unflatten(translated)
  end

  # Wrap in language key (e.g., "it:")
  wrapped = { target_lang_code => final_translations }

  # Write YAML with diff preview
  summary = @yaml_handler.write_yaml(output_path, wrapped, diff_preview: @diff_preview)

  @progress_tracker.complete(target_lang_name, translated.size)

  # Return summary for dry run
  if summary
    { file: output_path, **summary }
  else
    nil
  end
end
```

### 5.11 Test: `spec/better_translate/diff_preview_spec.rb`

```ruby
# frozen_string_literal: true

RSpec.describe BetterTranslate::DiffPreview do
  let(:config) do
    BetterTranslate::Configuration.new.tap do |c|
      c.dry_run = true
    end
  end

  subject(:diff_preview) { described_class.new(config) }

  describe "#show_diff" do
    context "when dry_run is enabled" do
      it "shows added keys" do
        existing = {}
        new_data = { "en" => { "welcome" => "Welcome" } }

        expect {
          diff_preview.show_diff(existing, new_data, "en.yml")
        }.to output(/\+ welcome: "Welcome"/).to_stdout
      end

      it "shows modified keys" do
        existing = { "en" => { "welcome" => "Hello" } }
        new_data = { "en" => { "welcome" => "Welcome" } }

        expect {
          diff_preview.show_diff(existing, new_data, "en.yml")
        }.to output(/~ welcome: "Welcome"/).to_stdout
      end

      it "shows removed keys" do
        existing = { "en" => { "old_key" => "Old value" } }
        new_data = { "en" => {} }

        expect {
          diff_preview.show_diff(existing, new_data, "en.yml")
        }.to output(/- old_key: "Old value"/).to_stdout
      end

      it "returns summary with counts" do
        existing = {
          "en" => {
            "old_key" => "Old",
            "modified" => "Original"
          }
        }
        new_data = {
          "en" => {
            "modified" => "Changed",
            "new_key" => "New"
          }
        }

        summary = diff_preview.show_diff(existing, new_data, "en.yml")

        expect(summary[:added]).to eq(1)
        expect(summary[:modified]).to eq(1)
        expect(summary[:removed]).to eq(1)
      end
    end

    context "when dry_run is disabled" do
      before { config.dry_run = false }

      it "returns zero counts" do
        existing = {}
        new_data = { "en" => { "welcome" => "Welcome" } }

        summary = diff_preview.show_diff(existing, new_data, "en.yml")

        expect(summary[:added]).to eq(0)
        expect(summary[:modified]).to eq(0)
        expect(summary[:removed]).to eq(0)
      end
    end
  end

  describe "#show_summary" do
    it "displays total summary for all files" do
      summaries = [
        { file: "it.yml", added: 5, modified: 2, removed: 1 },
        { file: "fr.yml", added: 3, modified: 1, removed: 0 }
      ]

      expect {
        diff_preview.show_summary(summaries)
      }.to output(/Total: \+8 \| ~3 \| -1/).to_stdout
    end

    it "shows no files were modified message" do
      summaries = [
        { file: "it.yml", added: 5, modified: 0, removed: 0 }
      ]

      expect {
        diff_preview.show_summary(summaries)
      }.to output(/No files were modified \(dry run mode\)/).to_stdout
    end
  end

  describe "#calculate_changes" do
    it "identifies all types of changes" do
      existing = {
        "keep" => "Same",
        "modify" => "Old",
        "remove" => "Gone"
      }
      new_data = {
        "keep" => "Same",
        "modify" => "New",
        "add" => "Fresh"
      }

      changes = diff_preview.send(:calculate_changes, existing, new_data)

      expect(changes[:added].size).to eq(1)
      expect(changes[:modified].size).to eq(1)
      expect(changes[:removed].size).to eq(1)
    end
  end
end
```

---

## Configuration Option

Add to `lib/better_translate/configuration.rb`:

```ruby
# @return [Boolean] Dry run mode - show diff preview without writing files (default: false)
attr_accessor :dry_run

# In initialize method:
@dry_run = false
```

---

## Usage Examples

### Example 1: Enable Dry Run Mode

```ruby
BetterTranslate.configure do |config|
  config.dry_run = true
  config.input_file = "config/locales/en.yml"
  config.target_languages = [
    { short_name: "it", name: "Italian" },
    { short_name: "fr", name: "French" }
  ]
end

BetterTranslate.translate_all
# Output:
# ============================================================
# config/locales/it.yml
# ============================================================
# + welcome: "Benvenuto"
# + greeting: "Ciao"
# ~ goodbye: "Arrivederci" (was: "Addio")
# - old_message: "Vecchio messaggio"
# ------------------------------------------------------------
# + 2 | ~ 1 | - 1
#
# [Repeat for fr.yml...]
#
# ============================================================
# DRY RUN SUMMARY
# ============================================================
# config/locales/it.yml:
#   + 2 added
#   ~ 1 modified
#   - 1 removed
#
# config/locales/fr.yml:
#   + 3 added
#   ~ 0 modified
#   - 0 removed
#
# ------------------------------------------------------------
# Total: +5 | ~1 | -1
# ============================================================
# ℹ No files were modified (dry run mode)
```

### Example 2: CLI with Dry Run

```bash
# Using the standalone CLI
better_translate translate config/locales/en.yml --to it,fr --dry-run

# Shows colored diff preview without writing files
```

### Example 3: Programmatic Dry Run Check

```ruby
config = BetterTranslate::Configuration.new
config.dry_run = true
config.input_file = "en.yml"
config.target_languages = [{ short_name: "it", name: "Italian" }]

translator = BetterTranslate::Translator.new(config)
results = translator.translate_all

# In dry run mode, no files are written
# Results include success/failure counts but no actual file modifications
```

---

## Benefits

1. **Safety**: Preview changes before committing translations
2. **Clarity**: Color-coded diff shows exactly what will change
3. **Non-Destructive**: No files modified in dry-run mode
4. **Summary**: Clear overview of all changes across all language files
5. **CI/CD Integration**: Useful for validation in automated pipelines

---

## Implementation Checklist

- [ ] Create `lib/better_translate/diff_preview.rb`
- [ ] Update `YAMLHandler#write_yaml` to accept `diff_preview` parameter
- [ ] Update `Translator` to instantiate and use `DiffPreview`
- [ ] Add `dry_run` configuration option
- [ ] Create comprehensive test suite in `spec/better_translate/diff_preview_spec.rb`
- [ ] Update CLI to support `--dry-run` flag (Phase 12)
- [ ] Add YARD documentation for all methods
- [ ] Update README with dry-run examples

---

---

[← Previous: 04-Provider Architecture](./04-provider_architecture.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 06-Main Module Api →](./06-main_module_api.md)
