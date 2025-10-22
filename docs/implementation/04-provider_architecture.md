# 04 - Provider Architecture

[← Previous: 03-Core Components](./03-core_components.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 05-Translation Logic →](./05-translation_logic.md)

---

## Provider Architecture

### 4.1 `lib/better_translate/providers/base_http_provider.rb`

```ruby
# frozen_string_literal: true

require "faraday"
require "json"

module BetterTranslate
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
      def translate_batch(texts, target_lang_code, target_lang_name)
        raise NotImplementedError, "#{self.class} must implement #translate_batch"
      end

      protected

      # Make an HTTP request with retry logic
      #
      # @param method [Symbol] HTTP method (:get, :post, etc.)
      # @param url [String] Request URL
      # @param body [Hash, nil] Request body
      # @param headers [Hash] Request headers
      # @return [Faraday::Response] HTTP response
      # @raise [ApiError] if request fails after retries
      def make_request(method, url, body: nil, headers: {})
        attempt = 0
        last_error = nil

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

          rescue RateLimitError => e
            last_error = e
            if attempt < config.max_retries
              delay = calculate_backoff(attempt)
              log_retry(attempt, delay, e)
              sleep(delay)
              next
            end
            raise

          rescue ApiError => e
            last_error = e
            if attempt < config.max_retries
              delay = calculate_backoff(attempt)
              log_retry(attempt, delay, e)
              sleep(delay)
              next
            end
            raise
          end
        end
      end

      # Handle HTTP response
      #
      # @param response [Faraday::Response] HTTP response
      # @raise [RateLimitError] if rate limited (429)
      # @raise [ApiError] if response indicates error
      # @return [void]
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
      def calculate_backoff(attempt)
        base_delay = config.retry_delay
        max_delay = 60.0
        jitter = rand * 0.3 # 0-30% jitter

        delay = base_delay * (2 ** (attempt - 1)) * (1 + jitter)
        [delay, max_delay].min
      end

      # Log retry attempt
      #
      # @param attempt [Integer] Current attempt number
      # @param delay [Float] Delay before retry
      # @param error [StandardError] The error that triggered retry
      # @return [void]
      def log_retry(attempt, delay, error)
        return unless config.verbose

        puts "[BetterTranslate] Retry #{attempt}/#{config.max_retries} after #{delay.round(2)}s (#{error.class}: #{error.message})"
      end

      # Get or create HTTP client
      #
      # @return [Faraday::Connection] HTTP client
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
      def build_cache_key(text, target_lang_code)
        "#{text}:#{target_lang_code}"
      end
    end
  end
end
```

### 4.2 `lib/better_translate/providers/chatgpt_provider.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  module Providers
    # OpenAI ChatGPT translation provider
    #
    # Uses GPT-5-nano model with temperature=1.0
    class ChatGPTProvider < BaseHttpProvider
      API_URL = "https://api.openai.com/v1/chat/completions"
      MODEL = "gpt-5-nano"
      TEMPERATURE = 1.0

      # Translate a single text
      #
      # @param text [String] Text to translate
      # @param target_lang_code [String] Target language code (e.g., "it")
      # @param target_lang_name [String] Target language name (e.g., "Italian")
      # @return [String] Translated text
      # @raise [ValidationError] if input is invalid
      # @raise [TranslationError] if translation fails
      def translate_text(text, target_lang_code, target_lang_name)
        Validator.validate_text!(text)
        Validator.validate_language_code!(target_lang_code)

        cache_key = build_cache_key(text, target_lang_code)

        with_cache(cache_key) do
          messages = build_messages(text, target_lang_name)
          response = make_chat_completion_request(messages)
          extract_translation(response)
        end
      rescue ApiError => e
        raise TranslationError.new(
          "Failed to translate text with ChatGPT: #{e.message}",
          context: { text: text, target_lang: target_lang_code, original_error: e }
        )
      end

      # Translate multiple texts in a batch
      #
      # @param texts [Array<String>] Texts to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Array<String>] Translated texts
      def translate_batch(texts, target_lang_code, target_lang_name)
        texts.map { |text| translate_text(text, target_lang_code, target_lang_name) }
      end

      private

      def build_messages(text, target_lang_name)
        system_message = build_system_message(target_lang_name)

        [
          { role: "system", content: system_message },
          { role: "user", content: text }
        ]
      end

      def build_system_message(target_lang_name)
        base_message = "You are a professional translator. Translate the following text to #{target_lang_name}. " \
                       "Return ONLY the translated text, without any explanations or additional text."

        if config.translation_context && !config.translation_context.empty?
          base_message += "\n\nContext: #{config.translation_context}"
        end

        base_message
      end

      def make_chat_completion_request(messages)
        body = {
          model: MODEL,
          messages: messages,
          temperature: TEMPERATURE
        }

        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{config.openai_key}"
        }

        make_request(:post, API_URL, body: body, headers: headers)
      end

      def extract_translation(response)
        parsed = JSON.parse(response.body)
        translation = parsed.dig("choices", 0, "message", "content")

        raise TranslationError, "No translation in response" if translation.nil? || translation.empty?

        translation.strip
      rescue JSON::ParserError => e
        raise TranslationError.new(
          "Failed to parse ChatGPT response",
          context: { error: e.message, body: response.body }
        )
      end
    end
  end
