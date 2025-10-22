# 10 - Documentation & Examples

[← Previous: 09-Testing Suite](./09-testing_suite.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 11-Quality Security →](./11-quality_security.md)

---

## Documentation & Examples

### 9.1 Creare `examples/basic_usage.rb`

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "better_translate"

# Basic usage example
BetterTranslate.configure do |config|
  config.provider = :chatgpt
  config.openai_key = ENV["OPENAI_API_KEY"]
  config.source_language = "en"
  config.target_languages = [
    { short_name: "it", name: "Italian" },
    { short_name: "fr", name: "French" }
  ]
  config.input_file = "config/locales/en.yml"
  config.output_folder = "config/locales"
  config.verbose = true
end

puts "Starting translation..."
results = BetterTranslate.translate_all

puts "\n" + "=" * 80
puts "Translation Results:"
puts "  ✓ Success: #{results[:success_count]} languages"
puts "  ✗ Failed: #{results[:failure_count]} languages"

if results[:errors].any?
  puts "\nErrors:"
  results[:errors].each do |error|
    puts "  - #{error[:language]}: #{error[:error]}"
  end
end
puts "=" * 80
```

### 9.2 Creare `examples/advanced_usage.rb`

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "better_translate"

# Advanced usage with all options
BetterTranslate.configure do |config|
  # Provider selection
  config.provider = :anthropic
  config.anthropic_key = ENV["ANTHROPIC_API_KEY"]

  # Languages
  config.source_language = "en"
  config.target_languages = [
    { short_name: "it", name: "Italian" },
    { short_name: "fr", name: "French" },
    { short_name: "de", name: "German" },
    { short_name: "es", name: "Spanish" }
  ]

  # Files
  config.input_file = "config/locales/en.yml"
  config.output_folder = "config/locales"

  # Translation mode
  config.translation_mode = :incremental  # Preserve existing translations

  # Domain-specific context
  config.translation_context = "Medical terminology for healthcare applications"

  # Caching
  config.cache_enabled = true
  config.cache_size = 2000
  config.cache_ttl = 3600  # 1 hour

  # Performance tuning
  config.max_concurrent_requests = 5
  config.request_timeout = 60
  config.max_retries = 5
  config.retry_delay = 3.0

  # Logging
  config.verbose = true

  # Exclusions
  config.global_exclusions = ["app.name", "company.logo_url"]
  config.exclusions_per_language = {
    "fr" => ["legal.disclaimer"],  # French has custom legal text
    "de" => ["privacy.gdpr_text"]  # German GDPR text is manually translated
  }

  # Dry run (don't actually write files)
  # config.dry_run = true
end

puts "Advanced Translation Configuration"
puts "=" * 80
puts "Provider: #{BetterTranslate.configuration.provider}"
puts "Languages: #{BetterTranslate.configuration.target_languages.map { |l| l[:name] }.join(", ")}"
puts "Mode: #{BetterTranslate.configuration.translation_mode}"
puts "Cache: #{BetterTranslate.configuration.cache_enabled ? "enabled" : "disabled"}"
puts "=" * 80
puts "\nStarting translation...\n"

results = BetterTranslate.translate_all

puts "\n" + "=" * 80
puts "Translation Results:"
puts "  ✓ Success: #{results[:success_count]} languages"
puts "  ✗ Failed: #{results[:failure_count]} languages"

if results[:errors].any?
  puts "\nErrors:"
  results[:errors].each do |error|
    puts "  - #{error[:language]}: #{error[:error]}"
    puts "    Context: #{error[:context]}" if error[:context].any?
  end
end
puts "=" * 80
```

### 9.3 Aggiornare `README.md`

Il README dovrebbe includere:
- Installation instructions
- Quick start guide
- Configuration options
- Usage examples
- Rails integration
- Supported providers
- Contributing guidelines
- License

---

---

[← Previous: 09-Testing Suite](./09-testing_suite.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 11-Quality Security →](./11-quality_security.md)
