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

module BetterTranslate
  class << self
    attr_accessor :configuration

    # Method to configure the gem
    def configure
      self.configuration ||= OpenStruct.new
      yield(configuration) if block_given?
    end

    # Install method to generate the configuration file (initializer)
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

    def magic
      message = "Magic method invoked: Translation will begin..."
      BetterTranslate::Utils.logger(message: message)

      BetterTranslate::Translator.work
      message = "Magic method invoked: Translation completed successfully!"
      BetterTranslate::Utils.logger(message: message)
    end

  end
end