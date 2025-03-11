require 'rails/generators'

module BetterTranslate
  module Generators
    class TranslateGenerator < Rails::Generators::Base
      desc "Starts the translation process configured in BetterTranslate"

      def run_translation
        message = "Starting translation with BetterTranslate..."
        BetterTranslate::Utils.logger(message: message)
        BetterTranslate.magic
        message = "Translation completed."
        BetterTranslate::Utils.logger(message: message)
      end
    end
  end
end