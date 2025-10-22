# frozen_string_literal: true

module BetterTranslate
  # Configuration class for BetterTranslate
  #
  # Manages all configuration options with type safety and validation.
  #
  # @example Basic configuration
  #   config = Configuration.new
  #   config.provider = :chatgpt
  #   config.openai_key = ENV['OPENAI_API_KEY']
  #   config.source_language = "en"
  #   config.target_languages = [{ short_name: "it", name: "Italian" }]
  #   config.validate!
  #
  class Configuration
    # @return [Symbol] The translation provider (:chatgpt, :gemini, :anthropic)
    attr_accessor :provider

    # @return [String, nil] OpenAI API key
    attr_accessor :openai_key

    # @return [String, nil] Google Gemini API key
    attr_accessor :google_gemini_key

    # Alias for google_gemini_key (for convenience in configuration)
    alias gemini_key google_gemini_key
    alias gemini_key= google_gemini_key=

    # @return [String, nil] Anthropic API key (Claude)
    attr_accessor :claude_key

    # Alias for claude_key (for convenience in configuration)
    alias anthropic_key claude_key
    alias anthropic_key= claude_key=

    # @return [String] Source language code (e.g., "en")
    attr_accessor :source_language

    # @return [Array<Hash>] Target languages with :short_name and :name
    attr_accessor :target_languages

    # @return [String] Path to input YAML file
    attr_accessor :input_file

    # @return [String] Output folder for translated files
    attr_accessor :output_folder

    # @return [Symbol] Translation mode (:override or :incremental)
    attr_accessor :translation_mode

    # @return [String, nil] Translation context for domain-specific terminology
    attr_accessor :translation_context

    # @return [Integer] Maximum concurrent requests
    attr_accessor :max_concurrent_requests

    # @return [Integer] Request timeout in seconds
    attr_accessor :request_timeout

    # @return [Integer] Maximum number of retries
    attr_accessor :max_retries

    # @return [Float] Retry delay in seconds
    attr_accessor :retry_delay

    # @return [Boolean] Enable/disable caching
    attr_accessor :cache_enabled

    # @return [Integer] Cache size (LRU capacity)
    attr_accessor :cache_size

    # @return [Integer, nil] Cache TTL in seconds (nil = no expiration)
    attr_accessor :cache_ttl

    # @return [Boolean] Verbose logging
    attr_accessor :verbose

    # @return [Boolean] Dry run mode (no files written)
    attr_accessor :dry_run

    # @return [Array<String>] Global exclusions (apply to all languages)
    attr_accessor :global_exclusions

    # @return [Hash] Language-specific exclusions
    attr_accessor :exclusions_per_language

    # @return [Boolean] Preserve interpolation variables during translation (default: true)
    attr_accessor :preserve_variables

    # Initialize a new configuration with defaults
    def initialize
      @translation_mode = :override
      @max_concurrent_requests = 3
      @request_timeout = 30
      @max_retries = 3
      @retry_delay = 2.0
      @cache_enabled = true
      @cache_size = 1000
      @cache_ttl = nil
      @verbose = false
      @dry_run = false
      @global_exclusions = []
      @exclusions_per_language = {}
      @target_languages = []
      @preserve_variables = true
    end

    # Validate the configuration
    #
    # @raise [ConfigurationError] if configuration is invalid
    # @return [true] if configuration is valid
    def validate!
      validate_provider!
      validate_api_keys!
      validate_languages!
      validate_files!
      validate_optional_settings!
      true
    end

    private

    # Validate provider configuration
    #
    # @raise [ConfigurationError] if provider is not set or not a Symbol
    # @return [void]
    # @api private
    def validate_provider!
      raise ConfigurationError, "Provider must be set" if provider.nil?
      raise ConfigurationError, "Provider must be a Symbol" unless provider.is_a?(Symbol)
    end

    # Validate API keys based on selected provider
    #
    # @raise [ConfigurationError] if required API key is missing
    # @return [void]
    # @api private
    def validate_api_keys!
      case provider
      when :chatgpt
        if openai_key.nil? || openai_key.empty?
          raise ConfigurationError, "OpenAI API key is required for ChatGPT provider"
        end
      when :gemini
        if google_gemini_key.nil? || google_gemini_key.empty?
          raise ConfigurationError, "Google Gemini API key is required for Gemini provider"
        end
      when :anthropic
        if anthropic_key.nil? || anthropic_key.empty?
          raise ConfigurationError, "Anthropic API key is required for Anthropic provider"
        end
      end
    end

    # Validate language configuration
    #
    # @raise [ConfigurationError] if source or target languages are invalid
    # @return [void]
    # @api private
    def validate_languages!
      raise ConfigurationError, "Source language must be set" if source_language.nil? || source_language.empty?
      raise ConfigurationError, "Target languages must be an array" unless target_languages.is_a?(Array)
      raise ConfigurationError, "At least one target language is required" if target_languages.empty?

      target_languages.each do |lang|
        raise ConfigurationError, "Each target language must be a Hash" unless lang.is_a?(Hash)
        raise ConfigurationError, "Target language must have :short_name" unless lang.key?(:short_name)
        raise ConfigurationError, "Target language must have :name" unless lang.key?(:name)
      end
    end

    # Validate file paths
    #
    # @raise [ConfigurationError] if input file or output folder are invalid
    # @return [void]
    # @api private
    def validate_files!
      raise ConfigurationError, "Input file must be set" if input_file.nil? || input_file.empty?
      raise ConfigurationError, "Output folder must be set" if output_folder.nil? || output_folder.empty?
      raise ConfigurationError, "Input file does not exist: #{input_file}" unless File.exist?(input_file)
    end

    # Validate optional settings (timeouts, retries, cache, etc.)
    #
    # @raise [ConfigurationError] if optional settings have invalid values
    # @return [void]
    # @api private
    def validate_optional_settings!
      valid_modes = %i[override incremental]
      unless valid_modes.include?(translation_mode)
        raise ConfigurationError, "Translation mode must be :override or :incremental"
      end

      raise ConfigurationError, "Max concurrent requests must be positive" if max_concurrent_requests <= 0
      raise ConfigurationError, "Request timeout must be positive" if request_timeout <= 0
      raise ConfigurationError, "Max retries must be non-negative" if max_retries.negative?
      raise ConfigurationError, "Cache size must be positive" if cache_size <= 0
    end
  end
end
