# 08 - Rails Integration

[← Previous: 07-Direct Translation Helpers](./07-direct_translation_helpers.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 09-Testing Suite →](./09-testing_suite.md)

---

## Rails Integration

### 7.1 `lib/generators/better_translate/install/install_generator.rb`

```ruby
# frozen_string_literal: true

require "rails/generators/base"

module BetterTranslate
  module Generators
    # Generator to install BetterTranslate in a Rails application
    #
    # Creates an initializer file with example configuration.
    #
    # @example
    #   rails generate better_translate:install
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a BetterTranslate initializer file"

      # Create initializer file
      #
      # @return [void]
      def create_initializer_file
        template "initializer.rb.tt", "config/initializers/better_translate.rb"
      end

      # Display post-install message
      #
      # @return [void]
      def show_readme
        readme "INSTALL" if behavior == :invoke
      end

      private

      def readme(file)
        say "\n" + "=" * 80
        say "BetterTranslate installed successfully!"
        say "=" * 80
        say "\nNext steps:"
        say "1. Edit config/initializers/better_translate.rb with your settings"
        say "2. Set your API keys in environment variables:"
        say "   - OPENAI_API_KEY (for ChatGPT)"
        say "   - GEMINI_API_KEY (for Google Gemini)"
        say "   - ANTHROPIC_API_KEY (for Anthropic Claude)"
        say "3. Run: rails generate better_translate:translate"
        say "\n" + "=" * 80 + "\n"
      end
    end
  end
end
```

### 7.2 `lib/generators/better_translate/install/templates/initializer.rb.tt`

```ruby
# frozen_string_literal: true

# BetterTranslate Configuration
#
# For more information, see: https://github.com/alessiobussolari/better_translate

BetterTranslate.configure do |config|
  # ==============================
  # REQUIRED SETTINGS
  # ==============================

  # Provider: :chatgpt, :gemini, or :anthropic
  config.provider = :chatgpt

  # API Keys (use environment variables for security)
  config.openai_key = ENV["OPENAI_API_KEY"]           # For ChatGPT
  # config.google_gemini_key = ENV["GEMINI_API_KEY"]  # For Gemini
  # config.anthropic_key = ENV["ANTHROPIC_API_KEY"]   # For Anthropic

  # Source language code (2 letters)
  config.source_language = "en"

  # Target languages
  config.target_languages = [
    { short_name: "it", name: "Italian" },
    { short_name: "fr", name: "French" },
    { short_name: "de", name: "German" },
    { short_name: "es", name: "Spanish" }
  ]

  # File paths
  config.input_file = Rails.root.join("config", "locales", "en.yml").to_s
  config.output_folder = Rails.root.join("config", "locales").to_s

  # ==============================
  # OPTIONAL SETTINGS
  # ==============================

  # Translation mode: :override or :incremental
  # - :override replaces entire files
  # - :incremental only translates missing keys
  config.translation_mode = :override

  # Domain-specific context for better translations
  # config.translation_context = "E-commerce product descriptions and checkout flow"

  # Caching
  config.cache_enabled = true
  config.cache_size = 1000
  # config.cache_ttl = 3600  # Seconds (nil = no expiration)

  # Performance
  config.max_concurrent_requests = 3
  config.request_timeout = 30
  config.max_retries = 3
  config.retry_delay = 2.0

  # Logging
  config.verbose = true

  # Dry run (don't write files, just test)
  # config.dry_run = false

  # Exclusions (keys to never translate)
  # config.global_exclusions = ["app.name", "brand.logo_url"]
  # config.exclusions_per_language = {
  #   "fr" => ["legal.disclaimer"],
  #   "de" => ["privacy.gdpr_text"]
  # }
end
```

### 7.3 `lib/generators/better_translate/translate/translate_generator.rb`

