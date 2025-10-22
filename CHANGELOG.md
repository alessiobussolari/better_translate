# Changelog

All notable changes to BetterTranslate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
