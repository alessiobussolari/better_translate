# Dummy Rails App for Testing

This is a minimal Rails application used for integration testing of the BetterTranslate gem.

## Purpose

The dummy app provides a realistic Rails environment to test:
- Translation of actual locale files
- Rails generators (`better_translate:install`, etc.)
- End-to-end workflows
- Variable preservation in translations (`%{name}`, `%<name>s`)
- Nested YAML structure handling

## Structure

```
spec/dummy/
├── config/
│   ├── application.rb      # Rails app configuration
│   ├── environment.rb       # Environment initialization
│   └── locales/
│       └── en.yml           # Sample English locale file
├── Rakefile                 # Rails tasks
└── README.md                # This file
```

## Sample Locale File

The `config/locales/en.yml` file contains realistic translations:

- Top-level keys: `hello`, `world`, `welcome`, `goodbye`
- Nested structures: `messages.*`, `users.*`, `navigation.*`, `forms.*`
- Variables: `users.greeting` contains `%{name}` placeholder
- Total: ~18 translation keys

## Usage in Tests

### Integration Tests

The dummy app is used in `spec/integration/rails_dummy_app_spec.rb`:

```ruby
# Translate dummy app locales using ChatGPT
config.input_file = File.join(dummy_app_path, "config/locales/en.yml")
config.output_folder = test_output_dir
translator = BetterTranslate::Translator.new(config)
translator.translate_all
```

### Generator Tests

Future generator tests will use this app to test:
- `rails g better_translate:install` → creates initializer
- `rails g better_translate:translate` → translates locales
- `rails g better_translate:analyze` → analyzes translations

## Running Tests

```bash
# Run all dummy app integration tests
bundle exec rspec spec/integration/rails_dummy_app_spec.rb

# Run specific test
bundle exec rspec spec/integration/rails_dummy_app_spec.rb:15
```

## Test Coverage

Current integration tests:
- ✅ ChatGPT translation of full dummy app
- ✅ Gemini translation of full dummy app
- ✅ Nested structure preservation
- ✅ Variable preservation (`%{name}`)
- ✅ Incremental translation mode
- ✅ Error handling (missing files, invalid YAML)

## VCR Cassettes

Integration tests record API interactions in `spec/vcr_cassettes/rails/`:
- `dummy_app_chatgpt_translation.yml` (~56KB)
- `dummy_app_gemini_translation.yml` (~34KB)
- `dummy_app_nested_translation.yml` (~56KB)
- `incremental_translation.yml` (~35KB)

## Extending the Dummy App

To add more test scenarios:

1. **Add new locale keys**: Edit `config/locales/en.yml`
2. **Add new languages**: Create `it.yml`, `fr.yml`, etc.
3. **Add complex structures**: Add deeply nested YAML structures
4. **Add edge cases**: Special characters, long strings, etc.

Example:

```yaml
# config/locales/en.yml
en:
  # ... existing keys ...

  complex:
    deeply:
      nested:
        structure: "This is a deeply nested value"

  edge_cases:
    special_chars: "This has special chars: é, à, ñ"
    long_text: "This is a very long text that tests how the translation handles lengthy content..."
```

## Maintenance

- Keep the dummy app minimal (no database, no controllers)
- Only add what's necessary for testing
- Update this README when adding new test scenarios
- Commit VCR cassettes after re-recording
