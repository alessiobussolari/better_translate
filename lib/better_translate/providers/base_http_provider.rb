# frozen_string_literal: true

require "faraday"
require "json"

module BetterTranslate
  # Translation provider implementations
  #
  # Contains all AI provider integrations (ChatGPT, Gemini, Anthropic)
  # and the base HTTP provider class.
  module Providers
    # Base class for HTTP-based translation providers
    #
    # Implements common functionality:
    # - Faraday HTTP client with retry logic
    # - Exponential backoff with jitter
    # - Rate limiting
    # - Caching
    # - Error handling
    #
    # @abstract Subclasses must implement {#translate_text} and {#translate_batch}
    #
    # @example Creating a custom provider
    #   class MyProvider < BaseHttpProvider
    #     def translate_text(text, target_lang_code, target_lang_name)
    #       # Implementation
    #     end
    #
    #     def translate_batch(texts, target_lang_code, target_lang_name)
    #       # Implementation
    #     end
    #   end
    #
    class BaseHttpProvider
      # @return [Configuration] The configuration object
      attr_reader :config

      # @return [Cache] The cache instance
      attr_reader :cache

      # @return [RateLimiter] The rate limiter instance
      attr_reader :rate_limiter

      # Initialize the provider
      #
      # @param config [Configuration] Configuration object
      #
      # @example
      #   config = Configuration.new
      #   provider = BaseHttpProvider.new(config)
      #
      def initialize(config)
        @config = config
        @cache = Cache.new(capacity: config.cache_size, ttl: config.cache_ttl)
        @rate_limiter = RateLimiter.new(delay: 0.5)
      end

      # Translate a single text string
      #
      # @param text [String] Text to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [String] Translated text
      # @raise [NotImplementedError] Must be implemented by subclasses
      #
      # @example
      #   provider.translate_text("Hello", "it", "Italian")
      #   #=> "Ciao"
      #
      def translate_text(text, target_lang_code, target_lang_name)
        raise NotImplementedError, "#{self.class} must implement #translate_text"
      end

      # Translate multiple texts in a batch
      #
      # @param texts [Array<String>] Texts to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Array<String>] Translated texts
      # @raise [NotImplementedError] Must be implemented by subclasses
      #
      # @example
      #   provider.translate_batch(["Hello", "World"], "it", "Italian")
      #   #=> ["Ciao", "Mondo"]
      #
      def translate_batch(texts, target_lang_code, target_lang_name)
        raise NotImplementedError, "#{self.class} must implement #translate_batch"
      end

      protected

      # Make an HTTP request with retry logic
      #
      # Implements exponential backoff with jitter and rate limiting.
      # Automatically retries on rate limit and API errors.
      #
      # @param method [Symbol] HTTP method (:get, :post, etc.)
      # @param url [String] Request URL
      # @param body [Hash, nil] Request body
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] HTTP response
      # @raise [ApiError] if request fails after retries
      # @api private
      #
      def make_request(method, url, body: nil, headers: {})
        attempt = 0

        loop do
          attempt += 1

          begin
            rate_limiter.wait
            response = http_client.send(method, url) do |req|
              req.headers.merge!(headers)
              req.body = body.to_json if body
            end
            rate_limiter.record_request

            handle_response(response)
            return response
          rescue RateLimitError, ApiError => e
            raise if attempt >= config.max_retries

            delay = calculate_backoff(attempt)
            log_retry(attempt, delay, e)
            sleep(delay)
          end
        end
      end

      # Handle HTTP response
      #
      # @param response [Faraday::Response] HTTP response
      # @raise [RateLimitError] if rate limited (429)
      # @raise [ApiError] if response indicates error
      # @return [void]
      # @api private
      #
      def handle_response(response)
        case response.status
        when 200..299
          # Success
        when 429
          raise RateLimitError.new(
            "Rate limit exceeded",
            context: { status: response.status, body: response.body }
          )
        when 400..499
          raise ApiError.new(
            "Client error: #{response.status}",
            context: { status: response.status, body: response.body }
          )
        when 500..599
          raise ApiError.new(
            "Server error: #{response.status}",
            context: { status: response.status, body: response.body }
          )
        else
          raise ApiError.new(
            "Unexpected status: #{response.status}",
            context: { status: response.status, body: response.body }
          )
        end
      end

      # Calculate exponential backoff with jitter
      #
      # @param attempt [Integer] Current attempt number
      # @return [Float] Delay in seconds
      # @api private
      #
      def calculate_backoff(attempt)
        base_delay = config.retry_delay
        max_delay = 60.0
        jitter = rand * 0.3 # 0-30% jitter

        delay = base_delay * (2**(attempt - 1)) * (1 + jitter)
        [delay, max_delay].min
      end

      # Log retry attempt
      #
      # @param attempt [Integer] Current attempt number
      # @param delay [Float] Delay before retry
      # @param error [StandardError] The error that triggered retry
      # @return [void]
      # @api private
      #
      def log_retry(attempt, delay, error)
        return unless config.verbose

        puts "[BetterTranslate] Retry #{attempt}/#{config.max_retries} " \
             "after #{delay.round(2)}s (#{error.class}: #{error.message})"
      end

      # Get or create HTTP client
      #
      # @return [Faraday::Connection] HTTP client
      # @api private
      #
      def http_client
        @http_client ||= Faraday.new do |f|
          f.options.timeout = config.request_timeout
          f.options.open_timeout = 10
          f.adapter Faraday.default_adapter
        end
      end

      # Get from cache or execute block
      #
      # @param cache_key [String] Cache key
      # @yieldreturn [String] Value to cache if not found
      # @return [String] Cached or newly computed value
      # @api private
      #
      def with_cache(cache_key)
        return yield unless config.cache_enabled

        cached = cache.get(cache_key)
        return cached if cached

        result = yield
        cache.set(cache_key, result)
        result
      end

      # Build cache key
      #
      # @param text [String] Text being translated
      # @param target_lang_code [String] Target language code
      # @return [String] Cache key
      # @api private
      #
      def build_cache_key(text, target_lang_code)
        "#{text}:#{target_lang_code}"
      end
    end
  end
end
