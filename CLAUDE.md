# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
```bash
# Run all tests (unit + integration)
bundle exec rake spec
# or
bundle exec rspec

# Run only unit tests (fast, no API calls)
bundle exec rspec spec/better_translate/

# Run only integration tests (with real API calls via VCR)
bundle exec rspec spec/integration/ --tag integration

# Run specific test file
bundle exec rspec spec/better_translate_spec.rb

# Run with specific example (line number)
bundle exec rspec spec/better_translate_spec.rb:42
```

### VCR Cassettes & API Testing

**Setup API Keys**:
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Edit `.env` and add your real API keys:
   ```env
   OPENAI_API_KEY=sk-...
   GEMINI_API_KEY=...
   ANTHROPIC_API_KEY=sk-ant-...
   ```
3. **IMPORTANT**: Never commit `.env` file (already in `.gitignore`)

**VCR Cassette Modes**:
- `:once` (default): Use existing cassettes, record new interactions
- `:new_episodes`: Record new interactions, keep existing ones
- `:all`: Re-record all cassettes (use when API changes)

**Re-recording Cassettes**:
```bash
# Delete existing cassettes and re-record with real API calls
rm -rf spec/vcr_cassettes/
bundle exec rspec spec/integration/ --tag integration

# Re-record specific provider
rm -rf spec/vcr_cassettes/chatgpt/
bundle exec rspec spec/integration/chatgpt_integration_spec.rb
```

**Cassette Location**: `spec/vcr_cassettes/`
- Cassettes are automatically anonymized (API keys replaced with placeholders)
- Cassettes should be committed to git for CI/CD pipelines
- Tests run without API keys when cassettes exist

### Code Quality
```bash
# Run RuboCop linter
bundle exec rake rubocop
# or
bundle exec rubocop

# Auto-fix RuboCop violations
bundle exec rubocop -a

# Run type checking with Steep
bundle exec rake steep
# or
bundle exec steep check

# Run default rake task (runs spec, rubocop, and steep)
bundle exec rake
```

### Documentation
```bash
# Generate YARD documentation
bundle exec yard doc

# Start YARD server (view docs at http://localhost:8808)
bundle exec yard server

# Check documentation coverage
bundle exec yard stats
```

### Security
```bash
# Check for security vulnerabilities in dependencies
bundle exec bundler-audit check --update
```

### Type Checking (RBS/Steep)
```bash
# Run type checking
bundle exec steep check

# Type check specific files
bundle exec steep check lib/better_translate/cache.rb

# Show statistics
bundle exec steep stats

# Validate RBS syntax only
bundle exec rbs validate
```

**RBS Files**: Type signatures are in `sig/` directory
- All public APIs have RBS signatures
- Steep is integrated in CI/CD pipeline
- Default rake task includes type checking

**Status**: 51 type errors remaining (down from 112 initial)
- Most errors are related to empty collection annotations
- All critical paths are type-checked
- Continuous improvement in progress

### Gem Management
```bash
# Install dependencies
bundle install

# Install gem locally for testing
bundle exec rake install

# Interactive console with gem loaded
bin/console
```

## Architecture Overview

### Provider-Based System
The gem uses a provider architecture to support multiple AI translation services:

- **BaseHttpProvider**: Abstract base class for all HTTP-based providers
  - Uses Faraday for all HTTP connections (REQUIRED - do not use Net::HTTP or other libraries)
  - Implements retry logic with exponential backoff (3 attempts, 2s base delay, 60s max)
  - Handles rate limiting (0.5s between requests, thread-safe with Mutex)
  - Configurable timeouts (default: 30s)

- **Providers**:
  - ChatGPT (OpenAI): GPT-5-nano model, temperature=1.0
  - Google Gemini: gemini-2.0-flash-exp model
  - Anthropic Claude: Planned support

### Translation Strategies
The gem automatically selects the optimal strategy based on content size:

- **Deep Translation** (< 50 strings): Individual translation with detailed progress
- **Batch Translation** (≥ 50 strings): Processes in batches of 10 for performance

### Configuration System
Type-safe `Configuration` class with mandatory validation:
- Required: provider, API keys, source language, target languages, file paths
- Optional: translation mode (override/incremental), context, caching, rate limiting
- Validation enforced via `config.validate!` before translation

### Caching System
LRU cache implementation:
- Default capacity: 1000 items (configurable)
- Cache key format: `"#{text}:#{target_lang_code}"`
- Optional TTL support
- Thread-safe with Mutex protection
- Toggleable via `cache_enabled` config

### Exclusion System
Two-tier exclusion mechanism:
- **Global exclusions**: Apply to all target languages (e.g., brand names)
- **Language-specific exclusions**: Exclude keys only for specific languages (e.g., legal text that was manually translated)

### Translation Modes
- **Override**: Replaces entire target YAML files
- **Incremental**: Merges with existing files, only translates missing keys

## Rails Integration

The gem provides three generators for Rails applications:

```bash
# Generate initializer with example configuration
rails generate better_translate:install

# Run translation process
rails generate better_translate:translate

# Analyze translation similarities (Levenshtein distance)
rails generate better_translate:analyze
```

Configuration is typically done in `config/initializers/better_translate.rb`.

## Development Requirements

### YARD Documentation (MANDATORY)
ALL public methods, classes, and modules must have comprehensive YARD documentation:

- Use `@param` for parameters with types (e.g., `@param text [String]`)
- Use `@return` for return values with types
- Use `@raise` for exceptions
- Provide `@example` blocks for public APIs
- Mark private methods with `@api private`

Example:
```ruby
# Translates text to a target language
#
# @param text [String] The text to translate
# @param target_lang_code [String] Language code (e.g., "it", "fr")
# @return [String] The translated text
# @raise [ValidationError] If input is invalid
# @raise [TranslationError] If translation fails
#
# @example
#   translate("Hello", "it") #=> "Ciao"
def translate(text, target_lang_code)
  # ...
end
```