end
```

### 4.3 `lib/better_translate/providers/gemini_provider.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  module Providers
    # Google Gemini translation provider
    #
    # Uses gemini-2.5-flash-lite model
    class GeminiProvider < BaseHttpProvider
      API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"
      MODEL = "gemini-2.5-flash-lite"

      # Translate a single text
      #
      # @param text [String] Text to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [String] Translated text
      def translate_text(text, target_lang_code, target_lang_name)
        Validator.validate_text!(text)
        Validator.validate_language_code!(target_lang_code)

        cache_key = build_cache_key(text, target_lang_code)

        with_cache(cache_key) do
          prompt = build_prompt(text, target_lang_name)
          response = make_generation_request(prompt)
          extract_translation(response)
        end
      rescue ApiError => e
        raise TranslationError.new(
          "Failed to translate text with Gemini: #{e.message}",
          context: { text: text, target_lang: target_lang_code, original_error: e }
        )
      end

      # Translate multiple texts in a batch
      #
      # @param texts [Array<String>] Texts to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Array<String>] Translated texts
      def translate_batch(texts, target_lang_code, target_lang_name)
        texts.map { |text| translate_text(text, target_lang_code, target_lang_name) }
      end

      private

      def build_prompt(text, target_lang_name)
        base_prompt = "Translate the following text to #{target_lang_name}. " \
                      "Return ONLY the translated text, without any explanations.\n\n" \
                      "Text: #{text}"

        if config.translation_context && !config.translation_context.empty?
          base_prompt = "Context: #{config.translation_context}\n\n#{base_prompt}"
        end

        base_prompt
      end

      def make_generation_request(prompt)
        url = "#{API_URL}?key=#{config.google_gemini_key}"

        body = {
          contents: [
            {
              parts: [
                { text: prompt }
              ]
            }
          ]
        }

        headers = {
          "Content-Type" => "application/json"
        }

        make_request(:post, url, body: body, headers: headers)
      end

      def extract_translation(response)
        parsed = JSON.parse(response.body)
        translation = parsed.dig("candidates", 0, "content", "parts", 0, "text")

        raise TranslationError, "No translation in response" if translation.nil? || translation.empty?

        translation.strip
      rescue JSON::ParserError => e
        raise TranslationError.new(
          "Failed to parse Gemini response",
          context: { error: e.message, body: response.body }
        )
      end
    end
  end
end
```

### 4.4 `lib/better_translate/providers/anthropic_provider.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  module Providers
    # Anthropic Claude translation provider
    #
    # Uses claude-haiku-4-5 model
    class AnthropicProvider < BaseHttpProvider
      API_URL = "https://api.anthropic.com/v1/messages"
      MODEL = "claude-haiku-4-5"
      API_VERSION = "2023-06-01"

      # Translate a single text
      #
      # @param text [String] Text to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [String] Translated text
      def translate_text(text, target_lang_code, target_lang_name)
        Validator.validate_text!(text)
        Validator.validate_language_code!(target_lang_code)

        cache_key = build_cache_key(text, target_lang_code)

        with_cache(cache_key) do
          messages = build_messages(text, target_lang_name)
          response = make_messages_request(messages)
          extract_translation(response)
        end
      rescue ApiError => e
        raise TranslationError.new(
          "Failed to translate text with Anthropic: #{e.message}",
          context: { text: text, target_lang: target_lang_code, original_error: e }
        )
      end

      # Translate multiple texts in a batch
      #
      # @param texts [Array<String>] Texts to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Array<String>] Translated texts
      def translate_batch(texts, target_lang_code, target_lang_name)
        texts.map { |text| translate_text(text, target_lang_code, target_lang_name) }
      end

      private

      def build_messages(text, target_lang_name)
        system_message = build_system_message(target_lang_name)

        {
          system: system_message,
          messages: [
            { role: "user", content: text }
          ]
        }
      end

      def build_system_message(target_lang_name)
        base_message = "You are a professional translator. Translate the following text to #{target_lang_name}. " \
                       "Return ONLY the translated text, without any explanations or additional text."

        if config.translation_context && !config.translation_context.empty?
          base_message += "\n\nContext: #{config.translation_context}"
        end

        base_message
      end

      def make_messages_request(message_data)
        body = {
          model: MODEL,
          max_tokens: 1024,
          system: message_data[:system],
          messages: message_data[:messages]
        }

        headers = {
          "Content-Type" => "application/json",
          "x-api-key" => config.anthropic_key,
          "anthropic-version" => API_VERSION
        }

        make_request(:post, API_URL, body: body, headers: headers)
      end

      def extract_translation(response)
        parsed = JSON.parse(response.body)
        translation = parsed.dig("content", 0, "text")

        raise TranslationError, "No translation in response" if translation.nil? || translation.empty?

        translation.strip
      rescue JSON::ParserError => e
        raise TranslationError.new(
          "Failed to parse Anthropic response",
          context: { error: e.message, body: response.body }
        )
      end
    end
  end
end
```

### 4.5 `lib/better_translate/provider_factory.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  # Factory for creating translation providers
  #
  # @example
  #   provider = ProviderFactory.create(:chatgpt, config)
  #
  class ProviderFactory
    # Create a provider instance
    #
    # @param provider_name [Symbol] Provider name (:chatgpt, :gemini, :anthropic)
    # @param config [Configuration] Configuration object
    # @return [Providers::BaseHttpProvider] Provider instance
    # @raise [ProviderNotFoundError] if provider is unknown
    def self.create(provider_name, config)
      case provider_name
      when :chatgpt
        Providers::ChatGPTProvider.new(config)
      when :gemini
        Providers::GeminiProvider.new(config)
      when :anthropic
        Providers::AnthropicProvider.new(config)
      else
        raise ProviderNotFoundError, "Unknown provider: #{provider_name}. Supported: :chatgpt, :gemini, :anthropic"
      end
    end
  end
end
```

---

---

[← Previous: 03-Core Components](./03-core_components.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 05-Translation Logic →](./05-translation_logic.md)
