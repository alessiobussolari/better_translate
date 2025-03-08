# frozen_string_literal: true

require "yaml"
require "better_translate/config"
require "better_translate/translator"

module BetterTranslate
  # Punto di ingresso della gemma
  def self.run(file_path, mode: :override, incremental_file: nil)
    config = Config.load_config
    translator = Translator.new(config)
    translator.translate_file(file_path, mode: mode, incremental_file: incremental_file)
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Config.new(
      provider: :google,
      default_language: 'it',
      target_languages: %w(en fr es),
      api_keys: {},
      translation_method: :override,
      initial_file_path: 'path/to/your/input.yml'
    )
    yield(configuration) if block_given?
  end

  def self.run
    translator = Translator.new(configuration)
    translator.translate_file(configuration.initial_file_path, mode: configuration.translation_method)
  end
end

