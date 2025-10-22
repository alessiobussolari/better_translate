# Integration Tests with VCR

This directory contains integration tests that verify real API interactions with translation providers using VCR (Video Cassette Recorder) to record and replay HTTP interactions.

## Overview

**Integration tests** validate that the gem works correctly with real provider APIs:
- ChatGPT (OpenAI)
- Google Gemini
- Anthropic Claude (when implemented)

Unlike unit tests (which use WebMock stubs), integration tests make actual HTTP requests to provider APIs on first run, then replay recorded responses (cassettes) on subsequent runs.

## Setup

### 1. Install Dependencies

```bash
bundle install
```

### 2. Configure API Keys

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` and add your real API keys:

```env
OPENAI_API_KEY=sk-proj-...
GEMINI_API_KEY=...
ANTHROPIC_API_KEY=sk-ant-...
```

**Note**: The `.env` file is gitignored and will never be committed.

## Running Tests

### Run Integration Tests Only

```bash
bundle exec rspec spec/integration/ --tag integration
```

### Run Specific Provider

```bash
# ChatGPT only
bundle exec rspec spec/integration/chatgpt_integration_spec.rb

# Gemini only
bundle exec rspec spec/integration/gemini_integration_spec.rb
```

### Run All Tests (Unit + Integration)

```bash
bundle exec rspec
```

## VCR Cassettes

### What are Cassettes?

Cassettes are YAML files stored in `spec/vcr_cassettes/` that contain:
- HTTP request details (method, URL, headers, body)
- HTTP response details (status, headers, body)
- Automatically anonymized API keys

### Cassette Workflow

1. **First Run** (with API keys):
   - Makes real HTTP requests to provider APIs
   - Records responses in `spec/vcr_cassettes/`
   - Filters sensitive data (API keys replaced with placeholders)

2. **Subsequent Runs** (with or without API keys):
   - Uses recorded cassettes
   - No real HTTP requests made
   - Tests run fast and offline

3. **CI/CD Pipelines**:
   - Uses committed cassettes
   - No API keys needed
   - Consistent test results

### Cassette Directory Structure

```
spec/vcr_cassettes/
├── chatgpt/
│   ├── translate_hello_to_italian.yml
│   ├── translate_hello_to_french.yml
│   ├── translate_batch.yml
│   ├── translate_with_variables.yml
│   ├── translate_with_medical_context.yml
│   ├── translate_technical_term.yml
│   └── invalid_api_key.yml
└── gemini/
    ├── translate_hello_to_italian.yml
    ├── translate_hello_to_french.yml
    ├── translate_batch.yml
    ├── translate_with_variables.yml
    ├── translate_with_medical_context.yml
    ├── translate_technical_term.yml
    └── invalid_api_key.yml
```

## Re-recording Cassettes

### When to Re-record

- Provider API changes (new response format, headers, etc.)
- Adding new test scenarios
- Updating models (e.g., `gpt-5-nano` → `gpt-6`)
- Testing different error conditions

### How to Re-record

#### Re-record All Cassettes

```bash
# Delete all cassettes
rm -rf spec/vcr_cassettes/

# Run integration tests with API keys
bundle exec rspec spec/integration/ --tag integration
```

#### Re-record Specific Provider

```bash
# Re-record ChatGPT cassettes only
rm -rf spec/vcr_cassettes/chatgpt/
bundle exec rspec spec/integration/chatgpt_integration_spec.rb

# Re-record Gemini cassettes only
rm -rf spec/vcr_cassettes/gemini/
bundle exec rspec spec/integration/gemini_integration_spec.rb
```

#### Re-record Specific Test

```bash
# Delete specific cassette
rm spec/vcr_cassettes/chatgpt/translate_hello_to_italian.yml

# Run specific test
bundle exec rspec spec/integration/chatgpt_integration_spec.rb:25
```

## VCR Configuration

VCR is configured in `spec/spec_helper.rb` with:

- **Cassette library**: `spec/vcr_cassettes/`
- **Record mode**: `:once` (use existing, record new)
- **Hook**: WebMock
- **Sensitive data filtering**:
  - `ENV['OPENAI_API_KEY']` → `<OPENAI_API_KEY>`
  - `ENV['GEMINI_API_KEY']` → `<GEMINI_API_KEY>`
  - `ENV['ANTHROPIC_API_KEY']` → `<ANTHROPIC_API_KEY>`

### VCR Record Modes

- `:once` (default): Use cassettes if exist, record new ones
- `:new_episodes`: Record new interactions, keep existing
- `:all`: Re-record everything (use for complete refresh)
- `:none`: Never record, error if cassette missing

To change record mode temporarily:

```ruby
VCR.use_cassette("my_test", record: :all) do
  # test code
end
```

## Test Coverage

### ChatGPT Integration Tests

- ✅ Translate simple text to Italian
- ✅ Translate simple text to French
- ✅ Translate with medical context
- ✅ Translate batch of texts
- ✅ Preserve variables in translation
- ✅ Handle technical terminology
- ✅ Error handling with invalid API key

### Gemini Integration Tests

- ✅ Translate simple text to Italian
- ✅ Translate simple text to French
- ✅ Translate with medical context
- ✅ Translate batch of texts
- ✅ Preserve variables in translation
- ✅ Handle technical terminology
- ✅ Error handling with invalid API key

## Troubleshooting

### Tests Fail with "key not found: OPENAI_API_KEY"

**Solution**: Create `.env` file with API keys:

```bash
cp .env.example .env
# Edit .env and add your keys
```

### Tests Make Real API Calls Every Time

**Cause**: Cassettes not found or VCR not configured properly.

**Solution**:
1. Check cassettes exist in `spec/vcr_cassettes/`
2. Verify VCR is loaded in `spec/spec_helper.rb`
3. Re-record cassettes: `rm -rf spec/vcr_cassettes/ && bundle exec rspec spec/integration/`

### API Key Visible in Cassette

**Cause**: VCR filter not configured or ENV var name mismatch.

**Solution**: Check `spec/spec_helper.rb` has correct `filter_sensitive_data` configuration:

```ruby
config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV.fetch("OPENAI_API_KEY", nil) }
```

### Tests Pass Locally but Fail in CI

**Cause**: Cassettes not committed to git.

**Solution**:
```bash
git add spec/vcr_cassettes/
git commit -m "Add VCR cassettes for integration tests"
git push
```

## Best Practices

1. **Commit Cassettes**: Always commit cassettes to git for CI/CD
2. **API Keys in .env**: Never commit `.env` file (already in `.gitignore`)
3. **Re-record Periodically**: Keep cassettes up-to-date with API changes
4. **Test Without Keys**: Verify tests pass without `.env` before committing
5. **Small Cassettes**: Keep test inputs small for readable cassettes
6. **Document Changes**: Update this README when adding new integration tests

## References

- [VCR Documentation](https://github.com/vcr/vcr)
- [WebMock Documentation](https://github.com/bblimke/webmock)
- [dotenv Documentation](https://github.com/bkeepers/dotenv)
