# 🌍 BetterTranslate

> AI-powered YAML locale file translator for Rails and Ruby projects

[![CI](https://github.com/alessiobussolari/better_translate/actions/workflows/main.yml/badge.svg)](https://github.com/alessiobussolari/better_translate/actions/workflows/main.yml)
[![codecov](https://codecov.io/gh/alessiobussolari/better_translate/branch/main/graph/badge.svg)](https://codecov.io/gh/alessiobussolari/better_translate)
[![Gem Version](https://badge.fury.io/rb/better_translate.svg)](https://badge.fury.io/rb/better_translate)
[![Downloads](https://img.shields.io/gem/dt/better_translate)](https://rubygems.org/gems/better_translate)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.0.0-ruby.svg)](https://www.ruby-lang.org/en/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![Security](https://img.shields.io/badge/security-brakeman-green)](https://brakemanscanner.org/)
[![Type Check](https://img.shields.io/badge/types-steep-blue)](https://github.com/soutaro/steep)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/alessiobussolari/better_translate/graphs/commit-activity)

BetterTranslate automatically translates your YAML locale files using cutting-edge AI providers (ChatGPT, Google Gemini, and Anthropic Claude). It's designed for Rails applications but works with any Ruby project that uses YAML-based internationalization.

**🎯 Why BetterTranslate?**
- ✅ **Production-Ready**: Tested with real APIs via VCR cassettes (18 cassettes, 260KB)
- ✅ **Interactive Demo**: Try it in 2 minutes with `ruby spec/dummy/demo_translation.rb`
- ✅ **Variable Preservation**: `%{name}` placeholders maintained in translations
- ✅ **Nested YAML Support**: Complex structures preserved perfectly
- ✅ **Multiple Providers**: Choose ChatGPT, Gemini, or Claude

| Provider | Model | Speed | Quality | Cost |
|----------|-------|-------|---------|------|
| **ChatGPT** | GPT-5-nano | ⚡⚡⚡ Fast | ⭐⭐⭐⭐⭐ Excellent | 💰💰 Medium |
| **Gemini** | gemini-2.0-flash-exp | ⚡⚡⚡⚡ Very Fast | ⭐⭐⭐⭐ Very Good | 💰 Low |
| **Claude** | Claude 3.5 | ⚡⚡ Medium | ⭐⭐⭐⭐⭐ Excellent | 💰💰💰 High |

## ✨ Features

### Core Translation Features
- 🤖 **Multiple AI Providers**: Support for ChatGPT (GPT-5-nano), Google Gemini (gemini-2.0-flash-exp), and Anthropic Claude
- ⚡ **Intelligent Caching**: LRU cache with optional TTL reduces API costs and speeds up repeated translations
- 🔄 **Translation Modes**: Choose between override (replace entire files) or incremental (merge with existing translations)
- 🎯 **Smart Strategies**: Automatic selection between deep translation (< 50 strings) and batch translation (≥ 50 strings)
- 🚫 **Flexible Exclusions**: Global exclusions for all languages + language-specific exclusions for fine-grained control
- 🎨 **Translation Context**: Provide domain-specific context for medical, legal, financial, or technical terminology
- 📊 **Similarity Analysis**: Built-in Levenshtein distance analyzer to identify similar translations
- 🔍 **Orphan Key Analyzer**: Find unused translation keys in your codebase with comprehensive reports (text, JSON, CSV)

### New in v1.1.0 🎉
- 🎛️ **Provider-Specific Options**: Fine-tune AI behavior with `model`, `temperature`, and `max_tokens`
- 💾 **Automatic Backups**: Configurable backup rotation before overwriting files (`.bak`, `.bak.1`, `.bak.2`)
- 📦 **JSON Support**: Full support for JSON locale files (React, Vue, modern JS frameworks)
- ⚡ **Parallel Translation**: Translate multiple languages concurrently with thread-based execution
- 📁 **Multiple Files**: Translate multiple files with arrays or glob patterns (`**/*.en.yml`)

### Development & Quality
- 🧪 **Comprehensive Testing**: Unit tests + integration tests with VCR cassettes (18 cassettes, 260KB)
- 🎬 **Rails Dummy App**: Interactive demo with real translations (`ruby spec/dummy/demo_translation.rb`)
- 🔒 **VCR Integration**: Record real API responses, test without API keys, CI/CD friendly
- 🛡️ **Type-Safe Configuration**: Comprehensive validation with detailed error messages
- 📚 **YARD Documentation**: Complete API documentation with examples
- 🔁 **Retry Logic**: Exponential backoff for failed API calls (3 attempts, configurable)
- 🚦 **Rate Limiting**: Thread-safe rate limiter prevents API overload

## 🚀 Quick Start

### Try It Now (Interactive Demo)

Clone the repo and run the demo to see BetterTranslate in action:

```bash
git clone https://github.com/alessiobussolari/better_translate.git
cd better_translate
bundle install

# Set your OpenAI API key
export OPENAI_API_KEY=your_key_here

# Run the demo!
ruby spec/dummy/demo_translation.rb
```

**What happens:**
- ✅ Reads `en.yml` with 16 translation keys
- ✅ Translates to Italian and French using ChatGPT
- ✅ Generates `it.yml` and `fr.yml` files
- ✅ Shows progress, results, and sample translations
- ✅ Takes ~2 minutes (real API calls)

**Sample Output:**
```yaml
# en.yml (input)
en:
  hello: "Hello"
  users:
    greeting: "Hello %{name}"

# it.yml (generated) ✅
it:
  hello: "Ciao"
  users:
    greeting: "Ciao %{name}"  # Variable preserved!

# fr.yml (generated) ✅
fr:
  hello: "Bonjour"
  users:
    greeting: "Bonjour %{name}"  # Variable preserved!
```

See [`spec/dummy/USAGE_GUIDE.md`](spec/dummy/USAGE_GUIDE.md) for more examples.

### Rails Integration

```ruby
# config/initializers/better_translate.rb
BetterTranslate.configure do |config|
  config.provider = :chatgpt
  config.openai_key = ENV["OPENAI_API_KEY"]

  config.source_language = "en"
  config.target_languages = [
    { short_name: "it", name: "Italian" },
    { short_name: "fr", name: "French" },
    { short_name: "es", name: "Spanish" }
  ]

  config.input_file = "config/locales/en.yml"
  config.output_folder = "config/locales"

  # Optional: Provide context for better translations
  config.translation_context = "E-commerce application with product catalog"
end

# Translate all files
BetterTranslate.translate_all
```

## 📦 Installation

Add this line to your application's Gemfile:

```ruby
gem "better_translate"
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install better_translate
```

### Rails Integration

For Rails applications, generate the initializer:

```bash
rails generate better_translate:install
```

This creates `config/initializers/better_translate.rb` with example configuration for all supported providers.

## ⚙️ Configuration

### Provider Setup

#### ChatGPT (OpenAI)

```ruby
BetterTranslate.configure do |config|
  config.provider = :chatgpt
  config.openai_key = ENV["OPENAI_API_KEY"]

  # Optional: customize model settings (defaults shown)
  config.request_timeout = 30      # seconds
  config.max_retries = 3
  config.retry_delay = 2.0         # seconds

  # 🆕 v1.1.0: Provider-specific options
  config.model = "gpt-5-nano"      # Specify model (optional)
  config.temperature = 0.3         # Creativity (0.0-2.0, default: 0.3)
  config.max_tokens = 2000         # Response length limit
end
```

Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys).

#### Google Gemini

```ruby
BetterTranslate.configure do |config|
  config.provider = :gemini
  config.google_gemini_key = ENV["GOOGLE_GEMINI_API_KEY"]

  # Same optional settings as ChatGPT
  config.request_timeout = 30
  config.max_retries = 3
end
```

Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey).

#### Anthropic Claude

```ruby
BetterTranslate.configure do |config|
  config.provider = :anthropic
  config.anthropic_key = ENV["ANTHROPIC_API_KEY"]

  # Same optional settings
  config.request_timeout = 30
  config.max_retries = 3
end
```

Get your API key from [Anthropic Console](https://console.anthropic.com/).

### New Features (v1.1.0)

#### Automatic Backups

Protect your translation files with automatic backup creation:

```ruby
config.create_backup = true    # Enable backups (default: true)
config.max_backups = 5          # Keep up to 5 backup versions
```

Backup files are created with rotation:
- First backup: `it.yml.bak`
- Second backup: `it.yml.bak.1`
- Third backup: `it.yml.bak.2`
- Older backups are automatically deleted

#### JSON File Support

Translate JSON locale files for modern JavaScript frameworks:

```ruby
# Automatically detects JSON format from file extension
config.input_file = "config/locales/en.json"
config.output_folder = "config/locales"

# All features work with JSON: backups, incremental mode, exclusions, etc.
```

Example JSON file:
```json
{
  "en": {
    "common": {
      "greeting": "Hello %{name}"
    }
  }
}
```

#### Parallel Translation

Translate multiple languages concurrently for faster processing:

```ruby
config.target_languages = [
  { short_name: "it", name: "Italian" },
  { short_name: "fr", name: "French" },
  { short_name: "es", name: "Spanish" },
  { short_name: "de", name: "German" }
]

config.max_concurrent_requests = 4  # Translate 4 languages at once
```

**Performance improvement:** With 4 languages and `max_concurrent_requests = 4`, translation time is reduced by ~75% compared to sequential processing.

#### Multiple Files Support

Translate multiple files in a single run:

```ruby
# Array of specific files
config.input_files = [
  "config/locales/common.en.yml",
  "config/locales/errors.en.yml",
  "config/locales/admin.en.yml"
]

# Or use glob patterns (recommended)
config.input_files = "config/locales/**/*.en.yml"

# Or combine both approaches
config.input_files = [
  "config/locales/**/*.en.yml",
  "app/javascript/translations/*.en.json"
]
```

Output files preserve the original structure:
- `common.en.yml` → `common.it.yml`
- `errors.en.yml` → `errors.it.yml`
- `admin/settings.en.yml` → `admin/settings.it.yml`

### Language Configuration

```ruby
config.source_language = "en"  # ISO 639-1 code (2 letters)

config.target_languages = [
  { short_name: "it", name: "Italian" },
  { short_name: "fr", name: "French" },
  { short_name: "de", name: "German" },
  { short_name: "es", name: "Spanish" },
  { short_name: "pt", name: "Portuguese" },
  { short_name: "ja", name: "Japanese" },
  { short_name: "zh", name: "Chinese" }
]
```

### File Paths

```ruby
config.input_file = "config/locales/en.yml"       # Source file
config.output_folder = "config/locales"            # Output directory
```

## 🎨 Features in Detail

### Translation Modes

#### Override Mode (Default)

Replaces the entire target file with fresh translations:

```ruby
config.translation_mode = :override  # default
```

**Use when:** Starting fresh or regenerating all translations.

#### Incremental Mode

Merges with existing translations, only translating missing keys:

```ruby
config.translation_mode = :incremental
```

**Use when:** Preserving manual corrections or adding new keys to existing translations.

### Caching System

The LRU (Least Recently Used) cache stores translations to reduce API costs:

```ruby
config.cache_enabled = true      # default: true
config.cache_size = 1000         # default: 1000 items
config.cache_ttl = 3600          # optional: 1 hour in seconds (nil = no expiration)
```

**Cache key format:** `"#{text}:#{target_lang_code}"`

**Benefits:**
- Reduces API costs for repeated translations
- Speeds up re-runs during development
- Thread-safe with Mutex protection

### Rate Limiting

Prevent API overload with built-in rate limiting:

```ruby
config.max_concurrent_requests = 3  # default: 3
```

The rate limiter enforces a 0.5-second delay between requests by default. This is handled automatically by the `BaseHttpProvider`.

### Exclusion System

#### Global Exclusions

Keys excluded from translation in **all** target languages (useful for brand names, product codes, etc.):

```ruby
config.global_exclusions = [
  "app.name",              # "MyApp" should never be translated
  "app.company",           # "ACME Inc." stays the same
  "product.sku"            # "SKU-12345" is language-agnostic
]
```

#### Language-Specific Exclusions

Keys excluded only for **specific** languages (useful for manually translated legal text, locale-specific content, etc.):

```ruby
config.exclusions_per_language = {
  "it" => ["legal.terms", "legal.privacy"],  # Italian legal text manually reviewed
  "de" => ["legal.terms", "legal.privacy"],  # German legal text manually reviewed
  "fr" => ["marketing.slogan"]               # French slogan crafted by marketing team
}
```

**Example:**
- `legal.terms` is translated for Spanish, Portuguese, etc.
- But excluded for Italian and German (already manually translated)

### Translation Context

Provide domain-specific context to improve translation accuracy:

```ruby
config.translation_context = "Medical terminology for healthcare applications"
```

This context is included in the AI system prompt, helping with specialized terminology in fields like:

- 🏥 **Medical/Healthcare**: "patient", "diagnosis", "treatment"
- ⚖️ **Legal**: "plaintiff", "defendant", "liability"
- 💰 **Financial**: "dividend", "amortization", "escrow"
- 🛒 **E-commerce**: "checkout", "cart", "inventory"
- 🔧 **Technical**: "API", "endpoint", "authentication"

### Translation Strategies

BetterTranslate automatically selects the optimal strategy based on content size:

#### Deep Translation (< 50 strings)
- Translates each string individually
- Detailed progress tracking
- Best for small to medium files

#### Batch Translation (≥ 50 strings)
- Processes in batches of 10 strings
- Faster for large files
- Reduced API overhead

**You don't need to configure this** - it's automatic! 🎯

## 🔧 Rails Integration

BetterTranslate provides three Rails generators:

### 1. Install Generator

Generate the initializer with example configuration:

```bash
rails generate better_translate:install
```

Creates: `config/initializers/better_translate.rb`

### 2. Translate Generator

Run the translation process:

```bash
rails generate better_translate:translate
```

This triggers the translation based on your configuration and displays progress messages.

### 3. Analyze Generator

Analyze translation similarities using Levenshtein distance:

```bash
rails generate better_translate:analyze
```

**Output:**
- Console summary with similar translation pairs
- Detailed JSON report: `tmp/translation_similarity_report.json`
- Human-readable summary: `tmp/translation_similarity_summary.txt`

**Use cases:**
- Identify potential translation inconsistencies
- Find duplicate or near-duplicate translations
- Quality assurance for translation output

## 📝 Advanced Usage

### Programmatic Translation

#### Translate Multiple Texts to Multiple Languages

```ruby
texts = ["Hello", "Goodbye", "Thank you"]
target_langs = [
  { short_name: "it", name: "Italian" },
  { short_name: "fr", name: "French" }
]

results = BetterTranslate::TranslationHelper.translate_texts_to_languages(texts, target_langs)

# Results structure:
# {
#   "it" => ["Ciao", "Arrivederci", "Grazie"],
#   "fr" => ["Bonjour", "Au revoir", "Merci"]
# }
```

#### Translate Single Text to Multiple Languages

```ruby
text = "Welcome to our application"
target_langs = [
  { short_name: "it", name: "Italian" },
  { short_name: "es", name: "Spanish" }
]

results = BetterTranslate::TranslationHelper.translate_text_to_languages(text, target_langs)

# Results:
# {
#   "it" => "Benvenuto nella nostra applicazione",
#   "es" => "Bienvenido a nuestra aplicación"
# }
```

### Custom Configuration for Specific Tasks

```ruby
# Separate configuration for different domains
medical_config = BetterTranslate::Configuration.new
medical_config.provider = :chatgpt
medical_config.openai_key = ENV["OPENAI_API_KEY"]
medical_config.translation_context = "Medical terminology for patient records"
medical_config.validate!

# Use the custom config...
```

### Dry Run Mode

Test your configuration without writing files:

```ruby
config.dry_run = true
```

This validates everything and simulates the translation process without creating output files.

### Verbose Logging

Enable detailed logging for debugging:

```ruby
config.verbose = true
```

## 🔍 Orphan Key Analyzer

The Orphan Key Analyzer helps you find unused translation keys in your codebase. It scans your YAML locale files and compares them against your actual code usage, generating comprehensive reports.

### CLI Usage

Find orphan keys from the command line:

```bash
# Basic text report (default)
better_translate analyze \
  --source config/locales/en.yml \
  --scan-path app/

# JSON format (great for CI/CD)
better_translate analyze \
  --source config/locales/en.yml \
  --scan-path app/ \
  --format json

# CSV format (easy to share with team)
better_translate analyze \
  --source config/locales/en.yml \
  --scan-path app/ \
  --format csv

# Save to file
better_translate analyze \
  --source config/locales/en.yml \
  --scan-path app/ \
  --output orphan_report.txt
```

### Sample Output

**Text format:**
```
============================================================
Orphan Keys Analysis Report
============================================================

Statistics:
  Total keys: 50
  Used keys: 45
  Orphan keys: 5
  Usage: 90.0%

Orphan Keys (5):
------------------------------------------------------------

  Key: users.old_message
  Value: This feature was removed

  Key: products.deprecated_label
  Value: Old Label
...
============================================================
```

**JSON format:**
```json
{
  "orphans": ["users.old_message", "products.deprecated_label"],
  "orphan_details": {
    "users.old_message": "This feature was removed",
    "products.deprecated_label": "Old Label"
  },
  "orphan_count": 5,
  "total_keys": 50,
  "used_keys": 45,
  "usage_percentage": 90.0
}
```

### Programmatic Usage

Use the analyzer in your Ruby code:

```ruby
# Scan YAML file
key_scanner = BetterTranslate::Analyzer::KeyScanner.new("config/locales/en.yml")
all_keys = key_scanner.scan  # Returns Hash of all keys

# Scan code for used keys
code_scanner = BetterTranslate::Analyzer::CodeScanner.new("app/")
used_keys = code_scanner.scan  # Returns Set of used keys

# Detect orphans
detector = BetterTranslate::Analyzer::OrphanDetector.new(all_keys, used_keys)
orphans = detector.detect

# Get statistics
puts "Orphan count: #{detector.orphan_count}"
puts "Usage: #{detector.usage_percentage}%"

# Generate report
reporter = BetterTranslate::Analyzer::Reporter.new(
  orphans: orphans,
  orphan_details: detector.orphan_details,
  total_keys: all_keys.size,
  used_keys: used_keys.size,
  usage_percentage: detector.usage_percentage,
  format: :text
)

puts reporter.generate
reporter.save_to_file("orphan_report.txt")
```

### Supported Translation Patterns

The analyzer recognizes these i18n patterns:

- `t('key')` - Rails short form
- `t("key")` - Rails short form with double quotes
- `I18n.t(:key)` - Symbol syntax
- `I18n.t('key')` - String syntax
- `I18n.translate('key')` - Full method name
- `<%= t('key') %>` - ERB templates
- `I18n.t('key', param: value)` - With parameters

**Nested keys:**
```yaml
en:
  users:
    profile:
      title: "Profile"  # Detected as: users.profile.title
```

**Use cases:**
- Clean up unused translations before deployment
- Identify dead code after refactoring
- Reduce locale file size
- Improve translation maintenance
- Generate reports for translation teams

## 🧪 Development & Testing

BetterTranslate includes comprehensive testing infrastructure with **unit tests**, **integration tests**, and a **Rails dummy app** for realistic testing.

### Test Structure

```
spec/
├── better_translate/           # Unit tests (fast, no API calls)
│   ├── cache_spec.rb
│   ├── configuration_spec.rb
│   ├── providers/
│   │   ├── chatgpt_provider_spec.rb
│   │   └── gemini_provider_spec.rb
│   └── ...
│
├── integration/                # Integration tests (real API via VCR)
│   ├── chatgpt_integration_spec.rb
│   ├── gemini_integration_spec.rb
│   ├── rails_dummy_app_spec.rb
│   └── README.md
│
├── dummy/                      # Rails dummy app for testing
│   ├── config/
│   │   └── locales/
│   │       ├── en.yml         # Source file
│   │       ├── it.yml         # Generated translations
│   │       └── fr.yml
│   ├── demo_translation.rb    # Interactive demo script
│   └── USAGE_GUIDE.md
│
└── vcr_cassettes/              # Recorded API responses (18 cassettes, 260KB)
    ├── chatgpt/ (7)
    ├── gemini/ (7)
    └── rails/ (4)
```

### Running Tests

```bash
# Run all tests (unit + integration)
bundle exec rake spec
# or
bundle exec rspec

# Run only unit tests (fast, no API calls)
bundle exec rspec spec/better_translate/

# Run only integration tests (uses VCR cassettes)
bundle exec rspec spec/integration/

# Run specific test file
bundle exec rspec spec/better_translate/configuration_spec.rb

# Run tests with coverage
bundle exec rspec --format documentation
```

### VCR Cassettes & API Testing

BetterTranslate uses **VCR** (Video Cassette Recorder) to record real API interactions for integration tests. This allows:

✅ **Realistic testing** with actual provider responses
✅ **No API keys needed** after initial recording
✅ **Fast test execution** (no real API calls)
✅ **CI/CD friendly** (cassettes committed to repo)
✅ **API keys anonymized** (safe to commit)

#### Setup API Keys for Recording

```bash
# Copy environment template
cp .env.example .env

# Edit .env and add your API keys
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...
ANTHROPIC_API_KEY=sk-ant-...
```

#### Re-record Cassettes

```bash
# Delete and re-record all cassettes
rm -rf spec/vcr_cassettes/
bundle exec rspec spec/integration/

# Re-record specific provider
rm -rf spec/vcr_cassettes/chatgpt/
bundle exec rspec spec/integration/chatgpt_integration_spec.rb
```

**Note**: The `.env` file is gitignored. API keys in cassettes are automatically replaced with `<OPENAI_API_KEY>`, `<GEMINI_API_KEY>`, etc.

### Rails Dummy App Demo

Test BetterTranslate with a realistic Rails app:

```bash
# Run interactive demo
ruby spec/dummy/demo_translation.rb
```

**Output:**
```
🚀 Starting translation...
[BetterTranslate] Italian | hello | 6.3%
[BetterTranslate] Italian | world | 12.5%
...
✅ Success: 2 language(s)
✓ it.yml generated (519 bytes)
✓ fr.yml generated (511 bytes)
```

**Generated files:**
- `spec/dummy/config/locales/it.yml` - Italian translation
- `spec/dummy/config/locales/fr.yml` - French translation

See [`spec/dummy/USAGE_GUIDE.md`](spec/dummy/USAGE_GUIDE.md) for more examples.

### Code Quality

```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix violations
bundle exec rubocop -a

# Run both tests and linter
bundle exec rake
```

### Documentation

```bash
# Generate YARD documentation
bundle exec yard doc

# Start documentation server (http://localhost:8808)
bundle exec yard server

# Check documentation coverage
bundle exec yard stats
```

### Interactive Console

```bash
# Load the gem in an interactive console
bin/console
```

### Security Audit

```bash
# Check for security vulnerabilities
bundle exec bundler-audit check --update
```

## 🏗️ Architecture

### Provider Architecture

All providers inherit from `BaseHttpProvider`:

```
BaseHttpProvider (abstract)
├── ChatGPTProvider
├── GeminiProvider
└── AnthropicProvider
```

**BaseHttpProvider responsibilities:**
- HTTP communication via Faraday
- Retry logic with exponential backoff
- Rate limiting
- Timeout handling
- Error wrapping

### Core Components

- **Configuration**: Type-safe config with validation
- **Cache**: LRU cache with optional TTL
- **RateLimiter**: Thread-safe request throttling
- **Validator**: Input validation (language codes, text, paths, keys)
- **HashFlattener**: Converts nested YAML ↔ flat structure

### Error Hierarchy

All errors inherit from `BetterTranslate::Error`:

```
BetterTranslate::Error
├── ConfigurationError
├── ValidationError
├── TranslationError
├── ProviderError
├── ApiError
├── RateLimitError
├── FileError
├── YamlError
└── ProviderNotFoundError
```

## 📖 Documentation

- **[USAGE_GUIDE.md](spec/dummy/USAGE_GUIDE.md)** - Complete guide to dummy app and demos
- **[VCR Testing Guide](spec/integration/README.md)** - How to test with VCR cassettes
- **[CLAUDE.md](CLAUDE.md)** - Developer guide for AI assistants (Claude Code)
- **[YARD Docs](https://rubydoc.info/gems/better_translate)** - Complete API documentation

### Key Documentation Files

```
better_translate/
├── README.md                          # This file (main documentation)
├── CLAUDE.md                          # Development guide (commands, architecture)
├── spec/
│   ├── dummy/
│   │   ├── USAGE_GUIDE.md            # 📖 Interactive demo guide
│   │   └── demo_translation.rb       # 🚀 Runnable demo script
│   └── integration/
│       └── README.md                  # 🧪 VCR testing guide
└── docs/
    └── implementation/                # Design docs
```

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alessiobussolari/better_translate.

### Development Guidelines

1. **TDD (Test-Driven Development)**: Always write tests before implementing features
2. **YARD Documentation**: Document all public methods with `@param`, `@return`, `@raise`, and `@example`
3. **RuboCop Compliance**: Ensure code passes `bundle exec rubocop` before committing
4. **Frozen String Literals**: Include `# frozen_string_literal: true` at the top of all files
5. **HTTP Client**: Use Faraday for all HTTP requests (never Net::HTTP or HTTParty)
6. **VCR Cassettes**: Record integration tests with real API responses for CI/CD

### Development Workflow

```bash
# 1. Clone and setup
git clone https://github.com/alessiobussolari/better_translate.git
cd better_translate
bundle install

# 2. Create a feature branch
git checkout -b my-feature

# 3. Write tests first (TDD)
# Edit spec/better_translate/my_feature_spec.rb

# 4. Implement the feature
# Edit lib/better_translate/my_feature.rb

# 5. Ensure tests pass and code is clean
bundle exec rspec
bundle exec rubocop

# 6. Commit and push
git add .
git commit -m "Add my feature"
git push origin my-feature

# 7. Create a Pull Request
```

### Release Workflow

Releases are automated via GitHub Actions:

```bash
# 1. Update version
vim lib/better_translate/version.rb  # VERSION = "1.0.1"

# 2. Update CHANGELOG
vim CHANGELOG.md

# 3. Commit and tag
git add -A
git commit -m "chore: Release v1.0.1"
git tag v1.0.1
git push origin main
git push origin v1.0.1

# 4. GitHub Actions automatically:
#    ✅ Runs tests
#    ✅ Builds gem
#    ✅ Publishes to RubyGems.org
#    ✅ Creates GitHub Release
```

**Setup**: See [`.github/RUBYGEMS_SETUP.md`](.github/RUBYGEMS_SETUP.md) for configuring RubyGems trusted publishing (no API keys needed!).

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 📜 Code of Conduct

Everyone interacting in the BetterTranslate project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

---

<div align="center">

**Made with ❤️ by [Alessio Bussolari](https://github.com/alessiobussolari)**

[Report Bug](https://github.com/alessiobussolari/better_translate/issues) · [Request Feature](https://github.com/alessiobussolari/better_translate/issues) · [Documentation](https://github.com/alessiobussolari/better_translate)

</div>
