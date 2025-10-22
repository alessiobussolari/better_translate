# Dummy Rails App - Usage Guide

This guide shows how to use the dummy Rails app to test and demonstrate BetterTranslate.

## Quick Start

### 1. Run Demo Script

The fastest way to see BetterTranslate in action:

```bash
ruby spec/dummy/demo_translation.rb
```

This will:
- Read `config/locales/en.yml`
- Translate to Italian and French
- Generate `it.yml` and `fr.yml` files
- Show progress and results

**Expected Output:**
```
🚀 Starting translation...
[BetterTranslate] Italian | hello | 6.3% | Elapsed: 0s | Remaining: ~0s
[BetterTranslate] Italian | world | 12.5% | Elapsed: 4s | Remaining: ~31s
...
✅ Success: 2 language(s)
```

### 2. View Generated Files

```bash
# List locale files
ls -lh spec/dummy/config/locales/

# View Italian translation
cat spec/dummy/config/locales/it.yml

# View French translation
cat spec/dummy/config/locales/fr.yml
```

### 3. Test in Rails Console

You can load the dummy app in a console to test I18n:

```ruby
# Load dummy app
require_relative 'spec/dummy/config/environment'

# Test translations
I18n.locale = :it
I18n.t('hello')  #=> "Ciao"
I18n.t('world')  #=> "Mondo"
I18n.t('users.greeting', name: "Marco")  #=> "Ciao Marco"

I18n.locale = :fr
I18n.t('hello')  #=> "Bonjour"
I18n.t('messages.success')  #=> "Opération réussie"
```

## Manual Translation (Ruby Code)

You can also translate programmatically:

```ruby
require "bundler/setup"
require_relative "lib/better_translate"
require "dotenv/load"

# Configure
config = BetterTranslate::Configuration.new
config.provider = :chatgpt
config.openai_key = ENV['OPENAI_API_KEY']
config.source_language = "en"
config.target_languages = [
  { short_name: "de", name: "German" },
  { short_name: "es", name: "Spanish" }
]
config.input_file = "spec/dummy/config/locales/en.yml"
config.output_folder = "spec/dummy/config/locales"
config.verbose = true

# Translate
translator = BetterTranslate::Translator.new(config)
results = translator.translate_all

puts "✅ Translated to #{results[:success_count]} languages"
```

## Using Different Providers

### ChatGPT (OpenAI)

```ruby
config.provider = :chatgpt
config.openai_key = ENV['OPENAI_API_KEY']
```

### Google Gemini

```ruby
config.provider = :gemini
config.google_gemini_key = ENV['GEMINI_API_KEY']
```

### Anthropic Claude (when available)

```ruby
config.provider = :anthropic
config.anthropic_key = ENV['ANTHROPIC_API_KEY']
```

## Advanced Usage

### Translation with Context

Add domain-specific context for better translations:

```ruby
config.translation_context = "Medical terminology"
# OR
config.translation_context = "E-commerce product descriptions"
# OR
config.translation_context = "Legal documents"
```

### Incremental Mode

Only translate new keys, preserve existing translations:

```ruby
config.translation_mode = :incremental
```

### With Exclusions

Exclude specific keys from translation:

```ruby
config.global_exclusions = ["brand_name", "company"]
config.exclusions_per_language = {
  "it" => ["legal.terms"],  # Don't translate legal terms to Italian
  "fr" => ["privacy_policy"]
}
```

### Caching Enabled

Speed up repeated translations:

```ruby
config.cache_enabled = true
config.cache_size = 1000
```

## File Structure

```
spec/dummy/
├── config/
│   ├── application.rb       # Rails app config
│   ├── environment.rb        # Environment setup
│   └── locales/
│       ├── en.yml            # Source file (English)
│       ├── it.yml            # Generated (Italian)
│       ├── fr.yml            # Generated (French)
│       ├── de.yml            # Optional (German)
│       └── es.yml            # Optional (Spanish)
├── demo_translation.rb       # Demo script
├── USAGE_GUIDE.md            # This file
└── README.md                 # Technical documentation
```

## Source File (`en.yml`)

The source file contains:
- **16 translation keys**
- **Nested structures**: messages, users, navigation, forms
- **Variables**: `%{name}` in `users.greeting`
- **Various types**: simple strings, nested hashes

```yaml
en:
  hello: "Hello"
  world: "World"
  messages:
    success: "Operation completed successfully"
    error: "An error occurred"
  users:
    greeting: "Hello %{name}"  # Variable preserved in translation
    profile: "User Profile"
  navigation:
    home: "Home"
    about: "About"
  forms:
    submit: "Submit"
    cancel: "Cancel"
```

## Generated Files

After translation, you'll have:

### `it.yml` (Italian)
```yaml
it:
  hello: Ciao
  world: Mondo
  messages:
    success: Operazione completata con successo
  users:
    greeting: Ciao %{name}  # ✅ Variable preserved!
```

### `fr.yml` (French)
```yaml
fr:
  hello: Bonjour
  world: Monde
  messages:
    success: Opération réussie
  users:
    greeting: Bonjour %{name}  # ✅ Variable preserved!
```

## Verification

Check translations are correct:

```bash
# Compare structures
diff <(grep "^  " spec/dummy/config/locales/en.yml) \
     <(grep "^  " spec/dummy/config/locales/it.yml)

# Count keys (should be same)
grep -c ":" spec/dummy/config/locales/en.yml  # 16
grep -c ":" spec/dummy/config/locales/it.yml  # 16
grep -c ":" spec/dummy/config/locales/fr.yml  # 16

# Verify variables preserved
grep "%{" spec/dummy/config/locales/en.yml  # Hello %{name}
grep "%{" spec/dummy/config/locales/it.yml  # Ciao %{name}
grep "%{" spec/dummy/config/locales/fr.yml  # Bonjour %{name}
```

## Cleanup

Remove generated files:

```bash
rm spec/dummy/config/locales/{it,fr,de,es}.yml
```

## Integration with Rails App

In a real Rails app:

1. **Install**: `rails g better_translate:install`
2. **Configure**: Edit `config/initializers/better_translate.rb`
3. **Translate**: Run the translator
4. **Use**: `I18n.t('hello', locale: :it)`

## Troubleshooting

### "API key not found"

```bash
# Set in .env file
echo "OPENAI_API_KEY=your_key_here" >> .env

# Or export in shell
export OPENAI_API_KEY=your_key_here
```

### "Input file does not exist"

Check path is correct:
```bash
ls -l spec/dummy/config/locales/en.yml
```

### Translations seem wrong

Try adding context:
```ruby
config.translation_context = "Your domain here"
```

Or try different provider:
```ruby
config.provider = :gemini  # Instead of :chatgpt
```

## Performance Tips

1. **Enable caching** for repeated translations
2. **Use batch mode** for large files (automatic when ≥50 strings)
3. **Use VCR cassettes** in tests to avoid API calls
4. **Adjust rate limiting** if hitting API limits

## Next Steps

- Modify `en.yml` to test with your own content
- Try different providers (ChatGPT, Gemini)
- Add more languages
- Test with complex nested structures
- Experiment with exclusions and context
