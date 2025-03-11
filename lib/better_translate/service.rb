module BetterTranslate
  # Service class that handles translation requests using the configured provider.
  # Implements a Least Recently Used (LRU) cache to avoid redundant translation requests.
  #
  # @example
  #   service = BetterTranslate::Service.new
  #   translated_text = service.translate("Hello world", "fr", "French")
  class Service
    # Maximum number of translations to keep in the LRU cache
    MAX_CACHE_SIZE = 1000

    # Initializes a new Service instance.
    # Sets up the translation provider based on configuration and initializes the LRU cache.
    #
    # @return [BetterTranslate::Service] A new Service instance
    def initialize
      @provider_name = BetterTranslate.configuration.provider
      @translation_cache = {}
      @cache_order = []
    end

    # Translates text using the configured provider with caching support.
    # First checks if the translation is already in the cache. If not, it uses the
    # provider to translate the text and then caches the result for future use.
    # Also tracks metrics about the translation request duration.
    #
    # @param text [String] The text to translate
    # @param target_lang_code [String] The target language code (e.g., 'fr', 'es')
    # @param target_lang_name [String] The target language name (e.g., 'French', 'Spanish')
    # @return [String] The translated text
    def translate(text, target_lang_code, target_lang_name)
      cache_key = "#{text}:#{target_lang_code}"
      
      # Prova a recuperare dalla cache
      cached = cache_get(cache_key)
      return cached if cached
      
      # Traduci e salva in cache
      start_time = Time.now
      result = provider_instance.translate_text(text, target_lang_code, target_lang_name)
      duration = Time.now - start_time
      
      BetterTranslate::Utils.track_metric("translation_request_duration", {
        provider: @provider_name,
        text_length: text.length,
        duration: duration
      })
      
      cache_set(cache_key, result)
    end

    private

    # Retrieves a translation from the LRU cache if it exists.
    # Updates the cache order to mark this key as most recently used.
    #
    # @param key [String] The cache key in the format "text:target_lang_code"
    # @return [String, nil] The cached translation or nil if not found
    def cache_get(key)
      if @translation_cache.key?(key)
        # Aggiorna l'ordine LRU
        @cache_order.delete(key)
        @cache_order.push(key)
        @translation_cache[key]
      end
    end

    # Stores a translation in the LRU cache.
    # If the cache is full, removes the least recently used item before adding the new one.
    #
    # @param key [String] The cache key in the format "text:target_lang_code"
    # @param value [String] The translated text to cache
    # @return [String] The value that was cached
    def cache_set(key, value)
      if @translation_cache.size >= MAX_CACHE_SIZE
        # Rimuovi l'elemento meno recentemente usato
        oldest_key = @cache_order.shift
        @translation_cache.delete(oldest_key)
      end
      
      @translation_cache[key] = value
      @cache_order.push(key)
      value
    end



    # Creates or returns a cached instance of the translation provider.
    # The provider is determined by the configuration and instantiated with the appropriate API key.
    # Supports ChatGPT and Gemini providers.
    #
    # @return [BetterTranslate::Providers::BaseProvider] An instance of the configured translation provider
    # @raise [RuntimeError] If the configured provider is not supported
    def provider_instance
      @provider_instance ||= case @provider_name
                             when :chatgpt
                               Providers::ChatgptProvider.new(BetterTranslate.configuration.openai_key)
                             when :gemini
                               Providers::GeminiProvider.new(BetterTranslate.configuration.google_gemini_key)
                             else
                               raise "Provider non supportato: #{@provider_name}"
                             end
    end
  end
end
