# BetterTranslate 🌍

[![Gem Version](https://badge.fury.io/rb/better_translate.svg)](https://badge.fury.io/rb/better_translate)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

> 🚀 A powerful Ruby gem for seamless YAML file translations using AI providers like ChatGPT and Google Gemini

BetterTranslate simplifies the translation of YAML files in your Ruby/Rails applications by leveraging advanced AI models. With support for both ChatGPT (OpenAI) and Google Gemini, it offers:

✨ **Key Features**
- 🔄 Smart translation modes (Override/Incremental)
- 🎯 Precise key exclusion control
- 📊 Real-time progress tracking
- 🧪 Comprehensive test coverage
- ⚡️ LRU caching for performance
- 🔍 Translation similarity analysis
- 📚 Extensive YARD documentation

## Why BetterTranslate? 🤔

- 🌐 **AI-Powered Translation**: Leverage ChatGPT and Google Gemini for high-quality translations
- 🔄 **Smart Translation Modes**:
  - `Override`: Full file rewrite
  - `Incremental`: Update only new/modified keys
- 🎯 **Precise Control**:
  - Global key exclusions
  - Language-specific exclusions
  - Dot notation support
- 🛠 **Developer-Friendly**:
  - Rails generators included
  - Comprehensive test suite
  - LRU caching for performance
  - Progress tracking
  - Detailed YARD documentation
- 🔍 **Translation Analysis**:
  - Similarity detection
  - Detailed reports
  - Optimization suggestions
- 🔧 **Flexible Helpers**:
  - Single text translation
  - Bulk text translation
  - Multiple target languages support

## Installation

Add the gem to your Gemfile:

```ruby
gem 'better_translate', '~> 0.4.2'
```

Then run:

```bash
bundle install
```

Or install the gem manually:

```bash
gem install better_translate
```

## Configuration

In a Rails application, generate the initializer by running:

```bash
rails generate better_translate:install
```

This command creates the file `config/initializers/better_translate.rb` with a default configuration. An example configuration is:

```ruby
BetterTranslate.configure do |config|
  # Choose the provider to use: :chatgpt or :gemini
  config.provider = :chatgpt
  
  # API key for ChatGPT (OpenAI)
  config.openai_key = ENV.fetch("OPENAI_API_KEY") { "YOUR_OPENAI_API_KEY" }
  
  # API key for Google Gemini
  config.google_gemini_key = ENV.fetch("GOOGLE_GEMINI_KEY") { "YOUR_GOOGLE_GEMINI_KEY" }
  
  # Source language (e.g., "en" if the source file is in English)
  config.source_language = "en"
  
  # Output folder where the translated files will be saved
  config.output_folder = Rails.root.join("config", "locales", "translated").to_s
  
  # List of target languages (short_name and name)
  config.target_languages = [
    # Example:
    { short_name: "it", name: "italian" }
  ]
  
  # Global exclusions (keys in dot notation) to exclude from translation
  config.global_exclusions = [
    "key.child_key"
  ]
  
  # Language-specific exclusions: keys to exclude only for specific target languages
  config.exclusions_per_language = {
    "es" => [],
    "it" => ["sample.valid"],
    "fr" => [],
    "de" => [],
    "pt" => [],
    "ru" => []
  }
  
  # Path to the input file (e.g., en.yml)
  config.input_file = Rails.root.join("config", "locales", "en.yml").to_s
  
  # Translation mode: :override or :incremental
  config.translation_mode = :override
end
```

## Usage

### Translating YAML Files

To start the translation process, simply call the `magic` method:

```ruby
BetterTranslate.magic
```

This will execute the process that:
1. Reads the input YAML file.
2. Applies the global exclusion filtering.
3. Applies additional language-specific exclusion filtering for each target language.
4. Translates the strings from the source language into the configured target languages.
5. Writes the translated files to the output folder, either in **override** or **incremental** mode based on the configuration.

### Using Rails Generators

The gem includes generators to simplify tasks:

- **Generate Initializer:**

  ```bash
  rails generate better_translate:install
  ```

- **Trigger Translation Process:**

  ```bash
  rails generate better_translate:translate
  ```

  The `better_translate:translate` generator will trigger the translation process (via `BetterTranslate.magic`) and display progress in the terminal.

- **Analyze Translations:**

  ```bash
  rails generate better_translate:analyze
  ```

  The `better_translate:analyze` generator will:
  - Scan all YAML files in your locales directory
  - Find similar translations using Levenshtein distance
  - Generate two reports:
    - `translation_similarities.json`: Detailed JSON report
    - `translation_similarities_summary.txt`: Human-readable summary
  
  This helps you:
  - Identify potentially redundant translations
  - Maintain consistency across your translations
  - Optimize your translation files
  - Reduce translation costs

### Translation Helpers

BetterTranslate provides helper methods to simplify translation tasks.

#### Single Text Translation

The `translate_text_to_languages` helper allows you to translate a single text into multiple target languages in one call.

**Example Usage:**

```ruby
text = "Hello world!"
target_languages = [
  { short_name: "it", name: "Italian" },
  { short_name: "fr", name: "French" }
]

translated = BetterTranslate::TranslationHelper.translate_text_to_languages(
  text,
  target_languages,
  "en",       # source language code
  :chatgpt    # provider: can be :chatgpt or :gemini
)

puts translated
# Expected output:
# { "it" => "Ciao mondo!", "fr" => "Bonjour le monde!" }
```

#### Multiple Texts Translation

The `translate_texts_to_languages` helper extends the functionality to translate an array of texts into multiple target languages. It returns a hash where each key is a target language code and the value is an array of translated texts.

**Example Usage:**

```ruby
texts = ["Hello world!", "How are you?"]
target_languages = [
  { short_name: "it", name: "Italian" },
  { short_name: "fr", name: "French" }
]

translated_texts = BetterTranslate::TranslationHelper.translate_texts_to_languages(
  texts,
  target_languages,
  "en",       # source language code
  :chatgpt    # provider: can be :chatgpt or :gemini
)

puts translated_texts
# Expected output:
# {
#   "it" => ["Ciao mondo!", "Come stai?"],
#   "fr" => ["Bonjour le monde!", "Comment ça va?"]
# }
```

## Testing 🧪

BetterTranslate comes with a comprehensive test suite using RSpec. To run the tests:

```bash
bundle exec rspec
```

The test suite covers:
- Core translation functionality
- Cache implementation (LRU)
- Provider selection and initialization
- Error handling
- Configuration management

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Contact & Support 📬

- **Email**: alessio.bussolari@pandev.it
- **Issues**: [GitHub Issues](https://github.com/alessiobussolari/better_translate/issues)
- **Discussions**: [GitHub Discussions](https://github.com/alessiobussolari/better_translate/discussions)

## License 📄

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

BetterTranslate aims to simplify the translation of YAML files in Ruby projects by providing a flexible, configurable, and extensible system. Whether you need a complete file rewrite or an incremental update, BetterTranslate streamlines the translation process using advanced providers like ChatGPT and Google Gemini. Contributions, feedback, and feature requests are highly encouraged to help improve the gem further.

For more details, please visit the [GitHub repository](https://github.com/alessiobussolari/better_translate).

## License

BetterTranslate is distributed under the MIT license. See the [LICENSE](LICENSE) file for more details.
