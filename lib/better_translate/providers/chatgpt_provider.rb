module BetterTranslate
  module Providers
    # Translation provider that uses OpenAI's ChatGPT API to perform translations.
    # Implements the BaseProvider interface with ChatGPT-specific translation logic.
    # Uses the gpt-3.5-turbo model with a specialized prompt for accurate translations.
    #
    # @example
    #   provider = BetterTranslate::Providers::ChatgptProvider.new(ENV['OPENAI_API_KEY'])
    #   translated_text = provider.translate("Hello world", "fr", "French")
    class ChatgptProvider < BaseProvider
      # Translates text using the OpenAI ChatGPT API.
      # Implements the provider-specific translation logic using OpenAI's ChatGPT API.
      # Sends a carefully crafted prompt to the API to ensure high-quality translations
      # without explanations or additional text.
      #
      # @param text [String] The text to translate
      # @param target_lang_code [String] The target language code (e.g., "fr")
      # @param target_lang_name [String] The target language name (e.g., "French")
      # @return [String] The translated text
      # @raise [StandardError] If the API request fails or returns an error
      def translate_text(text, target_lang_code, target_lang_name)
        uri = URI("https://api.openai.com/v1/chat/completions")
        headers = {
          "Content-Type"  => "application/json",
          "Authorization" => "Bearer #{@api_key}"
        }

        # Build the prompt to translate the text.
        body = {
          model: "gpt-3.5-turbo",
          messages: [
            { role: "system", content: "You are a professional translator. Translate the following text exactly from #{BetterTranslate.configuration.source_language} to #{target_lang_name}. Provide ONLY the direct translation without any explanations, alternatives, or additional text. Do not include the original text. Do not use markdown formatting. Do not add any prefixes or notes. Just return the plain translated text." },
            { role: "user", content: "#{text}" }
          ],
          temperature: 0.3
        }

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.path, headers)
        request.body = body.to_json

        response = http.request(request)
        if response.is_a?(Net::HTTPSuccess)
          json = JSON.parse(response.body)
          translated_text = json.dig("choices", 0, "message", "content")
          translated_text ? translated_text.strip : text
        else
          raise "Errore HTTP #{response.code}: #{response.body}"
        end
      rescue StandardError => e
        raise "Errore durante la traduzione con ChatGPT: #{e.message}"
      end
    end
  end
end
