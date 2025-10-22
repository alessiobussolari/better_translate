# 06 - Main Module & API

[← Previous: 05-Translation Logic](./05-translation_logic.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 07-Direct Translation Helpers →](./07-direct_translation_helpers.md)

---

## Main Module & API

### 6.1 Aggiornare `lib/better_translate.rb`

```ruby
# frozen_string_literal: true

require_relative "better_translate/version"
require_relative "better_translate/errors"
require_relative "better_translate/configuration"
require_relative "better_translate/validator"
require_relative "better_translate/cache"
require_relative "better_translate/rate_limiter"
require_relative "better_translate/utils/hash_flattener"
require_relative "better_translate/yaml_handler"
require_relative "better_translate/progress_tracker"
require_relative "better_translate/providers/base_http_provider"
require_relative "better_translate/providers/chatgpt_provider"
require_relative "better_translate/providers/gemini_provider"
require_relative "better_translate/providers/anthropic_provider"
require_relative "better_translate/provider_factory"
require_relative "better_translate/strategies/base_strategy"
require_relative "better_translate/strategies/deep_strategy"
require_relative "better_translate/strategies/batch_strategy"
require_relative "better_translate/strategies/strategy_selector"
require_relative "better_translate/translator"

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
#     config.target_languages = [{ short_name: "it", name: "Italian" }]
#     config.input_file = "config/locales/en.yml"
#     config.output_folder = "config/locales"
#   end
#
#   BetterTranslate.translate_all
#
# @example With advanced options
#   BetterTranslate.configure do |config|
#     config.provider = :anthropic
#     config.anthropic_key = ENV['ANTHROPIC_API_KEY']
#     config.source_language = "en"
#     config.target_languages = [
#       { short_name: "it", name: "Italian" },
#       { short_name: "fr", name: "French" }
#     ]
#     config.input_file = "config/locales/en.yml"
#     config.output_folder = "config/locales"
#     config.translation_mode = :incremental
#     config.translation_context = "E-commerce product descriptions"
#     config.cache_enabled = true
#     config.verbose = true
#     config.global_exclusions = ["app.name"]
#   end
#
#   results = BetterTranslate.translate_all
#   puts "Success: #{results[:success_count]}, Failures: #{results[:failure_count]}"
#
module BetterTranslate
  class << self
    # @return [Configuration, nil] Current configuration
    attr_accessor :configuration

    # Configure BetterTranslate
    #
    # @yieldparam config [Configuration] Configuration object to customize
    # @return [Configuration] The configuration object
    #
    # @example
    #   BetterTranslate.configure do |config|
    #     config.provider = :chatgpt
    #     config.openai_key = ENV['OPENAI_API_KEY']
    #   end
    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
      configuration
    end

    # Translate all target languages
    #
    # @return [Hash] Results hash with :success_count, :failure_count, :errors
    # @raise [ConfigurationError] if configuration is invalid
    #
    # @example
    #   results = BetterTranslate.translate_all
    #   puts "Translated #{results[:success_count]} languages"
    def translate_all
      raise ConfigurationError, "BetterTranslate not configured" unless configuration

      translator = Translator.new(configuration)
      translator.translate_all
    end

    # Reset configuration
    #
    # @return [void]
    def reset!
      self.configuration = nil
    end
  end
end
```

---

---

[← Previous: 05-Translation Logic](./05-translation_logic.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 07-Direct Translation Helpers →](./07-direct_translation_helpers.md)
