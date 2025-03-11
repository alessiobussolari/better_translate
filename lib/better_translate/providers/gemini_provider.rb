# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module BetterTranslate
  module Providers
    class GeminiProvider < BaseProvider
      GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

      def translate_text(text, target_lang_code, target_lang_name)
        url = "#{GEMINI_API_URL}?key=#{@api_key}"
        uri = URI(url)

        headers = { "Content-Type" => "application/json" }
        body = {
          contents: [{
            parts: [{
              text: "Translate the following text to #{target_lang_name}. Provide ONLY the direct translation without any explanations, alternatives, or additional text. Do not include the original text. Do not use markdown formatting. Do not add any prefixes or notes. Just return the plain translated text:\n\n#{text}"
            }]
          }]
        }

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.path + "?" + uri.query, headers)
        request.body = body.to_json

        begin
          response = http.request(request)
          
          if response.is_a?(Net::HTTPSuccess)
            json = JSON.parse(response.body)
            
            if json["candidates"]&.any? && json["candidates"][0]["content"]["parts"]&.any?
              translated_text = json["candidates"][0]["content"]["parts"][0]["text"]
              
              # Pulizia minima del testo, dato che il prompt è già specifico
              cleaned_text = translated_text.strip
                .gsub(/[\*\`\n"]/, '') # Rimuovi markdown, newline e virgolette
                .gsub(/\s+/, ' ') # Riduci spazi multipli a uno singolo
              
              cleaned_text.empty? ? text : cleaned_text
            else
              raise "Risposta Gemini non valida: #{json}"
            end
          else
            raise "Errore HTTP #{response.code}: #{response.body}"
          end
        rescue => e
          raise "Errore durante la traduzione con Gemini: #{e.message}"
        end
      end
    end
  end
end
