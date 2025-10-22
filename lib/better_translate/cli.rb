# frozen_string_literal: true

require "optparse"
require "yaml"

module BetterTranslate
  # Command-line interface for BetterTranslate
  #
  # Provides standalone CLI commands for translation without Rails.
  #
  # @example Run translation from config file
  #   cli = CLI.new(["translate", "--config", "config.yml"])
  #   cli.run
  #
  # @example Generate config file
  #   cli = CLI.new(["generate", "config.yml"])
  #   cli.run
  #
  # @example Direct translation
  #   cli = CLI.new(["direct", "Hello", "--to", "it", "--provider", "chatgpt"])
  #   cli.run
  #
  class CLI
    # @return [Array<String>] Command-line arguments
    attr_reader :args

    # Initialize CLI
    #
    # @param args [Array<String>] Command-line arguments
    #
    # @example
    #   cli = CLI.new(ARGV)
    #
    def initialize(args)
      @args = args
    end

    # Run CLI command
    #
    # @return [void]
    #
    # @example
    #   cli = CLI.new(ARGV)
    #   cli.run
    #
    def run
      command = args.first

      case command
      when "translate"
        run_translate
      when "generate"
        run_generate
      when "direct"
        run_direct
      when "--version", "-v"
        puts "BetterTranslate version #{VERSION}"
      when "--help", "-h", nil
        show_help
      else
        puts "Unknown command: #{command}"
        puts
        show_help
      end
    end

    private

    # Show help message
    #
    # @return [void]
    # @api private
    #
    def show_help
      puts <<~HELP
        Usage: better_translate COMMAND [OPTIONS]

        Commands:
          translate              Translate YAML files using config file
          generate OUTPUT_FILE   Generate sample config file
          direct TEXT            Translate text directly

        Options:
          --help, -h             Show this help message
          --version, -v          Show version

        Examples:
          better_translate translate --config config.yml
          better_translate generate config.yml
          better_translate direct "Hello" --to it --provider chatgpt --api-key KEY
      HELP
    end

    # Run translate command
    #
    # @return [void]
    # @api private
    #
    def run_translate
      # @type var options: Hash[Symbol, String]
      options = {}
      OptionParser.new do |opts|
        opts.on("--config FILE", "Config file path") { |v| options[:config] = v }
      end.parse!(args[1..])

      unless options[:config]
        puts "Error: --config is required"
        return
      end

      unless File.exist?(options[:config])
        puts "Error: Config file not found: #{options[:config]}"
        return
      end

      # Load configuration from YAML
      yaml_config = YAML.load_file(options[:config])

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

      return unless results[:errors].any?

      puts
      puts "Errors:"
      results[:errors].each do |error|
        puts "  - #{error[:language]}: #{error[:error]}"
      end
    end

    # Run generate command
    #
    # @return [void]
    # @api private
    #
    def run_generate
      output_file = args[1]
      force = args.include?("--force")

      unless output_file
        puts "Error: Output file path is required"
        puts "Usage: better_translate generate OUTPUT_FILE [--force]"
        return
      end

      if File.exist?(output_file) && !force
        puts "Config file already exists at #{output_file}"
        puts "Use --force to overwrite"
        return
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
        "input_file" => "locales/en.yml",
        "output_folder" => "locales",
        "verbose" => true,
        "dry_run" => false,
        "translation_mode" => "override",
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

      File.write(output_file, sample_config.to_yaml)
      puts "Generated configuration file at #{output_file}"
      puts "Please edit it with your API keys and preferences."
    end

    # Run direct translation command
    #
    # @return [void]
    # @api private
    #
    def run_direct
      text = args[1]
      # @type var options: Hash[Symbol, String]
      options = {}

      remaining_args = args[2..] || []
      OptionParser.new do |opts|
        opts.on("--to LANG", "Target language code") { |v| options[:to] = v }
        opts.on("--language-name NAME", "Target language name") { |v| options[:language_name] = v }
        opts.on("--provider PROVIDER", "Provider (chatgpt, gemini, anthropic)") { |v| options[:provider] = v }
        opts.on("--api-key KEY", "API key") { |v| options[:api_key] = v }
      end.parse!(remaining_args)

      unless text
        puts "Error: Text is required"
        puts "Usage: better_translate direct TEXT --to LANG --provider PROVIDER --api-key KEY"
        return
      end

      unless options[:to]
        puts "Error: --to is required"
        return
      end

      unless options[:provider]
        puts "Error: --provider is required"
        return
      end

      # Default language name
      options[:language_name] ||= options[:to].upcase

      # Configure
      BetterTranslate.configure do |config|
        config.provider = options[:provider].to_sym
        config.source_language = "en"

        case options[:provider].to_sym
        when :chatgpt
          config.openai_key = options[:api_key] || ENV["OPENAI_API_KEY"]
        when :gemini
          config.gemini_key = options[:api_key] || ENV["GEMINI_API_KEY"]
        when :anthropic
          config.anthropic_key = options[:api_key] || ENV["ANTHROPIC_API_KEY"]
        end
      end

      # Translate
      translator = DirectTranslator.new(BetterTranslate.configuration)
      result = translator.translate(
        text,
        to: options[:to],
        language_name: options[:language_name]
      )

      puts result
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end
end
