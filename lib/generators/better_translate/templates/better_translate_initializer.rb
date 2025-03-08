# Configurazione di BetterTranslate

BetterTranslate.configure do |config|
  # Specifica il provider da utilizzare: :google oppure :openai
  config.provider = :google

  # Imposta le chiavi API relative ai provider
  config.api_keys = {
    google: 'YOUR_GOOGLE_API_KEY',
    openai: 'YOUR_OPENAI_API_KEY'
  }

  # Definisce la lingua di partenza
  config.default_language = 'it'

  # Lista delle lingue in cui tradurre
  config.target_languages = %w(en fr es)

  # Metodo di traduzione: :override per rigenerare tutte le traduzioni,
  # oppure :incremental per aggiornare solo le chiavi mancanti
  config.translation_method = :override

  # Percorso del file YML iniziale da tradurre
  config.initial_file_path = 'path/to/your/input.yml'
end
