# 03 - Core Components

[← Previous: 02-Error Handling](./02-error_handling.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 04-Provider Architecture →](./04-provider_architecture.md)

---

## Core Components

### 3.1 `lib/better_translate/configuration.rb`

```ruby
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
    # @return [Symbol] The translation provider (:chatgpt, :gemini, etc.)
    attr_accessor :provider

    # @return [String, nil] OpenAI API key
    attr_accessor :openai_key

    # @return [String, nil] Google Gemini API key
    attr_accessor :google_gemini_key

    # @return [String, nil] Anthropic API key
    attr_accessor :anthropic_key

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

    def validate_provider!
      raise ConfigurationError, "Provider must be set" if provider.nil?
      raise ConfigurationError, "Provider must be a Symbol" unless provider.is_a?(Symbol)
    end

    def validate_api_keys!
      case provider
      when :chatgpt
        raise ConfigurationError, "OpenAI API key is required for ChatGPT provider" if openai_key.nil? || openai_key.empty?
      when :gemini
        raise ConfigurationError, "Google Gemini API key is required for Gemini provider" if google_gemini_key.nil? || google_gemini_key.empty?
      when :anthropic
        raise ConfigurationError, "Anthropic API key is required for Anthropic provider" if anthropic_key.nil? || anthropic_key.empty?
      end
    end

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

    def validate_files!
      raise ConfigurationError, "Input file must be set" if input_file.nil? || input_file.empty?
      raise ConfigurationError, "Output folder must be set" if output_folder.nil? || output_folder.empty?
      raise ConfigurationError, "Input file does not exist: #{input_file}" unless File.exist?(input_file)
    end

    def validate_optional_settings!
      valid_modes = [:override, :incremental]
      raise ConfigurationError, "Translation mode must be :override or :incremental" unless valid_modes.include?(translation_mode)

      raise ConfigurationError, "Max concurrent requests must be positive" if max_concurrent_requests <= 0
      raise ConfigurationError, "Request timeout must be positive" if request_timeout <= 0
      raise ConfigurationError, "Max retries must be non-negative" if max_retries < 0
      raise ConfigurationError, "Cache size must be positive" if cache_size <= 0
    end
  end
end
```

### 3.2 `lib/better_translate/cache.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  # LRU (Least Recently Used) Cache implementation
  #
  # Thread-safe cache with configurable capacity and optional TTL.
  #
  # @example Basic usage
  #   cache = Cache.new(capacity: 100)
  #   cache.set("hello:it", "ciao")
  #   cache.get("hello:it") #=> "ciao"
  #
  class Cache
    # @return [Integer] Maximum number of items in cache
    attr_reader :capacity

    # @return [Integer, nil] Time to live in seconds
    attr_reader :ttl

    # Initialize a new cache
    #
    # @param capacity [Integer] Maximum cache size
    # @param ttl [Integer, nil] Time to live in seconds
    def initialize(capacity: 1000, ttl: nil)
      @capacity = capacity
      @ttl = ttl
      @cache = {}
      @mutex = Mutex.new
    end

    # Get a value from the cache
    #
    # @param key [String] Cache key
    # @return [String, nil] Cached value or nil if not found/expired
    def get(key)
      @mutex.synchronize do
        return nil unless @cache.key?(key)

        entry = @cache[key]

        # Check TTL
        if @ttl && Time.now - entry[:timestamp] > @ttl
          @cache.delete(key)
          return nil
        end

        # Move to end (most recently used)
        @cache.delete(key)
        @cache[key] = entry
        entry[:value]
      end
    end

    # Set a value in the cache
    #
    # @param key [String] Cache key
    # @param value [String] Value to cache
    # @return [String] The cached value
    def set(key, value)
      @mutex.synchronize do
        # Remove oldest entry if at capacity
        @cache.shift if @cache.size >= @capacity && !@cache.key?(key)

        @cache[key] = {
          value: value,
          timestamp: Time.now
        }
        value
      end
    end

    # Clear the cache
    #
    # @return [void]
    def clear
      @mutex.synchronize { @cache.clear }
    end

    # Get cache size
    #
    # @return [Integer] Number of items in cache
    def size
      @mutex.synchronize { @cache.size }
    end

    # Check if key exists in cache
    #
    # @param key [String] Cache key
    # @return [Boolean] true if key exists and not expired
    def key?(key)
      !get(key).nil?
    end
  end