### HTTP Client (MANDATORY)
- Use Faraday for ALL HTTP connections
- Do NOT use Net::HTTP, HTTParty, or other HTTP libraries
- Implement retry logic and error handling as shown in BaseHttpProvider

### Code Style
- RuboCop compliance required before commits
- String literals: Use double quotes (enforced by RuboCop)
- Target Ruby version: 3.0+
- Frozen string literals: Required at top of all files

### Security
- NEVER hardcode API keys in code
- Use environment variables: `ENV['OPENAI_API_KEY']`, `ENV['GEMINI_API_KEY']`
- VCR cassettes must anonymize API keys automatically
- Input validation required for all user-provided data (language codes, file paths, text)

## Error Handling

Custom exception hierarchy (all inherit from `BetterTranslate::Error`):
- `ConfigurationError`: Configuration issues
- `ValidationError`: Input validation failures
- `TranslationError`: Translation failures
- `ProviderError`: Provider-specific errors
- `ApiError`: API call failures
- `RateLimitError`: Rate limit exceeded
- `FileError`: File operation failures
- `YamlError`: YAML parsing errors
- `ProviderNotFoundError`: Unknown provider

All errors include detailed messages and context hash for debugging.

## Testing Practices

### Test-Driven Development (TDD) - MANDATORY
**ALWAYS write tests BEFORE implementing any new feature or bug fix.**

This is a strict requirement for all development in this project. Follow the Red-Green-Refactor cycle:

#### TDD Workflow (REQUIRED)
1. **RED**: Write failing tests first
   - Write RSpec tests that describe the desired behavior
   - Run tests and verify they fail: `bundle exec rspec`
   - Failing tests prove that the test is valid and catches the missing functionality

2. **GREEN**: Implement minimum code to pass tests
   - Write the simplest implementation that makes tests pass
   - Run tests again and verify they pass: `bundle exec rspec`
   - DO NOT add extra features beyond what tests require

3. **REFACTOR**: Clean up code while keeping tests green
   - Improve code quality, remove duplication
   - Run tests after each refactoring to ensure nothing breaks
   - Update documentation (YARD) as needed

#### Example TDD Workflow
```bash
# 1. RED - Write failing test
# Edit spec/providers/new_provider_spec.rb with test cases
bundle exec rspec spec/providers/new_provider_spec.rb
# => Should see failures (RED)

# 2. GREEN - Implement feature
# Edit lib/better_translate/providers/new_provider.rb
bundle exec rspec spec/providers/new_provider_spec.rb
# => Should see passing tests (GREEN)

# 3. REFACTOR - Improve code
# Refactor implementation while keeping tests green
bundle exec rspec spec/providers/new_provider_spec.rb
# => Should still see passing tests (GREEN)
```

#### Why TDD is Mandatory
- Ensures all code is testable by design
- Prevents regression bugs
- Provides living documentation of expected behavior
- Catches edge cases early
- Makes refactoring safer

#### Exceptions
The ONLY acceptable exception to writing tests first is for critical production hotfixes where immediate deployment is required. In such cases:
- Document the technical debt in code comments
- Create a GitHub issue to add tests
- Add tests within 24 hours of the hotfix

### RSpec Setup

**Test Organization**:
- `spec/better_translate/`: Unit tests with WebMock stubs (fast, no API calls)
- `spec/integration/`: Integration tests with VCR cassettes (real API interactions)

**Unit Tests** (WebMock):
- Fast execution, no API keys required
- Test code structure, request formatting, and error handling
- Use `stub_request` to mock HTTP responses
- Example: `spec/better_translate/providers/chatgpt_provider_spec.rb`

**Integration Tests** (VCR):
- Test real API interactions
- Require API keys in `.env` file for first run (to record cassettes)
- Subsequent runs use recorded cassettes (no API keys needed)
- Tag with `:integration` and `:vcr`
- Example: `spec/integration/chatgpt_integration_spec.rb`

**Running Tests**:
```bash
# Unit tests only (fast, recommended for TDD)
bundle exec rspec spec/better_translate/

# Integration tests only (slower, validates API compatibility)
bundle exec rspec spec/integration/ --tag integration

# All tests
bundle exec rspec
```

### VCR Configuration Details

VCR is configured in `spec_helper.rb` with:
- **Cassette library**: `spec/vcr_cassettes/`
- **Record mode**: `:once` (use existing, record new)
- **API key filtering**: Automatically replaces keys with `<OPENAI_API_KEY>`, etc.
- **Match on**: HTTP method, URI, and request body

**When to Re-record Cassettes**:
1. API response format changes
2. Adding new test scenarios
3. Provider updates model or endpoint
4. Testing error conditions

**Cassette Workflow**:
1. First run: Needs real API keys, records responses
2. Subsequent runs: Uses cassettes, no API calls
3. CI/CD: Uses committed cassettes, no secrets needed

## Translation Context Feature

The `translation_context` configuration allows providing domain-specific context to improve translation accuracy:

```ruby
config.translation_context = "Medical terminology for healthcare applications"
```

This context is included in the AI system prompt, helping with specialized terminology in fields like:
- Medical/Healthcare
- Legal
- Financial
- E-commerce
- Technical documentation

## Performance Considerations

- Enable caching for repeated translations to reduce API costs
- Use incremental mode to preserve manual corrections
- Monitor API usage through provider dashboards
- Batch processing automatically used for large files (≥50 strings)
- Rate limiting prevents API overload (configurable, default 0.5s between requests)
- Concurrent requests configurable via `max_concurrent_requests` (default: 3)
