# frozen_string_literal: true

module BetterTranslate
  # Main translator class
  #
  # Coordinates the translation process using configuration, providers,
  # strategies, and YAML handling.
  #
  # @example Basic usage
  #   config = Configuration.new
  #   config.provider = :chatgpt
  #   config.openai_key = ENV['OPENAI_API_KEY']
  #   config.source_language = "en"
  #   config.target_languages = [{ short_name: "it", name: "Italian" }]
  #   config.input_file = "config/locales/en.yml"
  #   config.output_folder = "config/locales"
  #
  #   translator = Translator.new(config)
  #   results = translator.translate_all
  #
  class Translator
    # @return [Configuration] Configuration object
    attr_reader :config

    # Initialize translator
    #
    # @param config [Configuration] Configuration object
    #
    # @example
    #   translator = Translator.new(config)
    #
    def initialize(config)
      @config = config
      @config.validate!
      provider_name = config.provider || :chatgpt
      @provider = ProviderFactory.create(provider_name, config)
      @yaml_handler = YAMLHandler.new(config)
      @progress_tracker = ProgressTracker.new(enabled: config.verbose)
    end

    # Translate to all target languages
    #
    # @return [Hash] Results hash with :success_count, :failure_count, :errors
    #
    # @example
    #   results = translator.translate_all
    #   #=> { success_count: 2, failure_count: 0, errors: [] }
    #
    def translate_all
      source_strings = @yaml_handler.get_source_strings

      # @type var results: translation_results
      results = {
        success_count: 0,
        failure_count: 0,
        errors: []
      }

      config.target_languages.each do |lang|
        translate_language(source_strings, lang)
        results[:success_count] += 1
      rescue StandardError => e
        results[:failure_count] += 1
        # @type var error_context: Hash[Symbol, untyped]
        error_context = if e.is_a?(BetterTranslate::Error)
                          e.context
                        else
                          {}
                        end
        results[:errors] << {
          language: lang[:name],
          error: e.message,
          context: error_context
        }
        @progress_tracker.error(lang[:name], e)
      end

      results
    end

    private

    # Translate to a single language
    #
    # @param source_strings [Hash] Source strings (flattened)
    # @param lang [Hash] Language config with :short_name and :name
    # @return [void]
    # @api private
    #
    def translate_language(source_strings, lang)
      target_lang_code = lang[:short_name]
      target_lang_name = lang[:name]

      # Filter exclusions
      strings_to_translate = @yaml_handler.filter_exclusions(source_strings, target_lang_code)

      return if strings_to_translate.empty?

      # Select strategy
      strategy = Strategies::StrategySelector.select(
        strings_to_translate.size,
        config,
        @provider,
        @progress_tracker
      )

      # Translate
      @progress_tracker.reset
      translated = strategy.translate(strings_to_translate, target_lang_code, target_lang_name)

      # Save
      output_path = @yaml_handler.build_output_path(target_lang_code)

      final_translations = if config.translation_mode == :incremental
                             @yaml_handler.merge_translations(output_path, translated)
                           else
                             Utils::HashFlattener.unflatten(translated)
                           end

      # Wrap in language key (e.g., "it:")
      wrapped = { target_lang_code => final_translations }
      @yaml_handler.write_yaml(output_path, wrapped)

      @progress_tracker.complete(target_lang_name, translated.size)
    end
  end
end
