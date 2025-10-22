# frozen_string_literal: true

module BetterTranslate
  # Factory for creating translation providers
  #
  # Creates the appropriate provider instance based on configuration.
  #
  # @example Creating a ChatGPT provider
  #   config = Configuration.new
  #   config.provider = :chatgpt
  #   config.openai_key = ENV['OPENAI_API_KEY']
  #   provider = ProviderFactory.create(:chatgpt, config)
  #   #=> #<BetterTranslate::Providers::ChatGPTProvider>
  #
  # @example Creating a Gemini provider
  #   config.provider = :gemini
  #   config.google_gemini_key = ENV['GOOGLE_GEMINI_KEY']
  #   provider = ProviderFactory.create(:gemini, config)
  #   #=> #<BetterTranslate::Providers::GeminiProvider>
  #
  class ProviderFactory
    # Create a provider instance
    #
    # @param provider_name [Symbol] Provider name (:chatgpt, :gemini, :anthropic)
    # @param config [Configuration] Configuration object
    # @return [Providers::BaseHttpProvider] Provider instance
    # @raise [ProviderNotFoundError] if provider is unknown
    #
    # @example
    #   provider = ProviderFactory.create(:chatgpt, config)
    #
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
