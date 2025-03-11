# frozen_string_literal: true

module BetterTranslate
  module TestCases
    # Casi di test standard per le traduzioni
    STANDARD_CASES = {
      simple: "Hello! How are you? I'm doing great!",
      special_chars: "Hello! How are you? I'm doing great! 😊 Let's test some special characters: àèìòù",
      long_text: "This is a longer text that will be used to test the translation capabilities of the providers. " \
                "It includes multiple sentences and should be handled correctly by all providers. " \
                "The translation should maintain the meaning and context of the original text."
    }.freeze

    # Lingue di base per i test
    BASIC_LANGUAGES = [
      { code: "it", name: "Italian" },
      { code: "es", name: "Spanish" },
      { code: "fr", name: "French" }
    ].freeze
  end
end
