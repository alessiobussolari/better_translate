# frozen_string_literal: true

require "csv"

require_relative "better_translate/version"
require_relative "better_translate/errors"
require_relative "better_translate/configuration"
require_relative "better_translate/cache"
require_relative "better_translate/rate_limiter"
require_relative "better_translate/validator"
require_relative "better_translate/variable_extractor"
require_relative "better_translate/utils/hash_flattener"
require_relative "better_translate/providers/base_http_provider"
require_relative "better_translate/providers/chatgpt_provider"
require_relative "better_translate/providers/gemini_provider"
require_relative "better_translate/providers/anthropic_provider"
require_relative "better_translate/provider_factory"
require_relative "better_translate/yaml_handler"
require_relative "better_translate/json_handler"
require_relative "better_translate/progress_tracker"
require_relative "better_translate/strategies/base_strategy"
require_relative "better_translate/strategies/deep_strategy"
require_relative "better_translate/strategies/batch_strategy"
require_relative "better_translate/strategies/strategy_selector"
require_relative "better_translate/translator"
require_relative "better_translate/direct_translator"
require_relative "better_translate/analyzer/key_scanner"
require_relative "better_translate/analyzer/code_scanner"
require_relative "better_translate/analyzer/orphan_detector"
require_relative "better_translate/analyzer/reporter"
require_relative "better_translate/cli"

# Load Rails integration if Rails is present
require_relative "better_translate/railtie" if defined?(Rails::Railtie)

# BetterTranslate - AI-powered YAML locale file translator
#
# Automatically translate YAML locale files using AI providers (ChatGPT, Gemini, Claude).
# Features intelligent caching, batch processing, and Rails integration.
#
# @example Basic usage
#   BetterTranslate.configure do |config|
#     config.provider = :chatgpt
#     config.openai_key = ENV['OPENAI_API_KEY']
#     config.source_language = "en"
#     config.target_languages = [
#       { short_name: "it", name: "Italian" },
#       { short_name: "fr", name: "French" }
#     ]
#     config.input_file = "config/locales/en.yml"
#     config.output_folder = "config/locales"
#   end
#
#   BetterTranslate.translate_files
#
module BetterTranslate
  class << self
    # Configure BetterTranslate
    #
    # @yieldparam config [Configuration] Configuration object to modify
    # @return [Configuration] The configuration object
    #
    # @example
    #   BetterTranslate.configure do |config|
    #     config.provider = :chatgpt
    #     config.openai_key = ENV['OPENAI_API_KEY']
    #     config.source_language = "en"
    #     config.target_languages = [{ short_name: "it", name: "Italian" }]
    #   end
    #
    def configure
      yield(configuration)
      configuration
    end

    # Get current configuration
    #
    # @return [Configuration] Current configuration instance
    #
    # @example
    #   config = BetterTranslate.configuration
    #   config.provider #=> :chatgpt
    #
    def configuration
      @configuration ||= Configuration.new
    end

    # Translate files using current configuration
    #
    # @return [Hash] Results with :success_count, :failure_count, :errors
    # @raise [ConfigurationError] if configuration is invalid or missing
    #
    # @example
    #   results = BetterTranslate.translate_files
    #   puts "Success: #{results[:success_count]}, Failures: #{results[:failure_count]}"
    #
    def translate_files
      unless @configuration
        raise ConfigurationError,
              "BetterTranslate is not configured. Call BetterTranslate.configure first."
      end

      translator = Translator.new(configuration)
      translator.translate_all
    end

    # Reset configuration
    #
    # @return [void]
    #
    # @example
    #   BetterTranslate.reset!
    #   BetterTranslate.configuration.provider #=> nil
    #
    def reset!
      @configuration = nil
    end

    # Get gem version
    #
    # @return [String] Version string
    #
    # @example
    #   BetterTranslate.version #=> "0.1.0"
    #
    def version
      VERSION
    end
  end
end