```ruby
# frozen_string_literal: true

require "rails/generators/base"

module BetterTranslate
  module Generators
    # Generator to run BetterTranslate translation
    #
    # Triggers the translation process using the current configuration.
    #
    # @example
    #   rails generate better_translate:translate
    class TranslateGenerator < Rails::Generators::Base
      desc "Run BetterTranslate translation"

      # Run translation
      #
      # @return [void]
      def run_translation
        say "Starting translation process...", :green

        begin
          results = BetterTranslate.translate_all

          say "\n" + "=" * 80, :green
          say "Translation completed!", :green
          say "=" * 80, :green
          say "✓ Successful: #{results[:success_count]} languages", :green
          say "✗ Failed: #{results[:failure_count]} languages", :red if results[:failure_count] > 0

          if results[:errors].any?
            say "\nErrors:", :red
            results[:errors].each do |error|
              say "  - #{error[:language]}: #{error[:error]}", :red
            end
          end

          say "=" * 80 + "\n", :green

        rescue BetterTranslate::ConfigurationError => e
          say "Configuration error: #{e.message}", :red
          say "\nPlease check config/initializers/better_translate.rb", :yellow
          exit 1
        rescue StandardError => e
          say "Unexpected error: #{e.message}", :red
          say e.backtrace.join("\n"), :red
          exit 1
        end
      end
    end
  end
end
```

### 7.4 `lib/generators/better_translate/analyze/analyze_generator.rb`

```ruby
# frozen_string_literal: true

require "rails/generators/base"

module BetterTranslate
  module Generators
    # Generator to analyze translation similarities
    #
    # Uses Levenshtein distance to detect potential translation issues.
    #
    # @example
    #   rails generate better_translate:analyze
    class AnalyzeGenerator < Rails::Generators::Base
      desc "Analyze translation similarities using Levenshtein distance"

      # Run analysis
      #
      # @return [void]
      def run_analysis
        say "Analyzing translations...", :cyan

        config = BetterTranslate.configuration
        raise "BetterTranslate not configured" unless config

        yaml_handler = YAMLHandler.new(config)
        source_strings = yaml_handler.get_source_strings

        results = []

        config.target_languages.each do |lang|
          target_path = yaml_handler.build_output_path(lang[:short_name])
          next unless File.exist?(target_path)

          target_data = yaml_handler.read_yaml(target_path)
          target_strings = Utils::HashFlattener.flatten(target_data[lang[:short_name]] || target_data)

          source_strings.each do |key, source_value|
            target_value = target_strings[key]
            next unless target_value

            similarity = calculate_similarity(source_value, target_value)

            # Flag if too similar (might indicate untranslated text)
            if similarity > 0.8 && source_value.length > 10
              results << {
                language: lang[:name],
                key: key,
                source: source_value,
                target: target_value,
                similarity: (similarity * 100).round(1)
              }
            end
          end
        end

        display_results(results)
      end

      private

      # Calculate Levenshtein similarity (0.0 to 1.0)
      def calculate_similarity(str1, str2)
        return 1.0 if str1 == str2
        return 0.0 if str1.empty? || str2.empty?

        distance = levenshtein_distance(str1.downcase, str2.downcase)
        max_length = [str1.length, str2.length].max

        1.0 - (distance.to_f / max_length)
      end

      # Calculate Levenshtein distance
      def levenshtein_distance(str1, str2)
        matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

        (0..str1.length).each { |i| matrix[i][0] = i }
        (0..str2.length).each { |j| matrix[0][j] = j }

        (1..str1.length).each do |i|
          (1..str2.length).each do |j|
            cost = str1[i - 1] == str2[j - 1] ? 0 : 1
            matrix[i][j] = [
              matrix[i - 1][j] + 1,      # deletion
              matrix[i][j - 1] + 1,      # insertion
              matrix[i - 1][j - 1] + cost # substitution
            ].min
          end
        end

        matrix[str1.length][str2.length]
      end

      def display_results(results)
        if results.empty?
          say "\n✓ No suspicious translations found!", :green
          return
        end

        say "\n⚠ Found #{results.size} potentially untranslated strings:", :yellow
        say "=" * 80, :yellow

        results.each do |result|
          say "\nLanguage: #{result[:language]}", :cyan
          say "Key: #{result[:key]}", :white
          say "Source: #{result[:source]}", :white
          say "Target: #{result[:target]}", :white
          say "Similarity: #{result[:similarity]}%", :yellow
        end

        say "\n" + "=" * 80, :yellow
        say "\nNote: High similarity might indicate:", :white
        say "  - Untranslated text (e.g., brand names that shouldn't be translated)"
        say "  - Proper nouns or technical terms"
        say "  - Translation errors"
        say "\nReview these translations and add to exclusions if needed.", :white
      end
    end
  end
end
```

---

---

[← Previous: 07-Direct Translation Helpers](./07-direct_translation_helpers.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 09-Testing Suite →](./09-testing_suite.md)
