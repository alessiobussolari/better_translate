# frozen_string_literal: true

require "rails/generators/base"

module BetterTranslate
  module Generators
    # Rails generator for running translations
    #
    # Executes translation based on existing configuration.
    #
    # @example Run generator
    #   rails generate better_translate:translate
    #
    # @example Run with dry-run
    #   rails generate better_translate:translate --dry-run
    #
    class TranslateGenerator < Rails::Generators::Base
      dir = __dir__
      source_root File.expand_path("templates", dir) if dir

      desc "Run BetterTranslate translation task"

      class_option :dry_run,
                   type: :boolean,
                   default: false,
                   desc: "Run in dry-run mode (no files written)"

      # Run translation
      #
      # @return [void]
      #
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def run_translation
        # Check if configuration is already loaded (from initializer)
        if BetterTranslate.configuration.provider.nil?
          # No initializer configuration found, try loading from YAML
          config_file = Rails.root.join("config", "better_translate.yml")

          unless File.exist?(config_file)
            say "No configuration found", :red
            say "Either:"
            say "  1. Create config/initializers/better_translate.rb (recommended)"
            say "  2. Run 'rails generate better_translate:install' to create YAML config"
            return
          end

          # Load configuration from YAML
          yaml_config = YAML.load_file(config_file)

          # Configure BetterTranslate
          BetterTranslate.configure do |config|
            config.provider = yaml_config["provider"]&.to_sym
            config.openai_key = yaml_config["openai_key"] || ENV["OPENAI_API_KEY"]
            config.gemini_key = yaml_config["gemini_key"] || ENV["GEMINI_API_KEY"]
            config.anthropic_key = yaml_config["anthropic_key"] || ENV["ANTHROPIC_API_KEY"]

            config.source_language = yaml_config["source_language"]
            config.target_languages = yaml_config["target_languages"]&.map do |lang|
              if lang.is_a?(Hash)
                { short_name: lang["short_name"], name: lang["name"] }
              else
                lang
              end
            end

            config.input_file = Rails.root.join(yaml_config["input_file"]).to_s
            config.output_folder = Rails.root.join(yaml_config["output_folder"]).to_s
            config.verbose = yaml_config.fetch("verbose", true)
            config.dry_run = options[:dry_run] || yaml_config.fetch("dry_run", false)

            # Map "full" to :override for backward compatibility
            translation_mode = yaml_config.fetch("translation_mode", "override")
            translation_mode = "override" if translation_mode == "full"
            config.translation_mode = translation_mode.to_sym

            config.preserve_variables = yaml_config.fetch("preserve_variables", true)

            # Exclusions
            config.global_exclusions = yaml_config["global_exclusions"] || []
            config.exclusions_per_language = yaml_config["exclusions_per_language"] || {}

            # Provider options
            config.model = yaml_config["model"] if yaml_config["model"]
            config.temperature = yaml_config["temperature"] if yaml_config["temperature"]
            config.max_tokens = yaml_config["max_tokens"] if yaml_config["max_tokens"]
            config.timeout = yaml_config["timeout"] if yaml_config["timeout"]
            config.max_retries = yaml_config["max_retries"] if yaml_config["max_retries"]
            config.rate_limit = yaml_config["rate_limit"] if yaml_config["rate_limit"]
          end
        elsif options[:dry_run]
          # Configuration from initializer exists, but apply dry_run option if provided
          BetterTranslate.configuration.dry_run = true
        end

        # Validate configuration (whether from initializer or YAML)
        begin
          BetterTranslate.configuration.validate!
        rescue BetterTranslate::ConfigurationError => e
          say "Invalid configuration: #{e.message}", :red
          return
        end

        # Perform translation
        say "Starting translation...", :green
        say "Provider: #{BetterTranslate.configuration.provider}"
        say "Source: #{BetterTranslate.configuration.source_language}"
        say "Targets: #{BetterTranslate.configuration.target_languages.map { |l| l[:name] }.join(", ")}"

        say "DRY RUN MODE - No files will be written", :yellow if options[:dry_run]

        say ""

        results = BetterTranslate.translate_files

        # Report results
        say ""
        say "=" * 60
        say "Translation Complete", :green
        say "=" * 60
        say "Success: #{results[:success_count]}", :green
        say "Failure: #{results[:failure_count]}", results[:failure_count].zero? ? :green : :red

        return unless results[:errors].any?

        say ""
        say "Errors:", :red
        results[:errors].each do |error|
          say "  - #{error[:language]}: #{error[:error]}", :red
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    end
  end
end
