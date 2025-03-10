module BetterTranslate
  class Service
    def initialize
      @provider_name = BetterTranslate.configuration.provider
    end

    # Metodo per tradurre un testo utilizzando il provider selezionato.
    def translate(text, target_lang_code, target_lang_name)
      provider_instance.translate(text, target_lang_code, target_lang_name)
    end

    private

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