end
```

### 3.3 `lib/better_translate/rate_limiter.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  # Thread-safe rate limiter
  #
  # Ensures requests are spaced out by a minimum delay.
  #
  # @example
  #   limiter = RateLimiter.new(delay: 0.5)
  #   limiter.wait  # Waits if needed
  #
  class RateLimiter
    # @return [Float] Delay between requests in seconds
    attr_reader :delay

    # Initialize a new rate limiter
    #
    # @param delay [Float] Delay in seconds between requests
    def initialize(delay: 0.5)
      @delay = delay
      @last_request_time = nil
      @mutex = Mutex.new
    end

    # Wait if necessary to respect rate limit
    #
    # @return [void]
    def wait
      @mutex.synchronize do
        return if @last_request_time.nil?

        elapsed = Time.now - @last_request_time
        sleep_time = @delay - elapsed

        sleep(sleep_time) if sleep_time > 0
      end
    end

    # Record that a request was made
    #
    # @return [void]
    def record_request
      @mutex.synchronize { @last_request_time = Time.now }
    end

    # Reset the rate limiter
    #
    # @return [void]
    def reset
      @mutex.synchronize { @last_request_time = nil }
    end
  end
end
```

### 3.4 `lib/better_translate/validator.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  # Input validation utilities
  #
  # Validates language codes, text, paths, and other inputs.
  class Validator
    # Validate a language code
    #
    # @param code [String] Language code to validate
    # @raise [ValidationError] if code is invalid
    # @return [true] if valid
    def self.validate_language_code!(code)
      raise ValidationError, "Language code cannot be nil" if code.nil?
      raise ValidationError, "Language code must be a String" unless code.is_a?(String)
      raise ValidationError, "Language code cannot be empty" if code.empty?
      raise ValidationError, "Language code must be 2 letters" unless code.match?(/^[a-z]{2}$/i)
      true
    end

    # Validate text for translation
    #
    # @param text [String] Text to validate
    # @raise [ValidationError] if text is invalid
    # @return [true] if valid
    def self.validate_text!(text)
      raise ValidationError, "Text cannot be nil" if text.nil?
      raise ValidationError, "Text must be a String" unless text.is_a?(String)
      raise ValidationError, "Text cannot be empty" if text.strip.empty?
      true
    end

    # Validate a file path exists
    #
    # @param path [String] File path to validate
    # @raise [FileError] if path is invalid
    # @return [true] if valid
    def self.validate_file_exists!(path)
      raise FileError, "File path cannot be nil" if path.nil?
      raise FileError, "File path must be a String" unless path.is_a?(String)
      raise FileError, "File does not exist: #{path}" unless File.exist?(path)
      true
    end

    # Validate an API key
    #
    # @param key [String] API key to validate
    # @param provider [Symbol] Provider name for error message
    # @raise [ConfigurationError] if key is invalid
    # @return [true] if valid
    def self.validate_api_key!(key, provider:)
      raise ConfigurationError, "API key for #{provider} cannot be nil" if key.nil?
      raise ConfigurationError, "API key for #{provider} must be a String" unless key.is_a?(String)
      raise ConfigurationError, "API key for #{provider} cannot be empty" if key.strip.empty?
      true
    end
  end
end
```

### 3.5 `lib/better_translate/utils/hash_flattener.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  module Utils
    # Utilities for flattening and unflattening nested hashes
    #
    # Used to convert nested YAML structures to flat key-value pairs
    # and back again.
    #
    # @example
    #   nested = { "user" => { "name" => "John", "age" => 30 } }
    #   flat = HashFlattener.flatten(nested)
    #   #=> { "user.name" => "John", "user.age" => 30 }
    #
    #   HashFlattener.unflatten(flat)
    #   #=> { "user" => { "name" => "John", "age" => 30 } }
    #
    class HashFlattener
      # Flatten a nested hash to dot-notation keys
      #
      # @param hash [Hash] Nested hash to flatten
      # @param parent_key [String] Parent key prefix
      # @param separator [String] Key separator
      # @return [Hash] Flattened hash
      def self.flatten(hash, parent_key = "", separator = ".")
        hash.each_with_object({}) do |(key, value), result|
          new_key = parent_key.empty? ? key.to_s : "#{parent_key}#{separator}#{key}"

          if value.is_a?(Hash)
            result.merge!(flatten(value, new_key, separator))
          else
            result[new_key] = value
          end
        end
      end

      # Unflatten a hash with dot-notation keys to nested structure
      #
      # @param hash [Hash] Flattened hash
      # @param separator [String] Key separator
      # @return [Hash] Nested hash
      def self.unflatten(hash, separator = ".")
        hash.each_with_object({}) do |(key, value), result|
          keys = key.split(separator)
          last_key = keys.pop

          # Build nested structure
          nested = keys.reduce(result) do |memo, k|
            memo[k] ||= {}
            memo[k]
          end

          nested[last_key] = value
        end
      end
    end
  end
end
```

---

---

[← Previous: 02-Error Handling](./02-error_handling.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 04-Provider Architecture →](./04-provider_architecture.md)
