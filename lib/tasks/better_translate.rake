# frozen_string_literal: true

require "yaml"

# Define :environment task as no-op if it doesn't exist (for non-Rails usage)
unless Rake::Task.task_defined?(:environment)
  task :environment do
    # No-op for standalone usage
  end
end

namespace :better_translate do
  desc "Translate YAML locale files using AI providers"
  task translate: :environment do
    config_file = Rails.root.join("config", "better_translate.yml")

    unless File.exist?(config_file)
      puts "Error: Configuration file not found at #{config_file}"
      puts "Run 'rake better_translate:config:generate' to create one."
      exit 1
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

      config.input_file = yaml_config["input_file"]
      config.output_folder = yaml_config["output_folder"]
      config.verbose = yaml_config.fetch("verbose", true)
      config.dry_run = yaml_config.fetch("dry_run", false)

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

    # Perform translation
    puts "Starting translation..."
    puts "Provider: #{BetterTranslate.configuration.provider}"
    puts "Source: #{BetterTranslate.configuration.source_language}"
    puts "Targets: #{BetterTranslate.configuration.target_languages.map { |l| l[:name] }.join(", ")}"
    puts

    results = BetterTranslate.translate_files

    # Report results
    puts
    puts "=" * 60
    puts "Translation Complete"
    puts "=" * 60
    puts "Success: #{results[:success_count]}"
    puts "Failure: #{results[:failure_count]}"

    if results[:errors].any?
      puts
      puts "Errors:"
      results[:errors].each do |error|
        puts "  - #{error[:language]}: #{error[:error]}"
      end
    end
  end

  namespace :config do
    desc "Generate sample configuration file"
    task generate: :environment do
      config_file = Rails.root.join("config", "better_translate.yml")

      if File.exist?(config_file)
        puts "Configuration file already exists at #{config_file}"
        puts "Delete it first if you want to regenerate."
        next
      end

      sample_config = {
        "provider" => "chatgpt",
        "openai_key" => "YOUR_OPENAI_API_KEY",
        "gemini_key" => "YOUR_GEMINI_API_KEY",
        "anthropic_key" => "YOUR_ANTHROPIC_API_KEY",
        "source_language" => "en",
        "target_languages" => [
          { "short_name" => "it", "name" => "Italian" },
          { "short_name" => "es", "name" => "Spanish" },
          { "short_name" => "fr", "name" => "French" }
        ],
        "input_file" => "config/locales/en.yml",
        "output_folder" => "config/locales",
        "verbose" => true,
        "dry_run" => false,
        "translation_mode" => "full",
        "preserve_variables" => true,
        "global_exclusions" => [],
        "exclusions_per_language" => {},
        "model" => nil,
        "temperature" => 0.3,
        "max_tokens" => 2000,
        "timeout" => 30,
        "max_retries" => 3,
        "rate_limit" => 10
      }

      File.write(config_file, sample_config.to_yaml)
      puts "Generated configuration file at #{config_file}"
      puts "Please edit it with your API keys and preferences."
    end
  end
end
