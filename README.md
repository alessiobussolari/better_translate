# BetterTranslate

BetterTranslate is a Ruby gem that enables you to translate YAML files from a source language into one or more target languages using translation providers such as ChatGPT (OpenAI) and Google Gemini. The gem supports two translation modes:

- **Override**: Completely rewrites the translated file.
- **Incremental**: Updates the translated file only with new or modified keys while keeping existing ones.

Configuration is centralized via an initializer (for example, in a Rails app), where you can set API keys, the source language, target languages, key exclusions, the output folder, and the translation mode. Additionally, BetterTranslate integrates progress tracking using the [ruby-progressbar](https://github.com/jfelchner/ruby-progressbar) gem.

## Features

- **Multi-language YAML Translation**: Translates YAML files from a source language into one or more target languages.
- **Multiple Providers**: Supports ChatGPT (OpenAI) and Google Gemini (with potential for extending to other providers in the future).
- **Translation Modes**:
    - **Override**: Rewrites the file from scratch.
    - **Incremental**: Updates only missing or modified keys.
- **Centralized Configuration**: Configured via an initializer with settings for API keys, source language, target languages, exclusions (using dot notation), and the output folder.
- **Progress Bar**: Displays the translation progress using ruby-progressbar.

## Installation

Add the gem to your Gemfile:

```ruby
gem 'better_translate'
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
    "key.child_key",
  ]

  # Language-specific exclusions (optional)
  config.exclusions_per_language = {
    "ru" => []
  }

  # Path to the input file (e.g., en.yml)
  config.input_file = Rails.root.join("config", "locales", "en.yml").to_s

  # Translation mode: :override or :incremental
  config.translation_method = :override
end
```

## Usage

### YAML File Translation

To start the translation process, simply call the `magic` method:

```ruby
BetterTranslate.magic
```

This will execute the process that:
1. Reads the input YAML file.
2. Applies any filters (exclusions).
3. Translates the strings from the source language to the configured target languages.
4. Writes the translated files to the output folder, either in **override** or **incremental** mode based on the configuration.

## Contributing

Pull requests are welcome! If you would like to suggest improvements or new features, please open an issue to discuss your ideas before submitting a pull request.

## Changelog

See the [CHANGELOG](https://github.com/alessiobussolari/better_translate/blob/main/CHANGELOG.md) for a summary of changes.

## License

BetterTranslate is distributed under the MIT license. See the [LICENSE](LICENSE) file for more details.