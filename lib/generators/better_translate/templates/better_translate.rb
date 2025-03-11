BetterTranslate.configure do |config|
  # Choose the provider to use: :chatgpt, :gemini, or any custom provider registered with BetterTranslate::Service.register_provider
  config.provider = :chatgpt

  # API key for OpenAI
  config.openai_key = ENV.fetch("OPENAI_API_KEY") { "YOUR_OPENAI_API_KEY" }

  # API key for Google Gemini
  config.google_gemini_key = ENV.fetch("GOOGLE_GEMINI_KEY") { "YOUR_GOOGLE_GEMINI_KEY" }
  
  # Custom provider API keys
  # If you've created a custom provider using 'rails generate better_translate:provider YourProvider',
  # add its API key here following the naming convention: config.your_provider_key
  # 
  # Example for a custom DeepL provider:
  # config.deepl_key = ENV.fetch("DEEPL_API_KEY") { "YOUR_DEEPL_API_KEY" }

  # Source language (for example "en" if the source file is in English)
  config.source_language = "en"

  # List of target languages (short_name and name)
  config.target_languages = [
    # { short_name: 'es', name: 'spagnolo' },
    # { short_name: 'it', name: 'italiano' },
    # { short_name: 'fr', name: 'francese' },
    # { short_name: 'de', name: 'tedesco' },
    # { short_name: 'pt', name: 'portoghese' },
    { short_name: "ru", name: "russian" }
  ]

  # Global exclusions (paths in dot notation) to exclude for all languages
  config.global_exclusions = [
    "key.value"
  ]

  # Language-specific exclusions
  config.exclusions_per_language = {
    "es" => [],
    "it" => [],
    "fr" => [],
    "de" => [],
    "pt" => [],
    "ru" => []
  }

  # Input file path (e.g. en.yml)
  config.input_file = Rails.root.join("config", "locales", "en.yml").to_s

  # Output folder where translated files will be saved
  config.output_folder = Rails.root.join("config", "locales", "translated").to_s

  # Translation method:
  # - :override => regenerates all translations
  # - :incremental => updates only missing keys (or those that have been modified)
  config.translation_method = :override
end
