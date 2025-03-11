# frozen_string_literal: true
require "ruby-progressbar"

require "better_translate/version"
require "better_translate/utils"
require "better_translate/translator"
require "better_translate/service"
require "better_translate/writer"
require "better_translate/helper"

require 'better_translate/providers/base_provider'
require 'better_translate/providers/chatgpt_provider'
require 'better_translate/providers/gemini_provider'

module BetterTranslate
  class << self
    attr_accessor :configuration

    # Metodo per configurare la gemma
    def configure
      self.configuration ||= OpenStruct.new
      yield(configuration) if block_given?
    end

    # Metodo install per generare il file di configurazione (initializer)
    def install
      unless defined?(Rails) && Rails.respond_to?(:root)
        message = "Il metodo install è disponibile solo in un'applicazione Rails."
        BetterTranslate::Utils.logger(message: message)
        return
      end

      # Costruisce il percorso della cartella template all'interno della gemma
      source = File.expand_path("../generators/better_translate/templates/better_translate.rb", __dir__)
      destination = File.join(Rails.root, "config", "initializers", "better_translate.rb")

      if File.exist?(destination)
        message = "Il file initializer esiste già: #{destination}"
        BetterTranslate::Utils.logger(message: message)
      else
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(source, destination)
        message = "Il file initializer esiste già: #{destination}"
        BetterTranslate::Utils.logger(message: message)
      end
    end

    def magic
      message = "Metodo magic invocato: eseguirò la traduzione dei file..."
      BetterTranslate::Utils.logger(message: message)

      BetterTranslate::Translator.work
      message = "Metodo magic invocato: Traduzione completata con successo!"
      BetterTranslate::Utils.logger(message: message)
    end

  end
end