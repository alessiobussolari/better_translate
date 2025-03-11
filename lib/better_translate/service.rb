module BetterTranslate
  class Service
    MAX_CACHE_SIZE = 1000

    def initialize
      @provider_name = BetterTranslate.configuration.provider
      @translation_cache = {}
      @cache_order = []
    end

    # Method to translate a text using the selected provider.
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

    def cache_get(key)
      if @translation_cache.key?(key)
        # Aggiorna l'ordine LRU
        @cache_order.delete(key)
        @cache_order.push(key)
        @translation_cache[key]
      end
    end

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



    def provider_instance
      @provider_instance ||= case @provider_name
                             when :chatgpt
                               Providers::ChatgptProvider.new(BetterTranslate.configuration.openai_key)
                             when :gemini
                               Providers::GeminiProvider.new(BetterTranslate.configuration.gemini_key)
                             else
                               raise "Provider non supportato: #{@provider_name}"
                             end
    end
  end
end
