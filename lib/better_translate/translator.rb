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

      # Resolve input files (supports input_file, input_files array, or glob pattern)
      @input_files = resolve_input_files

      # We'll determine handler per file during translation
      @progress_tracker = ProgressTracker.new(enabled: config.verbose)
    end

    # Translate to all target languages
    #
    # Uses parallel execution when max_concurrent_requests > 1,
    # sequential execution otherwise. Supports multiple input files.
    #
    # @return [Hash] Results hash with :success_count, :failure_count, :errors
    #
    # @example
    #   results = translator.translate_all
    #   #=> { success_count: 2, failure_count: 0, errors: [] }
    #
    def translate_all
      # @type var combined_results: translation_results
      combined_results = {
        success_count: 0,
        failure_count: 0,
        errors: []
      }

      @input_files.each do |input_file|
        # Create appropriate handler for this file
        handler = if input_file.end_with?(".json")
                    JsonHandler.new(config)
                  else
                    YAMLHandler.new(config)
                  end

        # Temporarily set input_file for this iteration
        original_input_file = config.input_file
        config.input_file = input_file

        source_strings = handler.get_source_strings

        results = if config.max_concurrent_requests > 1
                    translate_parallel(source_strings, handler)
                  else
                    translate_sequential(source_strings, handler)
                  end

        # Restore original config
        config.input_file = original_input_file

        # Accumulate results
        combined_results[:success_count] += results[:success_count]
        combined_results[:failure_count] += results[:failure_count]
        combined_results[:errors].concat(results[:errors])
      end

      combined_results
    end

    private

    # Resolve input files from config
    #
    # Handles input_file, input_files array, or glob patterns
    #
    # @return [Array<String>] Resolved file paths
    # @raise [FileError] if no files found
    # @api private
    #
    def resolve_input_files
      files = if config.input_files
                # Handle input_files (array or glob pattern)
                if config.input_files.is_a?(Array)
                  config.input_files
                else
                  # Glob pattern
                  Dir.glob(config.input_files)
                end
              elsif config.input_file
                # Backward compatibility with single input_file
                [config.input_file]
              else
                [] # : Array[String]
              end

      # Validate files exist (unless glob pattern that found nothing)
      if files.empty?
        if config.input_files && !config.input_files.is_a?(Array)
          raise FileError, "No files found matching pattern: #{config.input_files}"
        end

        raise FileError, "No input files specified"

      end

      files.each do |file|
        Validator.validate_file_exists!(file)
      end

      files
    end

    # Translate languages in parallel
    #
    # @param source_strings [Hash] Source strings (flattened)
    # @param handler [YAMLHandler, JsonHandler] File handler for this file
    # @return [Hash] Results hash with counts and errors
    # @api private
    #
    def translate_parallel(source_strings, handler)
      # @type var results: translation_results
      results = {
        success_count: 0,
        failure_count: 0,
        errors: []
      }
      mutex = Mutex.new

      # Process languages in batches of max_concurrent_requests
      config.target_languages.each_slice(config.max_concurrent_requests) do |batch|
        threads = batch.map do |lang|
          Thread.new do
            translate_language(source_strings, lang, handler)
            mutex.synchronize { results[:success_count] += 1 }
          rescue StandardError => e
            mutex.synchronize { record_error(results, lang, e) }
          end
        end
        threads.each(&:join)
      end

      results
    end

    # Translate languages sequentially
    #
    # @param source_strings [Hash] Source strings (flattened)
    # @param handler [YAMLHandler, JsonHandler] File handler for this file
    # @return [Hash] Results hash with counts and errors
    # @api private
    #
    def translate_sequential(source_strings, handler)
      # @type var results: translation_results
      results = {
        success_count: 0,
        failure_count: 0,
        errors: []
      }

      config.target_languages.each do |lang|
        translate_language(source_strings, lang, handler)
        results[:success_count] += 1
      rescue StandardError => e
        record_error(results, lang, e)
      end

      results
    end

    # Record translation error in results
    #
    # @param results [Hash] Results hash to update
    # @param lang [Hash] Language config
    # @param error [StandardError] The error that occurred
    # @return [void]
    # @api private
    #
    def record_error(results, lang, error)
      results[:failure_count] += 1
      # @type var error_context: Hash[Symbol, untyped]
      error_context = if error.is_a?(BetterTranslate::Error)
                        error.context
                      else
                        {}
                      end
      results[:errors] << {
        language: lang[:name],
        error: error.message,
        context: error_context
      }
      @progress_tracker.error(lang[:name], error)
    end

    # Translate to a single language
    #
    # @param source_strings [Hash] Source strings (flattened)
    # @param lang [Hash] Language config with :short_name and :name
    # @param handler [YAMLHandler, JsonHandler] File handler for this file
    # @return [void]
    # @api private
    #
    def translate_language(source_strings, lang, handler)
      target_lang_code = lang[:short_name]
      target_lang_name = lang[:name]

      # Filter exclusions
      strings_to_translate = handler.filter_exclusions(source_strings, target_lang_code)

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

      # Save - generate output path with proper filename
      current_input_file = config.input_file or raise "No input file set"
      output_path = build_output_path_for_file(current_input_file, target_lang_code)

      final_translations = if config.translation_mode == :incremental
                             handler.merge_translations(output_path, translated)
                           else
                             Utils::HashFlattener.unflatten(translated)
                           end

      # Wrap in language key (e.g., "it:")
      wrapped = { target_lang_code => final_translations }

      # Write using appropriate handler method (write_yaml or write_json)
      if handler.is_a?(JsonHandler)
        handler.write_json(output_path, wrapped)
      else
        handler.write_yaml(output_path, wrapped)
      end

      @progress_tracker.complete(target_lang_name, translated.size)
    end

    # Build output path for a specific file and language
    #
    # Replaces source language code with target language code in filename
    # and preserves directory structure
    #
    # @param input_file [String] Input file path
    # @param target_lang_code [String] Target language code
    # @return [String] Output file path
    # @api private
    #
    # @example
    #   build_output_path_for_file("config/locales/common.en.yml", "it")
    #   #=> "config/locales/common.it.yml"
    #
    def build_output_path_for_file(input_file, target_lang_code)
      # Get file basename and directory
      dir = File.dirname(input_file)
      basename = File.basename(input_file)
      ext = File.extname(basename)
      name_without_ext = File.basename(basename, ext)

      # Replace source language code with target language code
      # Handles patterns like: common.en.yml -> common.it.yml
      new_basename = name_without_ext.gsub(/\.#{config.source_language}$/, ".#{target_lang_code}") + ext

      # If no language code in filename, use simple pattern
      new_basename = "#{target_lang_code}#{ext}" if new_basename == basename

      # Build output path
      if config.output_folder
        # Use output_folder but preserve relative directory structure if input was nested
        File.join(config.output_folder, new_basename)
      else
        File.join(dir, new_basename)
      end
    end
  end
end
