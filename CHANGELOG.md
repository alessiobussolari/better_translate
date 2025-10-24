# Changelog

All notable changes to BetterTranslate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2025-10-24

### Fixed
- **Initializer Configuration**: Updated template to use manual I18n configuration instead of `after_initialize` hook
  - Fixes loop/deadlock issues when running rake tasks
  - Adds clear documentation explaining I18n loading order
  - Provides example showing how to match Rails I18n config
  - Removes dependency on Rails initialization order

### Added
- **Automatic File Creation**: Input files are now created automatically if they don't exist
  - Creates directory structure automatically (mkdir -p)
  - Supports both YAML and JSON formats
  - Creates minimal valid file with root language key only
  - Shows message in verbose mode when file is created
  - Backward compatible: existing files are never modified

- **CSV Dependency**: Added explicit CSV dependency for Ruby 3.4.0 compatibility
  - Prevents deprecation warnings in Ruby 3.4.0+
  - Ensures gem works across all Ruby versions

### Changed
- **Initializer Priority**: Rake task now prioritizes initializer configuration over YAML config
  - Checks for existing initializer configuration first
  - Falls back to YAML config if no initializer found
  - Provides helpful error messages suggesting both configuration methods

## [1.1.0] - 2025-10-22

### Added

#### Enhanced Configuration
- **Provider-Specific Options**: Fine-tune AI provider behavior
  - `model`: Specify which AI model to use (e.g., "gpt-5-nano", "gemini-2.0-flash-exp")
  - `temperature`: Control creativity/randomness (0.0-2.0, default: 0.3)
  - `max_tokens`: Limit response length (default: 2000)
  - Configurable via CLI, configuration file, or programmatically

#### Automatic Backups
- **Backup System**: Automatic backup creation before overwriting translation files
  - `create_backup`: Enable/disable automatic backups (default: true)
  - `max_backups`: Keep up to N backup files with rotation (default: 3)
  - Backup format: `.bak`, `.bak.1`, `.bak.2`, etc.
  - Automatic cleanup of old backups beyond `max_backups`
  - Works with both YAML and JSON files

#### JSON File Support
- **JSON Handler**: Complete support for JSON translation files
  - Read and write JSON locale files
  - Automatic format detection based on file extension (.json vs .yml)
  - Same feature set as YAML (incremental mode, backups, exclusions)
  - Pretty-printed output with proper indentation
  - Compatible with modern JavaScript frameworks (React, Vue, etc.)

#### Parallel Translation
- **Concurrent Processing**: Translate multiple languages simultaneously
  - `max_concurrent_requests`: Control concurrency level (default: 3)
  - Thread-based parallel execution for improved performance
  - Automatic fallback to sequential processing when `max_concurrent_requests = 1`
  - Thread-safe error handling
  - Significant time savings for projects with many target languages

#### Multiple Files Support
- **Batch Translation**: Translate multiple files in a single run
  - `input_files`: Accept array of file paths or glob patterns
  - Glob pattern support: `config/locales/**/*.en.yml`
  - Preserves directory structure in output
  - Smart filename handling: `common.en.yml` → `common.it.yml`
  - Works with both YAML and JSON files
  - Backward compatible with single `input_file` attribute

### Examples

#### Provider-Specific Options
```ruby
config.model = "gpt-5-nano"           # Use specific model
config.temperature = 0.7              # More creative translations
config.max_tokens = 1500              # Limit response length
```

#### Automatic Backups
```ruby
config.create_backup = true           # Enable backups (default)
config.max_backups = 5                # Keep up to 5 backup versions
```

#### JSON Support
```ruby
config.input_file = "config/locales/en.json"
config.output_folder = "config/locales"
# Automatically detects JSON format and uses JsonHandler
```

#### Parallel Translation
```ruby
config.target_languages = [
  { short_name: "it", name: "Italian" },
  { short_name: "fr", name: "French" },
  { short_name: "es", name: "Spanish" }
]
config.max_concurrent_requests = 3   # Translate 3 languages at once
```

#### Multiple Files
```ruby
# Array of specific files
config.input_files = [
  "config/locales/common.en.yml",
  "config/locales/errors.en.yml"
]

# Or use glob patterns
config.input_files = "config/locales/**/*.en.yml"
```

## [1.0.0] - 2025-10-22

### Complete Rewrite 🎉

This version represents a complete architectural rewrite of BetterTranslate with improved design, better testing, and enhanced features.

