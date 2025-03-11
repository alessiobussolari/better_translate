module BetterTranslate
  module Providers
    class ChatgptProvider < BaseProvider
      # Uses the OpenAI API to translate the text.
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
            { role: "system", content: "You are a professional translator. Translate the following text exactly from #{BetterTranslate.configuration.source_language} to #{target_lang_name} without adding comments, explanations, or alternatives. Provide only the direct translation:" },
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
          raise "Error during translation with ChatGPT: #{response.body}"
        end
      end
    end
  end
end
