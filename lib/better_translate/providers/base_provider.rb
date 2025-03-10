module BetterTranslate
  module Providers
    class BaseProvider
      def initialize(api_key)
        @api_key = api_key
      end

      # Metodo da implementare nelle classi derivate.
      # @param text [String] testo da tradurre.
      # @param target_lang_code [String] codice della lingua di destinazione (es. "en").
      # @param target_lang_name [String] nome della lingua di destinazione (es. "English").
      # @return [String] testo tradotto.
      def translate(text, target_lang_code, target_lang_name)
        raise NotImplementedError, "Il provider #{self.class} deve implementare il metodo translate"
      end
    end
  end
end