**Note:** This release is not backward compatible with versions 0.x.x

### Added

#### Core Infrastructure
- **Configuration System**: Type-safe configuration with comprehensive validation
  - Support for multiple providers (ChatGPT, Gemini, Anthropic)
  - Configurable timeouts, retries, and concurrency
  - Translation modes: override and incremental
  - Optional translation context for domain-specific terminology

- **LRU Cache**: Intelligent caching system for improved performance
  - Configurable capacity (default: 1000 items)
  - Optional TTL (Time To Live) support
  - Thread-safe with Mutex protection
  - Cache key format: `"#{text}:#{target_lang_code}"`

- **Rate Limiter**: Thread-safe request throttling
  - Configurable delay between requests (default: 0.5s)
  - Prevents API overload and rate limit errors
  - Mutex-based synchronization

- **Validator**: Comprehensive input validation
  - Language code validation (2-letter ISO codes)
  - Text validation for translation
  - File path validation
  - API key validation

- **Error Handling**: Custom exception hierarchy
  - `ConfigurationError`: Configuration issues
  - `ValidationError`: Input validation failures
  - `TranslationError`: Translation failures
  - `ProviderError`: Provider-specific errors
  - `ApiError`: API call failures
  - `RateLimitError`: Rate limit exceeded
  - `FileError`: File operation failures
  - `YamlError`: YAML parsing errors
  - `ProviderNotFoundError`: Unknown provider

#### Provider Architecture
- **BaseHttpProvider**: Abstract base class for HTTP-based providers
  - Faraday-based HTTP client (required for all providers)
  - Retry logic with exponential backoff (3 attempts, 2s base delay, 60s max)
  - Built-in rate limiting (0.5s between requests)
  - Configurable timeouts (default: 30s)

- **ChatGPT Provider**: OpenAI GPT integration
  - Model: GPT-5-nano
  - Temperature: 1.0

- **Gemini Provider**: Google Gemini integration
  - Model: gemini-2.0-flash-exp

- **Anthropic Provider**: Claude integration (planned)
  - Model: claude-3-5-sonnet-20241022

#### Translation Features
- **Translation Strategies**: Automatic strategy selection based on content size
  - Deep Translation (< 50 strings): Individual translation with detailed progress
  - Batch Translation (≥ 50 strings): Processes in batches of 10 for performance

- **Exclusion System**: Two-tier exclusion mechanism
  - Global exclusions: Apply to all target languages (e.g., brand names)
  - Language-specific exclusions: Exclude keys only for specific languages

- **Translation Modes**:
  - Override mode: Replaces entire target YAML files
  - Incremental mode: Merges with existing files, only translates missing keys

- **Translation Context**: Domain-specific context for improved accuracy
  - Medical terminology
  - Legal terminology
  - Financial terminology
  - E-commerce
  - Technical documentation

#### Rails Integration
- **Install Generator**: `rails generate better_translate:install`
  - Creates initializer with example configuration
  - Configures all supported providers

- **Translate Generator**: `rails generate better_translate:translate`
  - Runs translation process
  - Displays progress messages
  - Integrates with existing configuration

- **Analyze Generator**: `rails generate better_translate:analyze`
  - Analyzes translation similarities using Levenshtein distance
  - Generates detailed JSON reports
  - Provides human-readable summaries
  - Configurable similarity threshold

#### Utilities
- **HashFlattener**: Converts nested YAML to flat structure and vice versa
  - Flatten with dot-notation keys
  - Unflatten back to nested structure
  - Preserves data types and structure

### Development
- **YARD Documentation**: Comprehensive documentation for all public APIs
  - `@param` with types
  - `@return` with types
  - `@raise` for exceptions
  - `@example` blocks

- **RSpec Test Suite**: Full test coverage for core components
  - Configuration tests
  - Cache tests
  - Rate limiter tests
  - Validator tests
  - Error handling tests
  - Hash flattener tests

- **RuboCop**: Code style compliance
  - Ruby 3.0+ target
  - Frozen string literals required
  - Double quotes for strings

### Security
- Environment variable-based API key management
- No hardcoded credentials
- Input validation for all user-provided data
- VCR cassettes with automatic API key anonymization

### Performance
- LRU caching reduces API costs
- Batch processing for large files (≥50 strings)
- Configurable concurrent requests (default: 3)
- Rate limiting prevents API overload
