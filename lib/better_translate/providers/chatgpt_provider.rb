module BetterTranslate
  module Providers
    class ChatgptProvider < BaseProvider
      # Utilizza l'API di OpenAI per tradurre il testo.
      def translate(text, target_lang_code, target_lang_name)
        uri = URI("https://api.openai.com/v1/chat/completions")
        headers = {
          "Content-Type"  => "application/json",
          "Authorization" => "Bearer #{@api_key}"
        }

        # Costruiamo il prompt per tradurre il testo.
        body = {
          model: "gpt-3.5-turbo",
          messages: [
            { role: "system", content: "Sei un traduttore professionale. Traduci esattamente il seguente testo da #{BetterTranslate.configuration.source_language} a #{target_lang_name} senza aggiungere commenti, spiegazioni o alternative. Fornisci solamente la traduzione diretta:" },
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
          raise "Errore durante la traduzione con ChatGPT: #{response.body}"
        end
      end
    end
  end
end
