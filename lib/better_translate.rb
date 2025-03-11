# frozen_string_literal: true
require "ruby-progressbar"

require "better_translate/version"
require "better_translate/utils"
require "better_translate/translator"
require "better_translate/service"
require "better_translate/writer"
require "better_translate/helper"
require "better_translate/similarity_analyzer"

require 'better_translate/providers/base_provider'
require 'better_translate/providers/chatgpt_provider'
require 'better_translate/providers/gemini_provider'

require 'ostruct'

# Main module for the BetterTranslate gem.
# Provides functionality for translating YAML files using various AI providers.
#
# @example Basic configuration and usage
#   BetterTranslate.configure do |config|
#     config.provider = :chatgpt
#     config.openai_key = ENV['OPENAI_API_KEY']
#     config.input_file = 'config/locales/en.yml'
#     config.target_languages = [{short_name: 'fr', name: 'French'}]
#   end
#   
#   BetterTranslate.magic # Start the translation process
module BetterTranslate
  class << self
    # Configuration object for the gem
    # @return [OpenStruct] The configuration object
    attr_accessor :configuration

    # Configures the gem with the provided block.
    # Sets up the configuration object and yields it to the block.
    #
    # @yield [configuration] Yields the configuration object to the block
    # @yieldparam configuration [OpenStruct] The configuration object
    # @return [OpenStruct] The updated configuration object
    def configure
      self.configuration ||= OpenStruct.new
      yield(configuration) if block_given?
    end

    # Installs the gem configuration file (initializer) in a Rails application.
    # Copies the template initializer to the Rails config/initializers directory.
    # Only works in a Rails environment.
    #
    # @return [void]
    # @note This method will log an error if not called from a Rails application
    def install
      unless defined?(Rails) && Rails.respond_to?(:root)
        message = "The install method is only available in a Rails application."
        BetterTranslate::Utils.logger(message: message)
        return
      end

      # Builds the path to the template folder inside the gem
      source = File.expand_path("../generators/better_translate/templates/better_translate.rb", __dir__)
      destination = File.join(Rails.root, "config", "initializers", "better_translate.rb")

      if File.exist?(destination)
        message = "The initializer file already exists: #{destination}"
        BetterTranslate::Utils.logger(message: message)
      else
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(source, destination)
        message = "The initializer file already exists: #{destination}"
        BetterTranslate::Utils.logger(message: message)
      end
    end

    # Starts the translation process using the configured settings.
    # This is the main entry point for the translation functionality.
    # Logs the start and completion of the translation process.
    #
    # @return [void]
    # @example
    #   BetterTranslate.magic
    def magic
      message = "Magic method invoked: Translation will begin..."
      BetterTranslate::Utils.logger(message: message)
      # Utilizziamo il logger per tutti i messaggi
      message = "\n[BetterTranslate] Starting translation process...\n"
      BetterTranslate::Utils.logger(message: message)

      BetterTranslate::Translator.work
      
      message = "Magic method invoked: Translation completed successfully!"
      BetterTranslate::Utils.logger(message: message)
      # Utilizziamo il logger per tutti i messaggi
      message = "\n[BetterTranslate] Translation completed successfully!\n"
      BetterTranslate::Utils.logger(message: message)
    end

  end
end