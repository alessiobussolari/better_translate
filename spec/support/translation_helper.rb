# frozen_string_literal: true

module TranslationHelper
  # Rende disponibili le costanti a livello di modulo
  include BetterTranslate::TestCases

  # Configura BetterTranslate con il provider specificato
  def configure_provider(provider_name)
    BetterTranslate.configure do |config|
      config.provider = provider_name
      config.source_language = "en"
      
      case provider_name
      when :chatgpt
        config.openai_api_key = ENV.fetch("OPENAI_API_KEY", "test_openai_key")
      when :gemini
        config.gemini_api_key = ENV.fetch("GEMINI_API_KEY", "test_gemini_key")
      end
    end
  end

  # Verifica se una traduzione è valida
  def valid_translation?(text)
    text.is_a?(String) && !text.empty? && text != "ERROR"
  end

  # Crea file YAML temporanei per i test
  def create_temp_yaml_files
    # Creiamo file con contenuti simili per testare il SimilarityAnalyzer
    en_content = {
      "en" => {
        "greeting" => "Hello, how are you?",
        "intro" => "Hi there, welcome!",
        "farewell" => "Goodbye, see you later!",
        "similar_text_1" => "This is a test message for similarity analysis",
        "similar_text_2" => "This is a test message for similarity checking",
        "similar_text_3" => "This is a test for similarity analysis",
        "unique_text" => "This is a completely different message"
      }
    }

    it_content = {
      "it" => {
        "greeting" => "Ciao, come stai?",
        "intro" => "Ciao, benvenuto!",
        "farewell" => "Arrivederci, a più tardi!",
        "similar_text_1" => "Questo è un messaggio di prova per l'analisi di similarità",
        "similar_text_2" => "Questo è un messaggio di prova per il controllo di similarità",
        "similar_text_3" => "Questo è un test per l'analisi di similarità",
        "unique_text" => "Questo è un messaggio completamente diverso"
      }
    }

    en_file = Tempfile.new(["en", ".yml"])
    it_file = Tempfile.new(["it", ".yml"])

    File.write(en_file.path, en_content.to_yaml)
    File.write(it_file.path, it_content.to_yaml)

    [en_file, it_file]
  end
end
