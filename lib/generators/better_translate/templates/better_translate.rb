BetterTranslate.configure do |config|
  # Scegli il provider da utilizzare: :chatgpt oppure :gemini
  config.provider = :chatgpt

  # API key per OpenAI
  config.openai_key = ENV.fetch("OPENAI_API_KEY") { "YOUR_OPENAI_API_KEY" }

  # API key per Google Gemini
  config.google_gemini_key = ENV.fetch("GOOGLE_GEMINI_KEY") { "YOUR_GOOGLE_GEMINI_KEY" }

  # Lingua sorgente (ad esempio "en" se il file sorgente è in inglese)
  config.source_language = "en"

  # Lista delle lingue target (short_name e name)
  config.target_languages = [
    # { short_name: 'es', name: 'spagnolo' },
    # { short_name: 'it', name: 'italiano' },
    # { short_name: 'fr', name: 'francese' },
    # { short_name: 'de', name: 'tedesco' },
    # { short_name: 'pt', name: 'portoghese' },
    { short_name: "ru", name: "russian" }
  ]

  # Esclusioni globali (percorsi in dot notation) da escludere per tutte le lingue
  config.global_exclusions = [
    "key.value"
  ]

  # Esclusioni specifiche per lingua
  config.exclusions_per_language = {
    "es" => [],
    "it" => [],
    "fr" => [],
    "de" => [],
    "pt" => [],
    "ru" => []
  }

  # Percorso del file di input (ad es. en.yml)
  config.input_file = Rails.root.join("config", "locales", "en.yml").to_s

  # Cartella di output dove verranno salvati i file tradotti
  config.output_folder = Rails.root.join("config", "locales", "translated").to_s

  # Metodo di traduzione:
  # - :override => rigenera tutte le traduzioni
  # - :incremental => aggiorna solo le chiavi mancanti (o quelle che hanno subito modifiche)
  config.translation_method = :override
end
