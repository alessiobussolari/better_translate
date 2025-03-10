require 'rails/generators'

module BetterTranslate
  module Generators
    class TranslateGenerator < Rails::Generators::Base
      desc "Lancia il processo di traduzione configurato in BetterTranslate"

      def run_translation
        say_status("Starting", "Esecuzione della traduzione con BetterTranslate...", :green)
        BetterTranslate.magic
        say_status("Done", "Traduzione completata.", :green)
      end
    end
  end
end