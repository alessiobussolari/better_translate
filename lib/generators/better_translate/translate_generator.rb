# frozen_string_literal: true

require 'rails/generators'

module BetterTranslate
  module Generators
    class TranslateGenerator < Rails::Generators::Base
      desc "Starts the translation process configured in BetterTranslate"

      def translate
        say "Starting translation with BetterTranslate...", :blue
        
        # Verifica che la configurazione sia valida
        if validate_configuration
          say "Configuration validated. Starting translation...", :green
          BetterTranslate.magic
          say "Translation completed.", :green
        else
          say "Translation aborted due to configuration issues.", :red
        end
      end
      
      private
      
      def validate_configuration
        valid = true
        
        # Verifica che il file di input esista
        unless BetterTranslate.configuration.respond_to?(:input_file)
          say "Error: input_file not configured. Please check your initializer.", :red
          return false
        end
        
        input_file = BetterTranslate.configuration.input_file
        unless File.exist?(input_file)
          say "Error: Input file not found: #{input_file}", :red
          valid = false
        end
        
        # Verifica che ci siano lingue target attive
        if !BetterTranslate.configuration.respond_to?(:target_languages) || 
           BetterTranslate.configuration.target_languages.empty?
          say "Error: No target languages configured. Please uncomment or add target languages in your initializer.", :red
          valid = false
        end
        
        # Verifica che il provider sia configurato
        if !BetterTranslate.configuration.respond_to?(:provider)
          say "Error: No provider configured. Please set config.provider in your initializer.", :red
          valid = false
        end
        
        # Verifica che la chiave API sia configurata per il provider selezionato
        if BetterTranslate.configuration.respond_to?(:provider)
          provider = BetterTranslate.configuration.provider
          if provider == :chatgpt && (!BetterTranslate.configuration.respond_to?(:openai_key) || 
             BetterTranslate.configuration.openai_key == "YOUR_OPENAI_API_KEY")
            say "Error: OpenAI API key not configured. Please set config.openai_key in your initializer.", :red
            valid = false
          elsif provider == :gemini && (!BetterTranslate.configuration.respond_to?(:google_gemini_key) || 
                BetterTranslate.configuration.google_gemini_key == "YOUR_GOOGLE_GEMINI_KEY")
            say "Error: Gemini API key not configured. Please set config.google_gemini_key in your initializer.", :red
            valid = false
          end
        end
        
        valid
      end
    end
  end
end